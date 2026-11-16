import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/exercise_execution.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';

CoachSessionAnalysis _analysis() => CoachSessionAnalysis(
      analysisId: 'analysis-1',
      sessionId: 'session-1',
      debrief: 'Débrief',
      successes: const ['Réussite'],
      attentionPoint: 'Attention',
      limitations: const [],
      exerciseEvaluation: null,
      nextAction: null,
      model: 'model',
      generatedAt: DateTime.utc(2026, 9, 12),
    );

void main() {
  group('ShootingSession model mapping & flags', () {
    test('toMap/fromMap roundtrip with series and fields', () {
      final ss = DetailedShootingSession(
        id: 12,
        date: DateTime(2025, 10, 7, 12, 0, 0),
        weapon: 'P',
        caliber: '22LR',
        status: 'réalisée',
        coachAnalysis: _analysis(),
        synthese: 'S',
        category: 'match',
        series: [Series(distance: 10, points: 50, groupSize: 20)],
        exerciseId: 'ex1',
        exerciseExecution: const ExerciseExecution(
          performed: true,
          protocolFollowed: ProtocolFollowed.partially,
          comment: '  Dernière série adaptée.  ',
        ),
        photoPath: '/tmp/session_photos/target_abc.jpg',
      );
      final map = ss.toMap();
      final ss2 = ShootingSession.fromMap(Map<String, dynamic>.from(map));
      expect(ss2.id, 12);
      expect(ss2.weapon, 'P');
      expect(ss2.caliber, '22LR');
      expect(ss2.status, 'réalisée');
      expect(ss2.category, 'match');
      expect(ss2.series.length, 1);
      expect(ss2.series.first.points, 50);
      expect(ss2.exerciseId, 'ex1');
      expect(ss2.exerciseExecution?.performed, isTrue);
      expect(
        ss2.exerciseExecution?.protocolFollowed,
        ProtocolFollowed.partially,
      );
      expect(ss2.exerciseExecution?.comment, 'Dernière série adaptée.');
      expect(ss2.hasAnalysis, isTrue);
      expect(ss2.hasSynthese, isTrue);
      expect(ss2.photoPath, '/tmp/session_photos/target_abc.jpg');
      expect(ss2.hasPhoto, isTrue);
    });

    test('fromMap tolerates missing/empty series and exercises', () {
      final ss = ShootingSession.fromMap({
        'weapon': 'C',
        'caliber': '9mm',
      });
      expect(ss.series, isEmpty);
      expect(ss.exerciseId, isNull);
      expect(ss.exerciseExecution, isNull);
      expect(ss.status, 'réalisée');
      expect(ss.category, 'entraînement');
      expect(ss.hasAnalysis, isFalse);
      expect(ss.hasSynthese, isFalse);
      expect(ss.photoPath, isNull);
      expect(ss.hasPhoto, isFalse);
    });

    test('tolère une qualification historique partielle ou invalide', () {
      final session = ShootingSession.fromMap({
        'weapon': 'P',
        'caliber': '9 mm',
        'exerciseId': 'ex-1',
        'exerciseExecution': {
          'performed': 'inconnu',
          'protocolFollowed': 'presque',
          'comment': 42,
        },
      }) as DetailedShootingSession;

      expect(session.exerciseExecution?.performed, isNull);
      expect(session.exerciseExecution?.protocolFollowed, isNull);
      expect(session.exerciseExecution?.comment, isNull);
    });

    test('relit uniquement le premier exercice d’une sauvegarde historique',
        () {
      final session = ShootingSession.fromMap({
        'weapon': 'P',
        'caliber': '9 mm',
        'exercises': ['first', 'second'],
      });

      expect(session.exerciseId, 'first');
      expect(session.toMap().containsKey('exercises'), isFalse);
    });

    test('hasPhoto is false for a blank photoPath', () {
      final ss = DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        series: const [],
        photoPath: '   ',
      );
      expect(ss.hasPhoto, isFalse);
    });
  });
}
