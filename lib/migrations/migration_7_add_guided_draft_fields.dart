import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import 'migration.dart';

/// Migration additive NT-131 : rend explicite l'état des séries historiques.
///
/// Les séries antérieures à NT-131 sont toutes des séries enregistrées. Les
/// nouveaux marqueurs servent uniquement aux saisies partielles des brouillons.
class Migration7AddGuidedDraftFields extends HiveMigration {
  @override
  int get toVersion => 7;

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
        series.putIfAbsent('completed', () => true);
        series.putIfAbsent('draft_started', () => true);
        migratedSeries.add(series);
      }
      envelope['series'] = migratedSeries;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
