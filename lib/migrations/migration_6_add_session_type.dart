import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import '../models/shooting_session.dart';
import 'migration.dart';

/// Migration additive NT-133 : identifie les sessions historiques comme
/// détaillées. La lecture conserve malgré tout son fallback sans discriminant.
class Migration6AddSessionType extends HiveMigration {
  @override
  int get toVersion => 6;

  @override
  Future<void> apply() async {
    final box = Hive.isBoxOpen(SessionConstants.hiveBoxSessions)
        ? Hive.box(SessionConstants.hiveBoxSessions)
        : await Hive.openBox(SessionConstants.hiveBoxSessions);
    final updates = <dynamic, dynamic>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map || raw['session'] is! Map) continue;
      final envelope = Map<String, dynamic>.from(raw);
      final session = Map<String, dynamic>.from(raw['session'] as Map);
      session.putIfAbsent(
        'sessionType',
        () => ShootingSession.detailedType,
      );
      envelope['session'] = session;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
