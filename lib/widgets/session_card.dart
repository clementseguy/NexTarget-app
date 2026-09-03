import 'package:flutter/material.dart';

import '../constants/session_constants.dart';
import 'session_chip.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<dynamic> series;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SessionCard({
    required this.session,
    required this.series,
    this.onTap,
    this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    final isPlanned = session['status'] == 'prévue';
    final isSimple = session['sessionType'] == 'simple';
    final exerciseIds = session['exercises'] is List
        ? session['exercises'] as List<dynamic>
        : const <dynamic>[];
    final totalPoints = series.fold<int>(
      0,
      (sum, item) => sum + ((item['points'] ?? 0) as int),
    );
    final avgScore = series.isEmpty ? 0.0 : totalPoints / series.length;
    final avgGroup = series.isEmpty
        ? 0.0
        : series
                .map((item) => (item['group_size'] ?? 0.0) as num)
                .fold<double>(0, (sum, value) => sum + value.toDouble()) /
            series.length;
    final colors = Theme.of(context).colorScheme;
    final accent = isPlanned
        ? Colors.blueAccent
        : isSimple
            ? colors.secondary
            : colors.primary;
    final identityColor = isPlanned ? Colors.blueAccent : null;
    final hasCoachAnalysis =
        !isSimple && (session['analyse'] as String?)?.trim().isNotEmpty == true;

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.55), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                key: const Key('sessionCardDateColumn'),
                width: 46,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 21, color: accent),
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isSimple) ...[
                      const SizedBox(height: 5),
                      Semantics(
                        label: 'Session libre',
                        child: Tooltip(
                          message: 'Session libre',
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                simpleSessionIcon,
                                size: 16,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                key: const Key('sessionCardContent'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        SessionChip(
                          text: (session['weapon'] ?? '').toString(),
                          icon: Icons.security,
                          color: identityColor,
                        ),
                        SessionChip(
                          text: (session['caliber'] ?? '').toString(),
                          icon: Icons.bolt,
                          color: identityColor,
                        ),
                        if ((session['category'] ?? '').toString().isNotEmpty)
                          SessionChip(
                            text: SessionConstants.categoryLabel(
                              session['category'].toString(),
                            ),
                            icon: Icons.category,
                            color: isPlanned
                                ? Colors.blueAccent
                                : colors.secondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isSimple) ...[
                          _MetricBadge(
                            label: 'Tirs',
                            value: '${session['shotCount'] ?? 0}',
                            icon: Icons.adjust,
                            color: colors.secondary,
                          ),
                          _MetricBadge(
                            label: 'Distance',
                            value: '${_distanceLabel(session['distance'])} m',
                            icon: Icons.social_distance,
                            color: colors.secondary,
                          ),
                        ] else if (isPlanned)
                          _MetricBadge(
                            label: 'Séries prévues',
                            value: '${series.length}',
                            icon: Icons.list_alt,
                            color: Colors.blueAccent,
                          )
                        else ...[
                          _MetricBadge(
                            label: 'Score',
                            value: avgScore.toStringAsFixed(1),
                            icon: Icons.score,
                            color: colors.primary,
                          ),
                          _MetricBadge(
                            label: 'Groupement',
                            value: '${avgGroup.toStringAsFixed(1)} cm',
                            icon: Icons.adjust,
                            color: colors.secondary,
                          ),
                          if (hasCoachAnalysis)
                            Semantics(
                              label: 'Analyse Coach disponible',
                              child: Tooltip(
                                message: 'Analyse Coach disponible',
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.analytics,
                                    size: 20,
                                    color: colors.secondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                    if (exerciseIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fitness_center, size: 14, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            '${exerciseIds.length} exercice(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isPlanned
                                  ? Colors.blueAccent.withValues(alpha: 0.8)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  tooltip: 'Supprimer la session',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _distanceLabel(dynamic value) {
    if (value is! num) return '-';
    final number = value.toDouble();
    return number == number.truncateToDouble()
        ? number.toInt().toString()
        : number.toString();
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.42), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text('$label ',
              style: TextStyle(fontSize: 11, color: colors.onSurface)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
