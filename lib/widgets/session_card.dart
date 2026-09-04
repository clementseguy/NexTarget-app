import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  final List<dynamic> series;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const SessionCard({required this.session, required this.series, this.onTap, this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(session['date'] ?? '') ?? DateTime.now();
    final bool isPlanned = (session['status'] == 'prévue');
    int totalPoints = 0;
    double avgScore = 0;
    double avgGroup = 0;
    final List<dynamic> exerciseIds = (session['exercises'] is List) ? (session['exercises'] as List) : const [];
    if (series.isNotEmpty) {
      totalPoints = series.fold(0, (sum, s) => sum + ((s['points'] ?? 0) as int));
      avgScore = totalPoints / series.length;
      avgGroup = series.map((s) => (s['group_size'] ?? 0.0) as num).fold(0.0, (a, b) => a + b) / series.length;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final Color accent = isPlanned ? Colors.blueAccent : colorScheme.primary;
    final Color badgeColor = isPlanned ? Colors.blueAccent : Colors.green;
    final Color titleColor = isPlanned ? colorScheme.primary : Theme.of(context).textTheme.titleMedium?.color ?? colorScheme.onSurface;
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isPlanned ? Colors.blueAccent.withValues(alpha: 0.4) : colorScheme.primary.withValues(alpha: 0.3), width: 0.8),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, color: accent),
            Text('${date.day}/${date.month}', style: TextStyle(fontSize: 12)),
          ],
        ),
        title: Text(
          '${session['weapon']} [${session['caliber']}] - ${session['category'] ?? ''} - # Séries : ${series.length}${isPlanned ? ' (prévue)' : ''}',
          style: TextStyle(color: titleColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score moyen : ${avgScore.toStringAsFixed(1)}', style: TextStyle(color: isPlanned ? colorScheme.primary.withValues(alpha: 0.8) : null)),
            Text('Groupement moyen : ${avgGroup.toStringAsFixed(1)} cm', style: TextStyle(color: isPlanned ? colorScheme.primary.withValues(alpha: 0.8) : null)),
            if (exerciseIds.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.fitness_center, size: 14, color: badgeColor),
                  SizedBox(width: 4),
                  Text('${exerciseIds.length} exercice(s)', style: TextStyle(fontSize: 12, color: isPlanned ? colorScheme.primary.withValues(alpha: 0.8) : null)),
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
}
