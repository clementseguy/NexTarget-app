import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Service d'authentification OAuth2 avec Google via le backend NexTarget.
class AuthService {
  final String _authBaseUrl;
  final String _callbackScheme;
  final FlutterSecureStorage _storage;
  
  static const String _tokenKey = 'jwt_token';
  static const String _emailKey = 'user_email';

  AuthService({
    required String authBaseUrl,
    required String callbackScheme,
    FlutterSecureStorage? storage,
  })  : _authBaseUrl = authBaseUrl,
        _callbackScheme = callbackScheme,
        _storage = storage ?? const FlutterSecureStorage();

  /// Lance le flow d'authentification Google OAuth2
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('[AUTH] Demande de l URL OAuth au serveur...');
      final startResponse = await http.get(
        Uri.parse('$_authBaseUrl/auth/google/start'),
      );

      if (startResponse.statusCode != 200) {
        throw Exception('Erreur serveur: ${startResponse.statusCode}');
      }

      final startData = jsonDecode(startResponse.body);
      final authUrl = startData['auth_url'] as String;

      print('[AUTH] Ouverture du navigateur in-app...');

      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: _callbackScheme,
      );

      print('[AUTH] Callback intercepte');

      final uri = Uri.parse(resultUrl);

      if (uri.fragment.isEmpty) {
        throw Exception('Pas de donnees dans le callback');
      }

      final params = Uri.splitQueryString(uri.fragment);
      
      final accessToken = params['access_token'];
      final email = params['email'];
      final provider = params['provider'] ?? 'google';

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token manquant dans le callback');
      }

      if (email == null || email.isEmpty) {
        throw Exception('Email manquant dans le callback');
      }

      await _storage.write(key: _tokenKey, value: accessToken);
      await _storage.write(key: _emailKey, value: email);

      print('[AUTH] Authentification reussie et token stocke');

      return {
        'access_token': accessToken,
        'email': email,
        'provider': provider,
      };
    } catch (e) {
      print('[AUTH] Erreur lors de l authentification: $e');
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
    print('[AUTH_SERVICE] isAuthenticated() - token présent: ${token != null}');
    if (token == null) {
      return false;
    }

    try {
      print('[AUTH_SERVICE] Vérification du token auprès de $_authBaseUrl/users/me');
      final response = await http.get(
        Uri.parse('$_authBaseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('[AUTH_SERVICE] Réponse /users/me: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('[AUTH_SERVICE] Token valide, utilisateur authentifié');
        return true;
      } else {
        print('[AUTH_SERVICE] Token invalide (${response.statusCode}), déconnexion');
        await logout();
        return false;
      }
    } catch (e) {
      print('[AUTH_SERVICE] Erreur lors de la vérification: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifie');
    }

    try {
      final response = await http.get(
        Uri.parse('$_authBaseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expiree');
      } else {
        throw Exception('Erreur lors de la recuperation du profil');
      }
    } catch (e) {
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
