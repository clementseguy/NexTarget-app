import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_10_single_session_exercise.dart';

void main() {
  group('Migration10SingleSessionExercise', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration10_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
      await directory.delete(recursive: true);
    });

    test('conserve le premier exercice historique et les autres données',
        () async {
      final box = await Hive.openBox('sessions');
      await box.put(7, {
        'session': {
          'id': 7,
          'weapon': 'Pistolet',
          'exercises': ['premier', 'second'],
        },
        'series': [
          {'points': 42},
        ],
      });
      await box.close();

      final migration = Migration10SingleSessionExercise();
      expect(migration.toVersion, 10);
      await migration.apply();

      final envelope = Map<String, dynamic>.from(Hive.box('sessions').get(7));
      final session = Map<String, dynamic>.from(envelope['session']);
      expect(session['exerciseId'], 'premier');
      expect(session.containsKey('exercises'), isFalse);
      expect(session['weapon'], 'Pistolet');
      expect((envelope['series'] as List).single['points'], 42);
    });

    test('préserve une session sans exercice et une valeur déjà migrée',
        () async {
      final box = await Hive.openBox('sessions');
      await box.putAll({
        1: {
          'session': {'id': 1, 'exercises': <String>[]},
          'series': [],
        },
        2: {
          'session': {
            'id': 2,
            'exerciseId': 'actuel',
            'exercises': ['ancien'],
          },
          'series': [],
        },
      });

      await Migration10SingleSessionExercise().apply();

      final firstEnvelope = Map<dynamic, dynamic>.from(box.get(1));
      final secondEnvelope = Map<dynamic, dynamic>.from(box.get(2));
      final first = Map<String, dynamic>.from(firstEnvelope['session'] as Map);
      final second =
          Map<String, dynamic>.from(secondEnvelope['session'] as Map);
      expect(first['exerciseId'], isNull);
      expect(second['exerciseId'], 'actuel');
    });

    test('ignore une entrée Hive mal formée sans la supprimer', () async {
      final box = await Hive.openBox('sessions');
      await box.put('invalid', 'valeur historique inconnue');

      await Migration10SingleSessionExercise().apply();

      expect(box.get('invalid'), 'valeur historique inconnue');
    });
  });
}
