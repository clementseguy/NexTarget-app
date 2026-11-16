import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import 'migration.dart';

/// Migration NT-154 : réserve la qualification des sessions avec exercice.
class Migration11AddExerciseExecution extends HiveMigration {
  @override
  int get toVersion => 11;

  @override
  Future<void> apply() async {
    final box = Hive.isBoxOpen(SessionConstants.hiveBoxSessions)
        ? Hive.box(SessionConstants.hiveBoxSessions)
        : await Hive.openBox(SessionConstants.hiveBoxSessions);
    final updates = <dynamic, dynamic>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map || raw['session'] is! Map) continue;
      final session = Map<String, dynamic>.from(raw['session'] as Map);
      final exerciseId = session['exerciseId'];
      if (exerciseId is! String || exerciseId.trim().isEmpty) continue;
      if (session.containsKey('exerciseExecution')) continue;
      final envelope = Map<String, dynamic>.from(raw);
      session['exerciseExecution'] = null;
      envelope['session'] = session;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
