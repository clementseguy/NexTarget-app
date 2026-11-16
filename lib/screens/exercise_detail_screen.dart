import 'package:flutter/material.dart';

import '../models/exercise.dart';

/// Consultation en lecture seule d'un exercice fourni par le Coach.
class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen(this.exercise, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’exercice')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(exercise.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Créé par le Coach',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          _Detail(label: 'Catégorie', value: exercise.categoryLabelFr),
          _Detail(label: 'Type', value: exercise.typeLabelFr),
          _Detail(label: 'Difficulté', value: exercise.difficultyLabelFr),
          if (exercise.description?.trim().isNotEmpty == true)
            _Detail(label: 'Description', value: exercise.description!.trim()),
          if (exercise.durationMinutes != null)
            _Detail(
              label: 'Durée',
              value: '${exercise.durationMinutes} min',
            ),
          if (exercise.equipment?.trim().isNotEmpty == true)
            _Detail(
                label: 'Matériel requis', value: exercise.equipment!.trim()),
          if (exercise.consignes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Consignes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...exercise.consignes.indexed.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
                title: Text(entry.$2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
