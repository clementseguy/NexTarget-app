import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';

void main() {
  test('sérialise et relit le contrat structuré', () {
    final original = CoachSessionAnalysis(
      analysisId: 'analysis',
      sessionId: 'session',
      debrief: 'Débrief',
      successes: const ['Réussite'],
      attentionPoint: 'Attention',
      limitations: const [],
      exerciseEvaluation: const ExerciseEvaluation(
        result: ExerciseResult.succeeded,
        debrief: 'Exercice réussi',
      ),
      nextAction: CoachNextAction.requestProgressionCoach,
      model: 'model',
      generatedAt: DateTime.utc(2026, 9, 11),
      reused: true,
    );
    final restored = CoachSessionAnalysis.fromMap(original.toMap());
    expect(restored.exerciseEvaluation?.result, ExerciseResult.succeeded);
    expect(restored.nextAction, CoachNextAction.requestProgressionCoach);
    expect(restored.reused, isTrue);
  });

  test('rejette une réponse sans réussite', () {
    expect(
      () => CoachSessionAnalysis.fromMap({
        'analysis_id': 'analysis',
        'session_id': 'session',
        'debrief': 'Débrief',
        'successes': <String>[],
        'attention_point': 'Attention',
        'limitations': <String>[],
        'model': 'model',
        'generated_at': '2026-09-11T00:00:00Z',
      }),
      throwsFormatException,
    );
  });
}
