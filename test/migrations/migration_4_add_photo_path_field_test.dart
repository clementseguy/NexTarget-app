import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_4_add_photo_path_field.dart';

void main() {
  group('Migration4AddPhotoPathField', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nt_migration4_');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('toVersion is 4', () {
      expect(Migration4AddPhotoPathField().toVersion, 4);
    });

    test('is a no-op when the sessions box is not open', () async {
      // La box n'est volontairement pas ouverte ici.
      await Migration4AddPhotoPathField().apply();
      expect(Hive.isBoxOpen('sessions'), isFalse);
    });

    test('ajoute photoPath=null aux sessions existantes qui ne l\'ont pas', () async {
      final box = await Hive.openBox('sessions');
      await box.put(1, {
        'session': {'id': 1, 'weapon': 'P', 'caliber': '22LR'},
        'series': [],
      });

      await Migration4AddPhotoPathField().apply();

      final stored = Map<String, dynamic>.from(box.get(1));
      final session = Map<String, dynamic>.from(stored['session']);
      expect(session.containsKey('photoPath'), isTrue);
      expect(session['photoPath'], isNull);
    });

    test('conserve un photoPath déjà présent', () async {
      final box = await Hive.openBox('sessions');
      await box.put(1, {
        'session': {'id': 1, 'weapon': 'P', 'caliber': '22LR', 'photoPath': '/docs/session_photos/target_x.jpg'},
        'series': [],
      });

      await Migration4AddPhotoPathField().apply();

      final stored = Map<String, dynamic>.from(box.get(1));
      final session = Map<String, dynamic>.from(stored['session']);
      expect(session['photoPath'], '/docs/session_photos/target_x.jpg');
    });

    test('traite plusieurs sessions dans la box', () async {
      final box = await Hive.openBox('sessions');
      await box.put(1, {
        'session': {'id': 1, 'weapon': 'P', 'caliber': '22LR'},
        'series': [],
      });
      await box.put(2, {
        'session': {'id': 2, 'weapon': 'C', 'caliber': '9mm', 'photoPath': '/docs/session_photos/target_y.jpg'},
        'series': [],
      });

      await Migration4AddPhotoPathField().apply();

      final s1 = Map<String, dynamic>.from(Map<String, dynamic>.from(box.get(1))['session']);
      final s2 = Map<String, dynamic>.from(Map<String, dynamic>.from(box.get(2))['session']);
      expect(s1['photoPath'], isNull);
      expect(s2['photoPath'], '/docs/session_photos/target_y.jpg');
    });
  });
}
