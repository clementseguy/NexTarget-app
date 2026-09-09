import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/server_coach_analysis_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';
import 'package:tir_sportif/services/network_error.dart';
import 'package:tir_sportif/constants/session_constants.dart';

import 'auth_service_test.mocks.dart' show MockFlutterSecureStorage;

DetailedShootingSession _session() => DetailedShootingSession(
      weapon: 'Glock 17',
      caliber: '9mm',
      exerciseId: 'exercise-1',
      series: [
        Series(
            shotCount: 5,
            distance: 25,
            points: 45,
            groupSize: 8.5,
            comment: 'stable'),
      ],
      synthese: 'RAS',
    );

void main() {
  // Note: ServerCoachAnalysisService(client: ...) ignore l'AuthenticatedHttpClient
  // par défaut quand un client de test est injecté (mêmes conventions que
  // CoachAnalysisService), donc AuthService peut rester un stub minimal ici.
  final storage = MockFlutterSecureStorage();
  when(storage.delete(key: anyNamed('key')))
      .thenAnswer((_) async => Future<void>.value());
  final dummyAuthService = AuthService(
    authBaseUrl: 'http://unused',
    storage: storage,
  );

  test('analyzeSession success returns analysis text', () async {
    final client = MockClient((req) async {
      expect(req.url.path, '/coach/analyze-session');
      return http.Response(
          '{"analysis":"OK","model":"m","generated_at":"2026-07-07T10:00:00Z"}',
          200);
    });
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    final out = await svc.analyzeSession(_session());
    expect(out, 'OK');
  });

  test('un brouillon est rejeté avant tout appel Coach', () async {
    var called = false;
    final client = MockClient((req) async {
      called = true;
      return http.Response('{"analysis":"OK"}', 200);
    });
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    final draft = _session()..status = SessionConstants.statusDraft;

    await expectLater(
      svc.analyzeSession(draft),
      throwsA(predicate((e) => e.toString().contains('session réalisée'))),
    );
    expect(called, isFalse);
  });

  test(
      'analyzeSession envoie le prompt_variant choisi (NT-032), défaut coach_neutre',
      () async {
    final capturedVariants = <String>[];
    final capturedExerciseIds = <String?>[];
    final client = MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      capturedVariants.add(body['prompt_variant'] as String);
      capturedExerciseIds.add(
        (body['session'] as Map<String, dynamic>)['exerciseId'] as String?,
      );
      return http.Response('{"analysis":"OK"}', 200);
    });
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);

    await svc.analyzeSession(_session());
    await svc.analyzeSession(_session(), promptVariant: 'coach_cool');

    expect(capturedVariants, ['coach_neutre', 'coach_cool']);
    expect(capturedExerciseIds, ['exercise-1', 'exercise-1']);
  });

  test('analyzeSession 401 throws session expirée', () async {
    final client = MockClient((req) async => http.Response('{}', 401));
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    await expectLater(
      svc.analyzeSession(_session()),
      throwsA(isA<SessionExpiredException>()),
    );
  });

  test('analyzeSession 429 throws trop de requêtes', () async {
    final client = MockClient((req) async => http.Response('{}', 429));
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    await expectLater(
      svc.analyzeSession(_session()),
      throwsA(isA<NetworkOperationException>().having(
        (error) => error.family,
        'family',
        NetworkErrorFamily.rateLimited,
      )),
    );
  });

  test('analyzeSession 5xx throws erreur serveur', () async {
    final client = MockClient((req) async => http.Response('{}', 503));
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    await expectLater(
      svc.analyzeSession(_session()),
      throwsA(isA<NetworkOperationException>().having(
        (error) => error.family,
        'family',
        NetworkErrorFamily.serviceUnavailable,
      )),
    );
  });

  test('analyzeSession malformed content throws réponse vide', () async {
    final client =
        MockClient((req) async => http.Response('{"analysis":""}', 200));
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()),
        throwsA(predicate((e) => e.toString().contains('Réponse vide'))));
  });

  test('analyzeSession SocketException produces user-friendly message',
      () async {
    final client =
        MockClient((req) async => throw SocketException('Failed host lookup'));
    final svc = ServerCoachAnalysisService(
        baseUrl: 'http://x', authService: dummyAuthService, client: client);
    await expectLater(
      svc.analyzeSession(_session()),
      throwsA(isA<NetworkOperationException>().having(
        (error) => error.family,
        'family',
        NetworkErrorFamily.offline,
      )),
    );
  });
}
