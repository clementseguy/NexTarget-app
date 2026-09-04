import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_6_add_session_type.dart';

void main() {
  group('Migration6AddSessionType', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration6_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
      await directory.delete(recursive: true);
    });

    test('ouvre la box et marque les sessions historiques détaillées',
        () async {
      final box = await Hive.openBox('sessions');
      await box.put(3, {
        'session': {'id': 3, 'weapon': 'P', 'caliber': '9mm'},
        'series': [],
      });
      await box.close();

      final migration = Migration6AddSessionType();
      expect(migration.toVersion, 6);
      await migration.apply();

      final migrated = Map<String, dynamic>.from(Hive.box('sessions').get(3));
      final session = Map<String, dynamic>.from(migrated['session']);
      expect(session['sessionType'], 'detailed');
    });

    test('préserve un discriminant existant', () async {
      final box = await Hive.openBox('sessions');
      await box.put(4, {
        'session': {'id': 4, 'sessionType': 'simple'},
        'series': [],
      });

      await Migration6AddSessionType().apply();

      final migrated = Map<String, dynamic>.from(box.get(4));
      expect(Map<String, dynamic>.from(migrated['session'])['sessionType'],
          'simple');
    });
  });
}
