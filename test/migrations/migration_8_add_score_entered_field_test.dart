import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_8_add_score_entered_field.dart';

void main() {
  group('Migration8AddScoreEnteredField', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration8_');
      Hive.init(directory.path);
      await Hive.openBox('sessions');
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('marque les scores historiques et préserve un brouillon non saisi',
        () async {
      final box = Hive.box('sessions');
      await box.put(1, {
        'session': {'id': 1, 'status': 'réalisée'},
        'series': [
          {'points': 0, 'completed': true},
          {'points': 42, 'completed': false},
          {'points': 0, 'completed': false},
        ],
      });

      final migration = Migration8AddScoreEnteredField();
      expect(migration.toVersion, 8);
      await migration.apply();

      final series = (box.get(1) as Map)['series'] as List;
      expect((series[0] as Map)['score_entered'], isTrue);
      expect((series[1] as Map)['score_entered'], isTrue);
      expect((series[2] as Map)['score_entered'], isFalse);
    });

    test('ne réécrit pas un marqueur existant', () async {
      final box = Hive.box('sessions');
      await box.put(1, {
        'series': [
          {'points': 0, 'completed': false, 'score_entered': true},
        ],
      });

      await Migration8AddScoreEnteredField().apply();

      final series = (box.get(1) as Map)['series'] as List;
      expect((series.single as Map)['score_entered'], isTrue);
    });
  });
}
