import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<dynamic> series;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const SessionCard(
      {required this.session,
      required this.series,
      this.onTap,
      this.onDelete,
      super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    final bool isPlanned = (session['status'] == 'prévue');
    final bool isSimple = session['sessionType'] == 'simple';
    int totalPoints = 0;
    double avgScore = 0;
    double avgGroup = 0;
    final List<dynamic> exerciseIds = (session['exercises'] is List)
        ? (session['exercises'] as List)
        : const [];
    if (series.isNotEmpty) {
      totalPoints =
          series.fold(0, (sum, s) => sum + ((s['points'] ?? 0) as int));
      avgScore = totalPoints / series.length;
      avgGroup = series
              .map((s) => (s['group_size'] ?? 0.0) as num)
              .fold(0.0, (a, b) => a + b) /
          series.length;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final Color accent = isPlanned
        ? colorScheme.primary
        : isSimple
            ? colorScheme.secondary
            : colorScheme.primary;
    final Color badgeColor =
        isSimple ? colorScheme.secondary : colorScheme.primary;
    final Color titleColor = isPlanned
        ? colorScheme.primary
        : Theme.of(context).textTheme.titleMedium?.color ??
            colorScheme.onSurface;
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: accent.withValues(alpha: isSimple ? 0.65 : 0.3),
          width: isSimple ? 1.2 : 0.8,
        ),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: accent),
            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 12)),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSimple)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Chip(
                  avatar: Icon(Icons.playlist_add, size: 16, color: accent),
                  label: const Text('Libre'),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: accent.withValues(alpha: 0.6)),
                  backgroundColor: accent.withValues(alpha: 0.12),
                ),
              ),
            Text(
              '${session['weapon']} [${session['caliber']}] - ${session['category'] ?? ''}${isPlanned ? ' (prévue)' : ''}',
              style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSimple) ...[
              Text(
                  '${session['shotCount']} tirs à ${_distanceLabel(session['distance'])} m'),
            ] else ...[
              Text('# Séries : ${series.length}'),
              Text('Score moyen : ${avgScore.toStringAsFixed(1)}',
                  style: TextStyle(
                      color: isPlanned
                          ? colorScheme.primary.withValues(alpha: 0.8)
                          : null)),
              Text('Groupement moyen : ${avgGroup.toStringAsFixed(1)} cm',
                  style: TextStyle(
                      color: isPlanned
                          ? colorScheme.primary.withValues(alpha: 0.8)
                          : null)),
            ],
            if (exerciseIds.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 14, color: badgeColor),
                  SizedBox(width: 4),
                  Text('${exerciseIds.length} exercice(s)',
                      style: TextStyle(
                          fontSize: 12,
                          color: isPlanned
                              ? colorScheme.primary.withValues(alpha: 0.8)
                              : null)),
                ],
              ),
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
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
