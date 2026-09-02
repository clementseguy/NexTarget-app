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
}

class _SessionExpiredAuthService extends AuthService {
  _SessionExpiredAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => true;

  @override
  Future<bool> isAuthenticated() async {
    throw SessionExpiredException('reconnexion requise');
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
}
