import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_12_add_exercise_origin.dart';

void main() {
  group('Migration12AddExerciseOrigin', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration12_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('qualifie les exercices historiques comme personnels', () async {
      final box = await Hive.openBox('exercises');
      await box.put('legacy', {'id': 'legacy', 'name': 'Historique'});

      final migration = Migration12AddExerciseOrigin();
      expect(migration.toVersion, 12);
      await migration.apply();

      expect(box.get('legacy'), {
        'id': 'legacy',
        'name': 'Historique',
        'origin': 'personal',
      });
    });

    test('préserve une provenance existante et ignore les entrées invalides',
        () async {
      final box = await Hive.openBox('exercises');
      await box.putAll({
        'catalog': {
          'id': 'catalog',
          'name': 'Catalogue',
          'origin': 'coach_catalog',
        },
        'invalid': 'ancienne valeur inconnue',
      });

      await Migration12AddExerciseOrigin().apply();

      expect(box.get('catalog')['origin'], 'coach_catalog');
      expect(box.get('invalid'), 'ancienne valeur inconnue');
    });
  });
}
