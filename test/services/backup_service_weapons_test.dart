import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/weapon_service.dart';

void main() {
  group('BackupService import/export - râtelier (NT-008)', () {
    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('nt_backup_weapons_test_');
      Hive.init(dir.path);
      await Hive.openBox('sessions');
      await Hive.openBox('exercises');
      await Hive.openBox('weapons');
    });

    tearDown(() async {
      for (final name in ['sessions', 'exercises', 'weapons']) {
        if (Hive.isBoxOpen(name)) await Hive.box(name).close();
      }
    });

    test('importSessionsFromJson importe les armes du râtelier exporté', () async {
      final svc = BackupService();
      final payload = {
        'format': 'mycoach-data',
        'version': 3,
        'sessions': <Map<String, dynamic>>[],
        'weapons': [
          {'id': 'w1', 'name': 'CZ 75 SP-01 Shadow', 'createdAt': DateTime(2026, 1, 1).toIso8601String()},
          {'id': 'w2', 'name': 'Glock 17', 'createdAt': DateTime(2026, 1, 1).toIso8601String()},
        ],
      };
      await svc.importSessionsFromJson(const JsonEncoder().convert(payload));

      final rack = await WeaponService().listAll();
      expect(rack.map((w) => w.name).toSet(), {'CZ 75 SP-01 Shadow', 'Glock 17'});
    });

    test('importSessionsFromJson fusionne sans effacer le râtelier local existant', () async {
      final weaponService = WeaponService();
      await weaponService.addWeapon('Revolver 357'); // déjà présent localement

      final svc = BackupService();
      final payload = {
        'format': 'mycoach-data',
        'version': 3,
        'sessions': <Map<String, dynamic>>[],
        'weapons': [
          {'id': 'w1', 'name': 'Glock 17', 'createdAt': DateTime(2026, 1, 1).toIso8601String()},
        ],
      };
      await svc.importSessionsFromJson(const JsonEncoder().convert(payload));

      final rack = await weaponService.listAll();
      expect(rack.map((w) => w.name).toSet(), {'Revolver 357', 'Glock 17'});
    });

    test('importSessionsFromJson ignore silencieusement un doublon normalisé', () async {
      final weaponService = WeaponService();
      await weaponService.addWeapon('Glock 17');

      final svc = BackupService();
      final payload = {
        'format': 'mycoach-data',
        'version': 3,
        'sessions': <Map<String, dynamic>>[],
        'weapons': [
          {'id': 'w-import', 'name': '  glock 17  ', 'createdAt': DateTime(2026, 1, 1).toIso8601String()},
        ],
      };
      await svc.importSessionsFromJson(const JsonEncoder().convert(payload));

      final rack = await weaponService.listAll();
      expect(rack.length, 1); // pas de doublon créé
    });

    test('importSessionsFromJson reste compatible avec un ancien export sans râtelier', () async {
      final weaponService = WeaponService();
      await weaponService.addWeapon('Revolver 357'); // râtelier local préexistant

      final svc = BackupService();
      final payload = {
        'format': 'mycoach-data',
        'version': 2,
        'sessions': <Map<String, dynamic>>[],
        // pas de clé 'weapons' (ancien format)
      };
      final imported = await svc.importSessionsFromJson(const JsonEncoder().convert(payload));

      expect(imported, 0);
      final rack = await weaponService.listAll();
      expect(rack.map((w) => w.name).toSet(), {'Revolver 357'}); // râtelier local intact
    });
  });
}
