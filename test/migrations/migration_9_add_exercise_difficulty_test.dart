import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_9_add_exercise_difficulty.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt025_migration_');
    Hive.init(directory.path);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('ajoute difficulty sans modifier les exercices historiques', () async {
    final box = await Hive.openBox('exercises');
    await box.put('e1', {'id': 'e1', 'name': 'Historique'});

    await Migration9AddExerciseDifficulty().apply();

    expect(box.get('e1')['difficulty'], isNull);
    expect(box.get('e1')['name'], 'Historique');
    expect(Migration9AddExerciseDifficulty().toVersion, 9);
  });
}
