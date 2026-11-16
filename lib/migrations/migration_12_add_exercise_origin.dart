import 'package:hive/hive.dart';

import 'migration.dart';

/// Migration NT-159 : qualifie les exercices historiques comme personnels.
class Migration12AddExerciseOrigin extends HiveMigration {
  @override
  int get toVersion => 12;

  @override
  Future<void> apply() async {
    final box = Hive.isBoxOpen('exercises')
        ? Hive.box('exercises')
        : await Hive.openBox('exercises');
    final updates = <dynamic, dynamic>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map || raw.containsKey('origin')) continue;
      final exercise = Map<String, dynamic>.from(raw);
      exercise['origin'] = 'personal';
      updates[key] = exercise;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
