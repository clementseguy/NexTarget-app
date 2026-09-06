import 'package:hive/hive.dart';

import 'migration.dart';

/// Migration additive NT-025 : rend explicite l'absence de difficulté.
class Migration9AddExerciseDifficulty extends HiveMigration {
  @override
  int get toVersion => 9;

  @override
  Future<void> apply() async {
    final box = await Hive.openBox('exercises');
    for (final key in box.keys.toList()) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final exercise = Map<String, dynamic>.from(raw);
      exercise.putIfAbsent('difficulty', () => null);
      await box.put(key, exercise);
    }
  }
}
