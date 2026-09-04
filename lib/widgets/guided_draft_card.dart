import 'package:flutter/material.dart';

import '../models/shooting_session.dart';

class GuidedDraftCard extends StatelessWidget {
  final DetailedShootingSession draft;
  final VoidCallback onResume;
  final VoidCallback onAbandon;

  const GuidedDraftCard({
    super.key,
    required this.draft,
    required this.onResume,
    required this.onAbandon,
  });

  @override
  Widget build(BuildContext context) {
    final completed = draft.completedSeriesCount;
    final total = draft.series.length;
    final progress = total == 0 ? 0.0 : completed / total;
    return Semantics(
      container: true,
      label: 'Séance en cours, $completed séries sur $total',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sports_score,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Séance en cours',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Abandonner la séance en cours',
                    onPressed: onAbandon,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              Text('${draft.weapon} · ${draft.caliber}'),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(
                '$completed / $total séries · '
                '${draft.completedShotCount} coups enregistrés',
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reprendre'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
