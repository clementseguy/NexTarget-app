import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_5_create_weapons_box.dart';

void main() {
  group('Migration5CreateWeaponsBox', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nt_migration5_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      if (Hive.isBoxOpen('weapons')) await Hive.box('weapons').close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('toVersion is 5', () {
      expect(Migration5CreateWeaponsBox().toVersion, 5);
    });

    test('ouvre la box weapons si elle n\'est pas déjà ouverte', () async {
      expect(Hive.isBoxOpen('weapons'), isFalse);
      await Migration5CreateWeaponsBox().apply();
      expect(Hive.isBoxOpen('weapons'), isTrue);
    });

    test('est un no-op si la box weapons est déjà ouverte', () async {
      final box = await Hive.openBox('weapons');
      await box.put('a', {'id': 'a', 'name': 'Glock 17', 'createdAt': DateTime(2026, 1, 1).toIso8601String()});

      await Migration5CreateWeaponsBox().apply();

      expect(Hive.isBoxOpen('weapons'), isTrue);
      expect(box.get('a'), isNotNull);
    });
  });
}
