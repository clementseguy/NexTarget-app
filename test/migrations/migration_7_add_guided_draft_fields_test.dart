import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_7_add_guided_draft_fields.dart';

void main() {
  group('Migration7AddGuidedDraftFields', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration7_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('marque les séries historiques comme enregistrées', () async {
      final box = await Hive.openBox('sessions');
      await box.put(1, {
        'session': {'id': 1, 'status': 'réalisée'},
        'series': [
          {'shot_count': 5, 'distance': 25, 'points': 45, 'group_size': 8},
        ],
      });

      final migration = Migration7AddGuidedDraftFields();
      expect(migration.toVersion, 7);
      await migration.apply();

      final envelope = Map<String, dynamic>.from(box.get(1));
      final series = Map<String, dynamic>.from(
        (envelope['series'] as List).single as Map,
      );
      expect(series['completed'], isTrue);
      expect(series['draft_started'], isTrue);
    });

    test('préserve les marqueurs déjà présents', () async {
      final box = await Hive.openBox('sessions');
      await box.put(2, {
        'session': {'id': 2, 'status': 'brouillon'},
        'series': [
          {
            'shot_count': 5,
            'distance': 25,
            'points': 0,
            'group_size': 0,
            'completed': false,
            'draft_started': false,
          },
        ],
      });

      await Migration7AddGuidedDraftFields().apply();

      final envelope = Map<String, dynamic>.from(box.get(2));
      final series = Map<String, dynamic>.from(
        (envelope['series'] as List).single as Map,
      );
      expect(series['completed'], isFalse);
      expect(series['draft_started'], isFalse);
    });
  });
}
