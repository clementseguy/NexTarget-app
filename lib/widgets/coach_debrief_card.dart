import 'package:flutter/material.dart';

import '../models/coach_session_analysis.dart';

class CoachDebriefCard extends StatelessWidget {
  final CoachSessionAnalysis analysis;

  const CoachDebriefCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.secondary, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Débrief factuel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(analysis.debrief),
            const SizedBox(height: 16),
            const Text('Réussites',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final success in analysis.successes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(success)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            const Text('Point d’attention',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(analysis.attentionPoint),
            if (analysis.exerciseEvaluation case final evaluation?) ...[
              const SizedBox(height: 16),
              const Text('Évaluation de l’exercice',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Chip(label: Text(_resultLabel(evaluation.result))),
              Text(evaluation.debrief),
            ],
            if (analysis.limitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Limites',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              for (final limitation in analysis.limitations)
                Text('• $limitation'),
            ],
            if (analysis.nextAction case final action?) ...[
              const SizedBox(height: 16),
              Text(
                'Prochaine action : ${_actionLabel(action)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resultLabel(ExerciseResult result) => switch (result) {
        ExerciseResult.succeeded => 'Réussi',
        ExerciseResult.failed => 'Échoué',
        ExerciseResult.notEvaluable => 'Non évaluable',
      };

  String _actionLabel(CoachNextAction action) => switch (action) {
        CoachNextAction.repeatExercise => 'refaire l’exercice',
        CoachNextAction.requestProgressionCoach =>
          'solliciter le Coach de progression',
      };
}
