import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/exercise_execution.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';
import 'package:tir_sportif/services/coach_analysis_exception.dart';
import 'package:tir_sportif/services/network_error.dart';
import 'package:tir_sportif/services/server_coach_analysis_service.dart';

import 'auth_service_test.mocks.dart' show MockFlutterSecureStorage;

DetailedShootingSession _session({bool withExercise = false}) =>
    DetailedShootingSession(
      sessionUuid: '123e4567-e89b-42d3-a456-426614174000',
      date: DateTime.utc(2026, 9, 11, 18, 30),
      weapon: 'Glock 17',
      caliber: '9mm',
      category: 'entraînement',
      exerciseId: withExercise ? 'exercise-1' : null,
      series: [
        Series(
          id: 7,
          shotCount: 5,
          distance: 25,
          points: 45,
          groupSize: 8.5,
          comment: 'stable',
          handMethod: HandMethod.oneHand,
        ),
      ],
      synthese: 'RAS',
      exerciseExecution: withExercise
          ? const ExerciseExecution(
              performed: true,
              protocolFollowed: ProtocolFollowed.partially,
              comment: 'Protocole adapté à la troisième série',
            )
          : null,
    );

Exercise _exercise({
  ExerciseOrigin origin = ExerciseOrigin.personal,
  String name = 'Tenue du lâcher',
}) =>
    Exercise(
      id: 'exercise-1',
      name: name,
      categoryEnum: ExerciseCategory.technique,
      type: ExerciseType.stand,
      difficulty: ExerciseDifficulty.advanced,
      origin: origin,
      description: 'Stabiliser le départ du coup',
      durationMinutes: 20,
      equipment: 'Arme et cible',
      createdAt: DateTime.utc(2026, 9, 11),
      priority: 2,
      goalIds: const ['goal-1'],
      consignes: const ['Viser', 'Presser progressivement'],
    );

String _response({String result = 'failed'}) => jsonEncode({
      'analysis_id': '123e4567-e89b-42d3-a456-426614174001',
      'session_id': '123e4567-e89b-42d3-a456-426614174000',
      'debrief': 'Session régulière.',
      'successes': ['Groupement stable.'],
      'attention_point': 'Surveiller le score.',
      'limitations': ['Une seule série.'],
      'exercise_evaluation': {
        'result': result,
        'debrief': 'Protocole partiellement suivi.',
      },
      'next_action': 'repeat_exercise',
      'model': 'm',
      'generated_at': '2026-09-11T18:35:00Z',
      'reused': false,
    });

void main() {
  final storage = MockFlutterSecureStorage();
  when(storage.delete(key: anyNamed('key')))
      .thenAnswer((_) async => Future<void>.value());
  final authService = AuthService(
    authBaseUrl: 'http://unused',
    storage: storage,
  );

  ServerCoachAnalysisService service(http.Client client) =>
      ServerCoachAnalysisService(
        baseUrl: 'http://x',
        authService: authService,
        client: client,
      );

  test('retourne et valide le débrief structuré', () async {
    final output = await service(
      MockClient((_) async => http.Response(_response(), 200)),
    ).analyzeSession(
      _session(withExercise: true),
      coachDataSharingAllowed: true,
      exercise: _exercise(),
      experienceLevel: 'advanced',
    );
    expect(output.debrief, 'Session régulière.');
    expect(output.successes, ['Groupement stable.']);
    expect(output.exerciseEvaluation?.result, ExerciseResult.failed);
    expect(output.nextAction, CoachNextAction.repeatExercise);
  });

  test('transmet le snapshot complet, le niveau et l’exercice personnel',
      () async {
    late Map<String, dynamic> body;
    final client = MockClient((request) async {
      body = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(_response(), 200);
    });
    await service(client).analyzeSession(
      _session(withExercise: true),
      coachDataSharingAllowed: true,
      exercise: _exercise(),
      experienceLevel: 'advanced',
    );
    final session = body['session'] as Map<String, dynamic>;
    expect(session['session_id'], '123e4567-e89b-42d3-a456-426614174000');
    expect(session['status'], 'réalisée');
    expect(session['category'], 'entraînement');
    expect(session['exercise_origin'], 'personal');
    expect(body['experience_level'], 'advanced');
    expect(session['series'].single['hand_method'], 'one');
    expect(session['series'].single['completed'], isTrue);
    expect(session['exercise_execution'], {
      'performed': true,
      'protocol_followed': 'partially',
      'comment': 'Protocole adapté à la troisième série',
    });
    expect(session['personal_exercise'].keys, {
      'id',
      'name',
      'origin',
      'description',
      'consignes',
    });
  });

  test('un exercice catalogue envoie sa provenance sans son contenu', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((request) async {
      sent = (jsonDecode(request.body) as Map<String, dynamic>)['session']
          as Map<String, dynamic>;
      return http.Response(_response(result: 'succeeded'), 200);
    });
    await service(client).analyzeSession(
      _session(withExercise: true),
      coachDataSharingAllowed: true,
      exercise: _exercise(origin: ExerciseOrigin.coachCatalog),
    );
    expect(sent['exercise_origin'], 'coach_catalog');
    expect(sent['personal_exercise'], isNull);
    expect(sent['exercise_execution'], isNotNull);
  });

  test('rejette une session dont l’exercice associé est indisponible',
      () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response(_response(), 200);
    });
    await expectLater(
      service(client).analyzeSession(
        _session(withExercise: true),
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<InvalidNetworkRequestException>()),
    );
    expect(called, isFalse);
  });

  test('rejette localement un instantané personnel hors limites', () async {
    final oversized = List.filled(
      ServerCoachAnalysisService.personalExerciseNameMaxLength + 1,
      'x',
    ).join();
    await expectLater(
      service(MockClient((_) async => http.Response(_response(), 200)))
          .analyzeSession(
        _session(withExercise: true),
        coachDataSharingAllowed: true,
        exercise: _exercise(name: oversized),
      ),
      throwsA(isA<InvalidNetworkRequestException>()),
    );
  });

  test('un brouillon est rejeté avant tout appel Coach', () async {
    var called = false;
    final draft = _session()..status = SessionConstants.statusDraft;
    final client = MockClient((_) async {
      called = true;
      return http.Response(_response(), 200);
    });
    await expectLater(
      service(client).analyzeSession(
        draft,
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<CoachAnalysisException>()),
    );
    expect(called, isFalse);
  });

  test('consentement absent : aucune requête envoyée', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response(_response(), 200);
    });
    await expectLater(
      service(client).analyzeSession(
        _session(),
        coachDataSharingAllowed: false,
      ),
      throwsA(isA<CoachConsentRequiredException>()),
    );
    expect(called, isFalse);
  });

  test('une réponse structurée invalide est rejetée', () async {
    await expectLater(
      service(MockClient((_) async => http.Response('{"debrief":"x"}', 200)))
          .analyzeSession(
        _session(),
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<CoachAnalysisException>()),
    );
  });

  test('401 invalide la session et 429 est présenté comme rate limit',
      () async {
    await expectLater(
      service(MockClient((_) async => http.Response('{}', 401))).analyzeSession(
        _session(),
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<SessionExpiredException>()),
    );
    await expectLater(
      service(MockClient((_) async => http.Response('{}', 429))).analyzeSession(
        _session(),
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<NetworkOperationException>().having(
        (error) => error.family,
        'family',
        NetworkErrorFamily.rateLimited,
      )),
    );
  });

  test('SocketException est présentée comme indisponibilité réseau', () async {
    final client = MockClient((_) async => throw const SocketException('DNS'));
    await expectLater(
      service(client).analyzeSession(
        _session(),
        coachDataSharingAllowed: true,
      ),
      throwsA(isA<NetworkOperationException>().having(
        (error) => error.family,
        'family',
        NetworkErrorFamily.offline,
      )),
    );
  });
}
