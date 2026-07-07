import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service d'authentification OAuth2 avec Google via le backend NexTarget.
class AuthService {
  final String _authBaseUrl;
  final FlutterSecureStorage _storage;
  
  static const String _tokenKey = 'jwt_token';
  static const String _emailKey = 'user_email';

  AuthService({
    required String authBaseUrl,
    String? callbackScheme,
    FlutterSecureStorage? storage,
  })  : _authBaseUrl = authBaseUrl,
        _storage = storage ?? const FlutterSecureStorage();

  /// Lance le flow d'authentification Google OAuth2
  /// 
  /// Flow (selon décision architecte):
  /// 1. Appel HTTP GET /auth/google/login
  /// 2. Récupération de auth_url du JSON
  /// 3. Ouverture de auth_url dans le navigateur externe
  /// 4. Backend gère OAuth2 et redirige vers nextarget://callback?token=XYZ
  /// 5. App intercepte le deep link via uni_links (géré dans main.dart)
  Future<void> signInWithGoogle() async {
    try {
      final loginUrl = '$_authBaseUrl/auth/google/login';
      print('[AUTH] Appel GET $loginUrl ...');

      // Étape 1 : Récupérer auth_url depuis le backend (timeout 15 s)
      final response = await http.get(Uri.parse(loginUrl)).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception(
          'Le serveur ne répond pas (timeout 15 s). Vérifiez votre connexion.',
        ),
      );
      print('[AUTH] Réponse ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Échec de récupération de l\'URL OAuth (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final authUrl = data['auth_url'] as String?;

      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('URL d\'authentification manquante');
      }

      // Étape 2 : Ouvrir auth_url dans le navigateur externe
      print('[AUTH] Ouverture du navigateur pour OAuth...');
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir le navigateur');
      }

      // Note : Le token sera récupéré via le deep link handler dans main.dart
    } catch (e) {
      print('[AUTH] Erreur lors de l\'authentification Google: $e');
      rethrow;
    }
  }

  /// Traite le callback deep link et stocke le token
  /// À appeler depuis le deep link handler
  Future<Map<String, dynamic>> handleCallback(Uri callbackUri) async {
    try {
      final token = callbackUri.queryParameters['token'];
      final error = callbackUri.queryParameters['error'];

      // Gérer les erreurs
      if (error != null && error.isNotEmpty) {
        throw Exception('Erreur d\'authentification: $error');
      }

      if (token == null || token.isEmpty) {
        throw Exception('Token manquant dans le callback OAuth');
      }
      
      // Échanger le token callback contre un token d'accès valide
      final exchangeResponse = await http.post(
        Uri.parse('$_authBaseUrl/auth/token/exchange'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'callback_token': token}),
      ).timeout(const Duration(seconds: 15));

      if (exchangeResponse.statusCode != 200) {
        throw Exception('Échec de l\'échange du token (${exchangeResponse.statusCode})');
      }

      final exchangeData = jsonDecode(exchangeResponse.body) as Map<String, dynamic>;
      final accessToken = exchangeData['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token d\'accès manquant dans la réponse');
      }

      // Stocker le token d'accès
      await _storage.write(key: _tokenKey, value: accessToken);

      // Récupérer les infos utilisateur complètes avec le token d'accès
      final userInfo = await getUserInfo();
      await _storage.write(key: _emailKey, value: userInfo['email'] ?? '');

      return userInfo;
    } catch (e) {
      print('[AUTH] Erreur lors du traitement du callback OAuth: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$_authBaseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      print('[AUTH] Erreur lors de la vérification du token: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    try {
      final response = await http.get(
        Uri.parse('$_authBaseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body) as Map<String, dynamic>;
        print('[AUTH] getUserInfo response keys: ${userInfo.keys.toList()}');
        print('[AUTH] created_at value: ${userInfo['created_at']}');
        return userInfo;
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur lors de la récupération du profil (${response.statusCode})');
      }
    } catch (e) {
      print('[AUTH] Erreur lors de la récupération des infos utilisateur: $e');
      rethrow;
    }
  }

  /// Met à jour le profil utilisateur (experience_level)
  /// Retourne le profil mis à jour (UserPublic)
  Future<Map<String, dynamic>> updateProfile({String? experienceLevel}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    try {
      final body = <String, dynamic>{};
      if (experienceLevel != null) {
        body['experience_level'] = experienceLevel;
      }

      final response = await http.patch(
        Uri.parse('$_authBaseUrl/users/me/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expirée');
      } else if (response.statusCode == 422) {
        throw Exception('Valeur invalide');
      } else {
        throw Exception('Erreur lors de la mise à jour du profil (${response.statusCode})');
      }
    } catch (e) {
      print('[AUTH] Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
