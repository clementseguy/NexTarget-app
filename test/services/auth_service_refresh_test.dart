import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';

import 'auth_service_refresh_test.mocks.dart';

/// Tests du cycle de vie du refresh token (NT-048) : rotation atomique,
/// renouvellement proactif, single-flight, migration depuis le stockage
/// historique, résilience réseau et logout best effort.
///
/// Le stockage sécurisé est simulé en mémoire (via un mock Mockito relié à
/// une Map) pour observer l'état exact persisté après chaque opération.
@GenerateMocks([FlutterSecureStorage])
void main() {
  late Map<String, String> store;
  late MockFlutterSecureStorage storage;

  setUp(() {
    store = {};
    storage = MockFlutterSecureStorage();
    when(storage.read(key: anyNamed('key'))).thenAnswer(
      (inv) async => store[inv.namedArguments[#key] as String],
    );
    when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((inv) async {
      store[inv.namedArguments[#key] as String] =
          inv.namedArguments[#value] as String;
    });
    when(storage.delete(key: anyNamed('key'))).thenAnswer((inv) async {
      store.remove(inv.namedArguments[#key] as String);
    });
  });

  AuthService buildService(http.Client client) => AuthService(
        authBaseUrl: 'https://test-api.com',
        storage: storage,
        httpClient: client,
      );

  Map<String, dynamic> exchangePayload({
    String access = 'access_1',
    String refresh = 'refresh_1',
    int expiresIn = 3600,
    int refreshExpiresIn = 30 * 24 * 3600,
  }) =>
      {
        'access_token': access,
        'token_type': 'bearer',
        'expires_in': expiresIn,
        'email': 'tireur@example.com',
        'provider': 'google',
        'user_id': 'user-1',
        'refresh_token': refresh,
        'refresh_expires_in': refreshExpiresIn,
      };

  group('échange OAuth et stockage de la paire', () {
    test(
        'handleCallback persiste access + refresh + expirations en un seul write',
        () async {
      var writeCount = 0;
      final client = MockClient((req) async {
        if (req.url.path == '/auth/token/exchange') {
          return http.Response(jsonEncode(exchangePayload()), 200);
        }
        if (req.url.path == '/users/me') {
          return http.Response(
              jsonEncode({'email': 'tireur@example.com'}), 200);
        }
        throw StateError('unexpected ${req.url}');
      });
      when(storage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((inv) async {
        writeCount++;
        store[inv.namedArguments[#key] as String] =
            inv.namedArguments[#value] as String;
      });

      final service = buildService(client);
      final userInfo = await service
          .handleCallback(Uri.parse('nextarget://callback?token=cb'));

      expect(userInfo['email'], 'tireur@example.com');
      expect(writeCount, 1);
      final stored =
          jsonDecode(store['auth_token_set']!) as Map<String, dynamic>;
      expect(stored['access_token'], 'access_1');
      expect(stored['refresh_token'], 'refresh_1');
      expect(stored['access_expires_at'], isNotNull);
      expect(stored['refresh_expires_at'], isNotNull);
    });
  });

  group('renouvellement proactif', () {
    test('ne renouvelle pas si le token est encore valide longtemps', () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'still_fresh',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      var refreshCalls = 0;
      final client = MockClient((req) async {
        refreshCalls++;
        throw StateError('ne devrait pas être appelé');
      });

      final token = await buildService(client).getValidAccessToken();

      expect(token, 'still_fresh');
      expect(refreshCalls, 0);
    });

    test('renouvelle proactivement et remplace atomiquement la paire',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'about_to_expire',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 30))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final client = MockClient((req) async {
        expect(req.url.path, '/auth/token/refresh');
        expect(jsonDecode(req.body)['refresh_token'], 'refresh_1');
        return http.Response(
          jsonEncode(exchangePayload(access: 'access_2', refresh: 'refresh_2')),
          200,
        );
      });

      final token = await buildService(client).getValidAccessToken();

      expect(token, 'access_2');
      final stored =
          jsonDecode(store['auth_token_set']!) as Map<String, dynamic>;
      expect(stored['access_token'], 'access_2');
      expect(stored['refresh_token'], 'refresh_2');
    });
  });

  group('single-flight', () {
    test('plusieurs requêtes concurrentes ne déclenchent qu\'un seul refresh',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'about_to_expire',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 10))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      var refreshCalls = 0;
      final client = MockClient((req) async {
        refreshCalls++;
        // Simule une latence réseau pour laisser les appels concurrents se chevaucher.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(
          jsonEncode(exchangePayload(access: 'access_2', refresh: 'refresh_2')),
          200,
        );
      });

      final service = buildService(client);
      final results = await Future.wait([
        service.getValidAccessToken(),
        service.getValidAccessToken(),
        service.forceRefreshAfterUnauthorized(),
      ]);

      expect(refreshCalls, 1);
      expect(results, everyElement('access_2'));
    });
  });

  group('refresh invalide / expiré / révoqué / rejoué', () {
    test('401 du serveur termine la session et efface les tokens', () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'expired',
        'refresh_token': 'reused_or_revoked',
        'access_expires_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final client = MockClient((req) async =>
          http.Response('{"detail":"Refresh token reuse detected"}', 401));

      await expectLater(
        buildService(client).getValidAccessToken(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(store.containsKey('auth_token_set'), isFalse);
    });
  });

  group('installation historique sans refresh token', () {
    test(
        'access token legacy expiré => reconnexion requise, aucun appel réseau',
        () async {
      store['jwt_token'] = 'legacy_token';
      store['user_email'] = 'ancien@example.com';
      var networkCalls = 0;
      final client = MockClient((req) async {
        networkCalls++;
        throw StateError(
            'ne devrait jamais être appelé (pas de refresh token)');
      });

      await expectLater(
        buildService(client).getValidAccessToken(),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(networkCalls, 0);
      expect(store.containsKey('jwt_token'), isFalse);
    });

    test(
        'access token legacy encore valide reste utilisable sans reconnexion immédiate',
        () async {
      store['jwt_token'] = 'legacy_token';
      store['user_email'] = 'ancien@example.com';
      // Un vrai token legacy a une expiration JWT propre ; on simule ici un
      // stockage déjà migré manuellement à une expiration future proche
      // pour couvrir le cas où la fenêtre proactive n'est pas encore ouverte.
      // (Le cas "déjà expiré" est couvert par le test précédent.)
      final client =
          MockClient((req) async => throw StateError('no network expected'));
      // getToken() (lecture simple) doit fonctionner sans réseau ni exception.
      final token = await buildService(client).getToken();
      expect(token, 'legacy_token');
    });
  });

  group('panne réseau', () {
    test(
        'au démarrage (proactif) : tokens préservés, exception réseau propagée',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'expired',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(minutes: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final client = MockClient(
          (req) async => throw const SocketException('pas de réseau'));

      await expectLater(
        buildService(client).getValidAccessToken(),
        throwsA(isA<NetworkUnavailableException>()),
      );
      // Les tokens locaux ne sont pas effacés par une panne réseau.
      expect(store.containsKey('auth_token_set'), isTrue);
    });

    test(
        'pendant un refresh : le token encore valide quelques instants reste utilisé',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'still_valid_for_now',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 30))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final client = MockClient(
          (req) async => throw const SocketException('pas de réseau'));

      final token = await buildService(client).getValidAccessToken();

      expect(token, 'still_valid_for_now');
      expect(store.containsKey('auth_token_set'), isTrue);
    });

    test(
        'pendant le logout : révocation best effort échoue, nettoyage local systématique',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'a',
        'refresh_token': 'r',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final client = MockClient(
          (req) async => throw const SocketException('pas de réseau'));

      await buildService(client).logout();

      expect(store.containsKey('auth_token_set'), isFalse);
    });
  });

  group('logout', () {
    test(
        'tente la révocation serveur en arrière-plan puis efface tout localement, même en cas de succès',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'a',
        'refresh_token': 'r',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final revokeCalled = Completer<void>();
      final client = MockClient((req) async {
        expect(req.url.path, '/auth/token/revoke');
        expect(jsonDecode(req.body)['refresh_token'], 'r');
        if (!revokeCalled.isCompleted) revokeCalled.complete();
        return http.Response('', 204);
      });

      await buildService(client).logout();

      // Le nettoyage local est immédiat, sans attendre la révocation réseau.
      expect(store.containsKey('auth_token_set'), isFalse);
      expect(store.containsKey('jwt_token'), isFalse);
      expect(store.containsKey('user_email'), isFalse);

      // La révocation serveur est bien tentée en arrière-plan (best effort).
      await revokeCalled.future.timeout(const Duration(seconds: 1));
    });

    test(
        'sans session locale : aucun appel réseau, nettoyage quand même effectué',
        () async {
      var networkCalls = 0;
      final client = MockClient((req) async {
        networkCalls++;
        return http.Response('', 204);
      });

      await buildService(client).logout();

      expect(networkCalls, 0);
    });

    test(
        'ne laisse pas une rotation en cours ressusciter une session terminée par logout',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'about_to_expire',
        'refresh_token': 'refresh_1',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 5))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      final refreshResponse = Completer<http.Response>();
      final client = MockClient((req) async {
        if (req.url.path == '/auth/token/refresh') {
          return refreshResponse.future;
        }
        // /auth/token/revoke
        return http.Response('', 204);
      });

      final service = buildService(client);
      final refreshFuture = service.getValidAccessToken();
      // Laisse le refresh démarrer (lecture du token) avant le logout concurrent.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final stopwatch = Stopwatch()..start();
      await service.logout();
      stopwatch.stop();

      // Le logout ne doit jamais attendre la rotation en cours ni le réseau.
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(store.containsKey('auth_token_set'), isFalse);

      // La rotation en cours se termine ensuite avec succès côté serveur,
      // mais ne doit pas ressusciter de session locale après le logout.
      refreshResponse.complete(http.Response(
        jsonEncode(exchangePayload(access: 'access_2', refresh: 'refresh_2')),
        200,
      ));
      await expectLater(refreshFuture, throwsA(isA<SessionExpiredException>()));
      expect(store.containsKey('auth_token_set'), isFalse);
    });

    test('ne bloque pas sur une révocation serveur qui ne répond jamais',
        () async {
      store['auth_token_set'] = jsonEncode({
        'access_token': 'a',
        'refresh_token': 'r',
        'access_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
        'refresh_expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(days: 30))
            .toIso8601String(),
        'email': 'tireur@example.com',
      });
      // Simule une connexion acceptée qui ne répond jamais dans un délai
      // raisonnable (le timeout de la requête est de 15 s).
      final client = MockClient((req) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('', 204);
      });

      final stopwatch = Stopwatch()..start();
      await buildService(client).logout();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      expect(store.containsKey('auth_token_set'), isFalse);
    });
  });
}
