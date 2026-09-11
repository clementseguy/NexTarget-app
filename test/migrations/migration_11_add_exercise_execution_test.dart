import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_11_add_exercise_execution.dart';

void main() {
  group('Migration11AddExerciseExecution', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration11_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('ajoute une qualification vide aux sessions avec exercice', () async {
      final box = await Hive.openBox('sessions');
      await box.put(1, {
        'session': {
          'id': 1,
          'exerciseId': 'exercise-1',
          'weapon': 'Pistolet',
        },
        'series': [
          {'points': 42},
        ],
      });

      final migration = Migration11AddExerciseExecution();
      expect(migration.toVersion, 11);
      await migration.apply();

      final envelope = Map<String, dynamic>.from(box.get(1));
      final session = Map<String, dynamic>.from(envelope['session'] as Map);
      expect(session.containsKey('exerciseExecution'), isTrue);
      expect(session['exerciseExecution'], isNull);
      expect(session['weapon'], 'Pistolet');
      expect((envelope['series'] as List).single['points'], 42);
    });

    test('préserve les sessions sans exercice et la qualification existante',
        () async {
      final box = await Hive.openBox('sessions');
      await box.putAll({
        1: {
          'session': {'id': 1, 'exerciseId': null},
          'series': [],
        },
        2: {
          'session': {
            'id': 2,
            'exerciseId': 'exercise-2',
            'exerciseExecution': {
              'performed': false,
              'protocolFollowed': 'no',
              'comment': 'Arrêt anticipé',
            },
          },
          'series': [],
        },
      });

      await Migration11AddExerciseExecution().apply();

      final withoutExercise = Map<String, dynamic>.from(
        (Map<dynamic, dynamic>.from(box.get(1)))['session'] as Map,
      );
      final qualified = Map<String, dynamic>.from(
        (Map<dynamic, dynamic>.from(box.get(2)))['session'] as Map,
      );
      expect(withoutExercise.containsKey('exerciseExecution'), isFalse);
      expect(qualified['exerciseExecution'], {
        'performed': false,
        'protocolFollowed': 'no',
        'comment': 'Arrêt anticipé',
      });
    });

    test('ignore une entrée Hive mal formée', () async {
      final box = await Hive.openBox('sessions');
      await box.put('invalid', 'valeur historique inconnue');

      await Migration11AddExerciseExecution().apply();

      expect(box.get('invalid'), 'valeur historique inconnue');
    });
  });
}
