import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import 'migration.dart';

/// Migration additive NT-131 : distingue un score nul saisi d'un score absent.
class Migration8AddScoreEnteredField extends HiveMigration {
  @override
  int get toVersion => 8;

  @override
  Future<void> apply() async {
    final box = Hive.isBoxOpen(SessionConstants.hiveBoxSessions)
        ? Hive.box(SessionConstants.hiveBoxSessions)
        : await Hive.openBox(SessionConstants.hiveBoxSessions);
    final updates = <dynamic, dynamic>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map || raw['series'] is! List) continue;
      final envelope = Map<String, dynamic>.from(raw);
      final migratedSeries = <dynamic>[];
      for (final item in raw['series'] as List) {
        if (item is! Map) {
          migratedSeries.add(item);
          continue;
        }
        final series = Map<String, dynamic>.from(item);
        series.putIfAbsent(
          'score_entered',
          () =>
              (series['completed'] as bool? ?? true) ||
              ((series['points'] as num?)?.toInt() ?? 0) != 0,
        );
        migratedSeries.add(series);
      }
      envelope['series'] = migratedSeries;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
