import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';

/// NT-048 (revue PR #25) — une panne réseau au démarrage ne doit pas
/// désauthentifier un utilisateur qui possède déjà des tokens locaux.
class _NetworkDownAuthService extends AuthService {
  _NetworkDownAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<bool> isAuthenticated() async {
    throw NetworkUnavailableException('offline');
  }

  @override
  Future<Map<String, dynamic>?> readCachedUser() async => const {
        'email': 'tireur@example.com',
      };

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    throw NetworkUnavailableException('offline');
  }
}

class _SessionExpiredAuthService extends AuthService {
  _SessionExpiredAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<bool> isAuthenticated() async {
    throw SessionExpiredException('reconnexion requise');
  }

  @override
  Future<Map<String, dynamic>?> readCachedUser() async => null;

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    throw SessionExpiredException('reconnexion requise');
  }
}

class _CallbackNetworkDownAuthService extends AuthService {
  _CallbackNetworkDownAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<Map<String, dynamic>> getUserInfo() async => const {
        'email': 'tireur@example.com',
      };

  @override
  Future<Map<String, dynamic>?> readCachedUser() async => null;

  @override
  Future<Map<String, dynamic>> handleCallback(Uri callbackUri) async {
    throw NetworkUnavailableException('DNS interne');
  }
}

class _RetryAuthService extends AuthService {
  Object firstResult;
  final Map<String, dynamic>? cachedUser;
  var calls = 0;

  _RetryAuthService({required this.firstResult, this.cachedUser})
      : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<Map<String, dynamic>?> readCachedUser() async => cachedUser;

  @override
  Future<Map<String, dynamic>> getUserInfo() async {
    calls++;
    if (calls == 1) throw firstResult;
    return const {'email': 'retour@example.com', 'display_name': 'Retour'};
  }
}

void main() {
  group('AuthProvider.checkAuthStatus', () {
    test(
        'panne réseau au démarrage : préserve un token local comme authentifié',
        () async {
      final provider = AuthProvider(_NetworkDownAuthService());

      await provider.checkAuthStatus();

      expect(provider.isAuthenticated, isTrue);
      expect(provider.isLoading, isFalse);
    });

    test('refresh réellement invalide/expiré/révoqué : session terminée',
        () async {
      final provider = AuthProvider(_SessionExpiredAuthService());

      await provider.checkAuthStatus();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.currentUser, isNull);
    });
  });

  test('une panne transitoire du callback préserve la session existante',
      () async {
    final provider = AuthProvider(_CallbackNetworkDownAuthService());
    await provider.checkAuthStatus();

    await expectLater(
      provider.handleAuthCallback(Uri.parse('nextarget://callback?token=test')),
      throwsA(isA<NetworkUnavailableException>()),
    );

    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?['email'], 'tireur@example.com');
    expect(provider.isLoading, isFalse);
  });

  test('hors ligne sans cache reste en vérification puis Réessayer connecte',
      () async {
    final service = _RetryAuthService(
      firstResult: NetworkUnavailableException('offline'),
    );
    final provider = AuthProvider(service);

    await provider.checkAuthStatus();

    expect(provider.status, AuthStatus.verifying);
    expect(provider.isVerificationPending, isTrue);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.currentUser, isNull);
    expect(service.calls, 1);

    await provider.checkAuthStatus();

    expect(provider.status, AuthStatus.authenticated);
    expect(provider.currentUser?['display_name'], 'Retour');
    expect(service.calls, 2);
  });

  test('l’état de vérification reste exposé pendant un contrôle actif',
      () async {
    final service = _RetryAuthService(
      firstResult: NetworkUnavailableException('offline'),
    );
    final provider = AuthProvider(service);

    final verification = provider.checkAuthStatus();

    expect(provider.status, AuthStatus.verifying);
    expect(provider.isVerificationPending, isTrue);
    expect(provider.isLoading, isTrue);

    await verification;
  });

  test('hors ligne avec cache conserve un état connecté exploitable', () async {
    final provider = AuthProvider(_RetryAuthService(
      firstResult: NetworkUnavailableException('offline'),
      cachedUser: const {
        'email': 'cache@example.com',
        'display_name': 'Cache Valide',
      },
    ));

    await provider.checkAuthStatus();

    expect(provider.status, AuthStatus.authenticated);
    expect(provider.isAuthenticated, isTrue);
    expect(provider.currentUser?['display_name'], 'Cache Valide');
  });

  test('hors ligne sans cache puis invalidation confirmée déconnecte',
      () async {
    final service = _RetryAuthService(
      firstResult: NetworkUnavailableException('offline'),
    );
    final provider = AuthProvider(service);
    await provider.checkAuthStatus();
    service.firstResult = SessionExpiredException('révoqué');
    service.calls = 0;

    await provider.checkAuthStatus();

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.isAuthenticated, isFalse);
    expect(provider.currentUser, isNull);
  });
}
