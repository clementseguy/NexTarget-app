import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'auth_session_exceptions.dart';
import 'authenticated_http_client.dart';
import 'logger.dart';

/// Paire de tokens persistée (NT-048).
///
/// Toujours lue/écrite comme un seul bloc JSON sous une unique clé de
/// stockage sécurisé : une interruption ne peut donc jamais laisser un
/// access token et un refresh token de générations différentes (l'écriture
/// remplace la paire en un seul appel, jamais deux écritures séparées).
class _StoredTokenSet {
  final String accessToken;
  final String? refreshToken;
  final DateTime accessExpiresAt;
  final DateTime? refreshExpiresAt;
  final String? email;

  const _StoredTokenSet({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'access_expires_at': accessExpiresAt.toIso8601String(),
        'refresh_expires_at': refreshExpiresAt?.toIso8601String(),
        'email': email,
      };

  factory _StoredTokenSet.fromJson(Map<String, dynamic> json) =>
      _StoredTokenSet(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        accessExpiresAt:
            DateTime.parse(json['access_expires_at'] as String).toUtc(),
        refreshExpiresAt: json['refresh_expires_at'] != null
            ? DateTime.parse(json['refresh_expires_at'] as String).toUtc()
            : null,
        email: json['email'] as String?,
      );
}

/// Service d'authentification OAuth2 avec Google via le backend NexTarget.
///
/// NT-048 : gère aussi le refresh token (stockage atomique, rotation,
/// renouvellement proactif, single-flight). Les appels authentifiés
/// (profil ici, Coach dans `ServerCoachAnalysisService`) passent tous par
/// [AuthenticatedHttpClient], qui délègue le renouvellement à ce service.
class AuthService {
  final String _authBaseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _httpClient;
  AuthenticatedHttpClient? _authenticatedClient;

  static const String _tokenSetKey = 'auth_token_set';
  // Clés historiques (pré-NT-048), lues en fallback pour détecter les
  // installations sans refresh token ; jamais réécrites après migration.
  static const String _legacyTokenKey = 'jwt_token';
  static const String _legacyEmailKey = 'user_email';

  static const Duration _proactiveRefreshMargin = Duration(minutes: 2);

  // Single-flight : un refresh en cours est partagé par tous les appelants
  // concurrents (proactifs ou réactifs après 401) — jamais deux rotations
  // simultanées du même refresh token.
  Future<String>? _refreshFuture;

  AuthService({
    required String authBaseUrl,
    String? callbackScheme,
    FlutterSecureStorage? storage,
    http.Client? httpClient,
  })  : _authBaseUrl = authBaseUrl,
        _storage = storage ?? const FlutterSecureStorage(),
        _httpClient = httpClient ?? http.Client();

  AuthenticatedHttpClient get _authedClient => _authenticatedClient ??=
      AuthenticatedHttpClient(this, client: _httpClient);

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
      AppLogger.I.debug('AUTH: appel GET $loginUrl');

      // Étape 1 : Récupérer auth_url depuis le backend (timeout 15 s)
      final response = await _httpClient.get(Uri.parse(loginUrl)).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Le serveur ne répond pas (timeout 15 s). Vérifiez votre connexion.',
            ),
          );
      AppLogger.I.debug('AUTH: réponse ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
            'Échec de récupération de l\'URL OAuth (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final authUrl = data['auth_url'] as String?;

      if (authUrl == null || authUrl.isEmpty) {
        throw Exception('URL d\'authentification manquante');
      }

      // Étape 2 : Ouvrir auth_url dans le navigateur externe
      AppLogger.I.debug('AUTH: ouverture du navigateur pour OAuth');
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir le navigateur');
      }

      // Note : Le token sera récupéré via le deep link handler dans main.dart
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de l\'authentification Google', e);
      rethrow;
    }
  }

  /// Traite le callback deep link : échange le callback token contre une
  /// paire access + refresh token (NT-048), la persiste atomiquement, puis
  /// retourne le profil complet.
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

      // Échanger le token callback contre une paire access + refresh token
      final exchangeResponse = await _httpClient
          .post(
            Uri.parse('$_authBaseUrl/auth/token/exchange'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'callback_token': token}),
          )
          .timeout(const Duration(seconds: 15));

      if (exchangeResponse.statusCode != 200) {
        throw Exception(
            'Échec de l\'échange du token (${exchangeResponse.statusCode})');
      }

      final exchangeData =
          jsonDecode(exchangeResponse.body) as Map<String, dynamic>;
      final accessToken = exchangeData['access_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Token d\'accès manquant dans la réponse');
      }

      // Écriture atomique (un seul appel storage) de toute la paire de tokens.
      await _persistTokenResponse(exchangeData);

      // Récupérer les infos utilisateur complètes avec le nouveau token.
      return await getUserInfo();
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors du traitement du callback OAuth', e);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------
  // Stockage (NT-048)
  // ---------------------------------------------------------------------

  Future<_StoredTokenSet?> _readTokenSet() async {
    final raw = await _storage.read(key: _tokenSetKey);
    if (raw != null) {
      return _StoredTokenSet.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    // Installation historique (pré-NT-048) : un access token existe sans
    // refresh token associé. Traité comme "déjà expiré" pour forcer, au
    // premier besoin de renouvellement, une reconnexion Google unique.
    final legacyToken = await _storage.read(key: _legacyTokenKey);
    if (legacyToken == null || legacyToken.isEmpty) return null;
    final legacyEmail = await _storage.read(key: _legacyEmailKey);
    return _StoredTokenSet(
      accessToken: legacyToken,
      refreshToken: null,
      accessExpiresAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      refreshExpiresAt: null,
      email: legacyEmail,
    );
  }

  /// Remplace atomiquement la paire de tokens (un seul write storage).
  Future<void> _persistTokenResponse(Map<String, dynamic> data,
      {String? emailFallback}) async {
    final now = DateTime.now().toUtc();
    final expiresIn = data['expires_in'] as int? ?? 0;
    final refreshExpiresIn = data['refresh_expires_in'] as int?;
    final set = _StoredTokenSet(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
      accessExpiresAt: now.add(Duration(seconds: expiresIn)),
      refreshExpiresAt: refreshExpiresIn != null
          ? now.add(Duration(seconds: refreshExpiresIn))
          : null,
      email: (data['email'] as String?) ?? emailFallback,
    );
    await _storage.write(key: _tokenSetKey, value: jsonEncode(set.toJson()));
  }

  Future<void> _clearAll() async {
    await _storage.delete(key: _tokenSetKey);
    await _storage.delete(key: _legacyTokenKey);
    await _storage.delete(key: _legacyEmailKey);
  }

  // ---------------------------------------------------------------------
  // Renouvellement proactif + réactif (NT-048)
  // ---------------------------------------------------------------------

  /// Retourne un access token valide, en le renouvelant proactivement s'il
  /// expire bientôt. Les appels concurrents partagent le même renouvellement
  /// en cours (single-flight).
  ///
  /// Lève [SessionExpiredException] si aucune session locale n'existe ou si
  /// le refresh échoue définitivement (invalide/expiré/révoqué/rejoué, ou
  /// installation historique sans refresh token déjà expirée) ;
  /// [NetworkUnavailableException] si le renouvellement est nécessaire mais
  /// que le serveur est injoignable et que le token courant est déjà expiré.
  Future<String> getValidAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    final set = await _readTokenSet();
    if (set == null) {
      throw SessionExpiredException('Non authentifié.');
    }

    final now = DateTime.now().toUtc();
    final needsRefresh =
        set.accessExpiresAt.isBefore(now.add(_proactiveRefreshMargin));
    if (!needsRefresh) {
      return set.accessToken;
    }

    if (set.refreshToken == null) {
      // Installation historique sans refresh token : utilisable jusqu'à sa
      // propre expiration, puis reconnexion Google unique nécessaire.
      if (set.accessExpiresAt.isAfter(now)) {
        return set.accessToken;
      }
      await _clearAll();
      throw SessionExpiredException('Reconnexion requise.');
    }

    try {
      return await _refreshOrThrow();
    } on NetworkUnavailableException {
      // Panne réseau : le token courant n'est pas encore expiré -> on le
      // garde plutôt que de bloquer la requête ; sinon on ne peut rien faire.
      if (set.accessExpiresAt.isAfter(now)) {
        return set.accessToken;
      }
      rethrow;
    }
  }

  /// Appelé par [AuthenticatedHttpClient] après un premier `401` : tente un
  /// unique renouvellement (partagé si déjà en cours) avant un rejeu unique
  /// de la requête. N'introduit jamais de boucle.
  Future<String> forceRefreshAfterUnauthorized() {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    return _refreshOrThrow();
  }

  Future<String> _refreshOrThrow() {
    return _refreshFuture ??=
        _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String> _doRefresh() async {
    final set = await _readTokenSet();
    if (set == null || set.refreshToken == null) {
      await _clearAll();
      throw SessionExpiredException('Reconnexion requise.');
    }

    http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse('$_authBaseUrl/auth/token/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': set.refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw NetworkUnavailableException('Le serveur ne répond pas (timeout).');
    } on SocketException catch (e) {
      throw NetworkUnavailableException(
          'Connexion impossible (réseau ou DNS): ${e.message}');
    }

    if (response.statusCode == 401) {
      // Refresh invalide, expiré, révoqué ou rejoué : fin de session.
      await _clearAll();
      throw SessionExpiredException('Session expirée, reconnectez-vous.');
    }
    if (response.statusCode != 200) {
      // Erreur serveur inattendue : transitoire, on ne touche pas aux tokens.
      throw NetworkUnavailableException(
          'Erreur serveur (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _persistTokenResponse(data, emailFallback: set.email);
    return data['access_token'] as String;
  }

  // ---------------------------------------------------------------------
  // Lecture simple (sans effet de bord ni appel réseau)
  // ---------------------------------------------------------------------

  Future<String?> getToken() async {
    final set = await _readTokenSet();
    return set?.accessToken;
  }

  Future<String?> getEmail() async {
    final set = await _readTokenSet();
    return set?.email;
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ---------------------------------------------------------------------
  // Appels authentifiés — même mécanisme que le Coach (AuthenticatedHttpClient)
  // ---------------------------------------------------------------------

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    try {
      final response = await _authedClient
          .get(Uri.parse('$_authBaseUrl/users/me'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) {
        await logout();
        return false;
      }
      // Statut inattendu (5xx...) : erreur transitoire, pas une session invalide.
      return false;
    } on SessionExpiredException {
      return false;
    } catch (e) {
      AppLogger.I.error('AUTH: erreur lors de la vérification du token', e);
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Non authentifié');
    }

    try {
      final response = await _authedClient
          .get(Uri.parse('$_authBaseUrl/users/me'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final userInfo = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.I.debug('AUTH: getUserInfo keys=${userInfo.keys.toList()}');

        return userInfo;
      } else if (response.statusCode == 401) {
        await logout();
        throw SessionExpiredException('Session expirée, reconnectez-vous.');
      } else {
        throw Exception(
            'Erreur lors de la récupération du profil (${response.statusCode})');
      }
    } catch (e) {
      if (e is SessionExpiredException || e is NetworkUnavailableException) {
        rethrow;
      }
      AppLogger.I.error(
          'AUTH: erreur lors de la récupération des infos utilisateur', e);
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

      final response = await _authedClient
          .patch(
            Uri.parse('$_authBaseUrl/users/me/profile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await logout();
        throw SessionExpiredException('Session expirée, reconnectez-vous.');
      } else if (response.statusCode == 422) {
        throw Exception('Valeur invalide');
      } else {
        throw Exception(
            'Erreur lors de la mise à jour du profil (${response.statusCode})');
      }
    } catch (e) {
      if (e is SessionExpiredException || e is NetworkUnavailableException) {
        rethrow;
      }
      AppLogger.I.error('AUTH: erreur lors de la mise à jour du profil', e);
      rethrow;
    }
  }

  /// Déconnexion : tente la révocation serveur en best effort (échec
  /// silencieux si le réseau ou le serveur est indisponible), puis efface
  /// systématiquement toutes les données d'authentification locales.
  ///
  /// Attend d'abord tout renouvellement en cours pour éviter qu'une rotation
  /// concurrente ne réécrive des tokens juste après le nettoyage local.
  Future<void> logout() async {
    if (_refreshFuture != null) {
      try {
        await _refreshFuture;
      } catch (_) {
        // Peu importe l'issue du refresh en cours : le nettoyage local a
        // lieu dans tous les cas juste après.
      }
    }

    try {
      final set = await _readTokenSet();
      final refreshToken = set?.refreshToken;
      if (refreshToken != null) {
        await _httpClient
            .post(
              Uri.parse('$_authBaseUrl/auth/token/revoke'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}),
            )
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      AppLogger.I.debug(
          'AUTH: révocation serveur indisponible au logout (best effort)');
    } finally {
      await _clearAll();
    }
  }
}
