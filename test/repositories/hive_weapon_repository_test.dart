import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    await Hive.close();
    tempDir = await Directory.systemTemp.createTemp('nt_repo_weapon_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('put/getAll conserve les armes ajoutées', () async {
    final repo = HiveWeaponRepository(boxName: 'weapons_test_1');
    await repo.put(Weapon(id: 'a', name: 'Glock 17', createdAt: DateTime(2026, 1, 1)));
    await repo.put(Weapon(id: 'b', name: 'CZ 75', createdAt: DateTime(2026, 1, 2)));

    final all = await repo.getAll();
    expect(all.map((w) => w.id).toSet(), {'a', 'b'});
  });

  test('put avec un id existant remplace l\'entrée (rename)', () async {
    final repo = HiveWeaponRepository(boxName: 'weapons_test_2');
    await repo.put(Weapon(id: 'a', name: 'Glock 17', createdAt: DateTime(2026, 1, 1)));
    await repo.put(Weapon(id: 'a', name: 'Glock 19', createdAt: DateTime(2026, 1, 1)));

    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Glock 19');
  });

  test('delete retire l\'arme du râtelier', () async {
    final repo = HiveWeaponRepository(boxName: 'weapons_test_3');
    await repo.put(Weapon(id: 'a', name: 'Glock 17', createdAt: DateTime(2026, 1, 1)));
    await repo.delete('a');

    expect(await repo.getAll(), isEmpty);
  });

  test('clear vide tout le râtelier', () async {
    final repo = HiveWeaponRepository(boxName: 'weapons_test_4');
    await repo.put(Weapon(id: 'a', name: 'Glock 17', createdAt: DateTime(2026, 1, 1)));
    await repo.put(Weapon(id: 'b', name: 'CZ 75', createdAt: DateTime(2026, 1, 2)));
    await repo.clear();

    expect(await repo.getAll(), isEmpty);
  });
}
