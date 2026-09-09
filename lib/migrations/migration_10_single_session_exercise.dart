import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import 'migration.dart';

/// Migration NT-152 : remplace la liste d'exercices par l'exercice principal.
class Migration10SingleSessionExercise extends HiveMigration {
  @override
  int get toVersion => 10;

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
      if (!session.containsKey('exerciseId')) {
        session['exerciseId'] = _firstExerciseId(session['exercises']);
      }
      session.remove('exercises');
      envelope['session'] = session;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }

  String? _firstExerciseId(dynamic exercises) {
    if (exercises is! List) return null;
    for (final value in exercises) {
      if (value is String) return value;
    }
    return null;
  }
}
