import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';
import 'package:tir_sportif/widgets/coach_debrief_card.dart';

void main() {
  testWidgets('affiche toutes les sections structurées du débrief',
      (tester) async {
    final analysis = CoachSessionAnalysis(
      analysisId: 'analysis-1',
      sessionId: 'session-1',
      debrief: 'Session régulière.',
      successes: const ['Groupement stable.', 'Score renseigné.'],
      attentionPoint: 'Surveiller la dernière série.',
      limitations: const ['Deux séries seulement.'],
      exerciseEvaluation: const ExerciseEvaluation(
        result: ExerciseResult.failed,
        debrief: 'Le protocole a été partiellement suivi.',
      ),
      nextAction: CoachNextAction.repeatExercise,
      model: 'model',
      generatedAt: DateTime.utc(2026, 9, 11),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CoachDebriefCard(analysis: analysis)),
      ),
    );
    expect(find.text('Débrief factuel'), findsOneWidget);
    expect(find.text('Groupement stable.'), findsOneWidget);
    expect(find.text('Échoué'), findsOneWidget);
    expect(find.textContaining('Deux séries seulement.'), findsOneWidget);
    expect(find.textContaining('refaire l’exercice'), findsOneWidget);
  });
}
