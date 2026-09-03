import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/services/weapon_service.dart';

/// Repository en mémoire pour isoler WeaponService des tests.
class _MemWeaponRepo implements WeaponRepository {
  final List<Weapon> list = [];
  @override
  Future<void> clear() async => list.clear();
  @override
  Future<void> delete(String id) async => list.removeWhere((w) => w.id == id);
  @override
  Future<List<Weapon>> getAll() async => List.of(list);
  @override
  Future<void> put(Weapon weapon) async {
    list.removeWhere((w) => w.id == weapon.id);
    list.add(weapon);
  }
}

/// Repository de sessions en mémoire, avec possibilité de simuler un échec
/// d'écriture pour tester le rollback du renommage (NT-008).
class _MemSessionRepo implements SessionRepository {
  final List<ShootingSession> sessions = [];
  int updateCallCount = 0;
  int? failOnUpdateCallNumber; // 1-based : la Nième mise à jour échoue

  @override
  Future<void> clearAll() async => sessions.clear();
  @override
  Future<void> delete(int id) async => sessions.removeWhere((s) => s.id == id);
  @override
  // Clone (comme HiveSessionRepository, qui reconstruit toujours des objets
  // frais depuis les maps sérialisées) : muter un élément retourné par
  // getAll() ne doit jamais affecter l'état persistant tant que update()
  // n'a pas réussi.
  Future<List<ShootingSession>> getAll() async =>
      sessions.map((s) => ShootingSession.fromMap(s.toMap())).toList();
  @override
  Future<int> insert(ShootingSession session) async {
    final id = sessions.length + 1;
    session.id = id;
    sessions.add(session);
    return id;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    updateCallCount++;
    if (failOnUpdateCallNumber != null && updateCallCount == failOnUpdateCallNumber) {
      throw StateError('Échec simulé de mise à jour de session');
    }
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) sessions[idx] = session;
    return false;
  }
}

ShootingSession _session({required int id, required String weapon, String status = 'réalisée'}) {
  return DetailedShootingSession(
    id: id,
    weapon: weapon,
    caliber: '9mm',
    status: status,
    series: [Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)],
  );
}

/// Attend l'exécution de [action] et retourne l'exception levée, ou `null`
/// si aucune exception n'a été levée. Évite les `expect(() => ..., throwsA())`
/// non awaités sur des fonctions async, qui laissent un travail asynchrone en
/// suspens pouvant se résoudre pendant un test suivant.
Future<Object?> _captureError(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } catch (e) {
    return e;
  }
}

void main() {
  group('WeaponService.addWeapon', () {
    late WeaponService service;
    late _MemWeaponRepo weaponRepo;
    late _MemSessionRepo sessionRepo;

    setUp(() {
      weaponRepo = _MemWeaponRepo();
      sessionRepo = _MemSessionRepo();
      service = WeaponService(weaponRepository: weaponRepo, sessionRepository: sessionRepo);
    });

    test('ajoute une arme avec un nom trim', () async {
      final w = await service.addWeapon('  Glock 17  ');
      expect(w.name, 'Glock 17');
      expect((await service.listAll()).length, 1);
    });

    test('rejette un nom vide après trim', () async {
      final error = await _captureError(() => service.addWeapon('   '));
      expect(error, isA<WeaponValidationException>());
    });

    test('rejette un doublon normalisé (casse et espaces ignorés)', () async {
      await service.addWeapon('CZ 75');
      final error = await _captureError(() => service.addWeapon('  cz 75  '));
      expect(error, isA<WeaponValidationException>());
      expect((await service.listAll()).length, 1);
    });

    test('deux ajouts concurrents du même nom normalisé : un seul aboutit (pas de doublon)', () async {
      // Deux appels lancés sans attendre le premier (ex. double-tap) : sans
      // sérialisation, les deux lectures d'unicité pourraient chacune voir
      // "nom absent" avant qu'aucun des deux `put` n'ait eu lieu.
      final first = service.addWeapon('CZ 75');
      final second = service.addWeapon('cz 75'); // même nom normalisé

      Object? firstError;
      Object? secondError;
      try {
        await first;
      } catch (e) {
        firstError = e;
      }
      try {
        await second;
      } catch (e) {
        secondError = e;
      }

      final validationErrors = [firstError, secondError].whereType<WeaponValidationException>();
      expect(validationErrors, hasLength(1)); // exactement un des deux est rejeté
      expect((await service.listAll()).length, 1); // jamais deux armes de même nom
    });

    test('listAll trie par nom insensible à la casse', () async {
      await service.addWeapon('Zastava');
      await service.addWeapon('ares');
      await service.addWeapon('Beretta');
      final names = (await service.listAll()).map((w) => w.name).toList();
      expect(names, ['ares', 'Beretta', 'Zastava']);
    });
  });

  group('WeaponService.renameWeapon', () {
    late WeaponService service;
    late _MemWeaponRepo weaponRepo;
    late _MemSessionRepo sessionRepo;

    setUp(() {
      weaponRepo = _MemWeaponRepo();
      sessionRepo = _MemSessionRepo();
      service = WeaponService(weaponRepository: weaponRepo, sessionRepository: sessionRepo);
    });

    test('rejette un nouveau nom vide', () async {
      final w = await service.addWeapon('Glock 17');
      final error = await _captureError(() => service.renameWeapon(w, '   '));
      expect(error, isA<WeaponValidationException>());
    });

    test('rejette un nouveau nom en doublon avec une autre arme', () async {
      final w1 = await service.addWeapon('Glock 17');
      await service.addWeapon('CZ 75');
      final error = await _captureError(() => service.renameWeapon(w1, ' cz 75 '));
      expect(error, isA<WeaponValidationException>());
    });

    test('propage le renommage aux sessions dont le nom correspond exactement après normalisation', () async {
      final w = await service.addWeapon('CZ 75');
      await sessionRepo.insert(_session(id: 1, weapon: '  CZ 75  ')); // match normalisé
      await sessionRepo.insert(_session(id: 2, weapon: 'cz 75')); // match normalisé
      await sessionRepo.insert(_session(id: 3, weapon: 'CZ 09')); // ne matche pas
      await sessionRepo.insert(_session(id: 4, weapon: 'CZ 75', status: 'prévue')); // prévue aussi mise à jour

      await service.renameWeapon(w, 'CZ 75 SP-01 Shadow');

      final all = await sessionRepo.getAll();
      expect(all.firstWhere((s) => s.id == 1).weapon, 'CZ 75 SP-01 Shadow');
      expect(all.firstWhere((s) => s.id == 2).weapon, 'CZ 75 SP-01 Shadow');
      expect(all.firstWhere((s) => s.id == 3).weapon, 'CZ 09'); // saisie proche non modifiée
      expect(all.firstWhere((s) => s.id == 4).weapon, 'CZ 75 SP-01 Shadow');
      expect((await service.listAll()).single.name, 'CZ 75 SP-01 Shadow');
    });

    test('rollback complet si une mise à jour de session échoue en cours de propagation', () async {
      final w = await service.addWeapon('CZ 75');
      await sessionRepo.insert(_session(id: 1, weapon: 'CZ 75'));
      await sessionRepo.insert(_session(id: 2, weapon: 'CZ 75'));
      sessionRepo.failOnUpdateCallNumber = 2; // la 2e session échoue

      final error = await _captureError(() => service.renameWeapon(w, 'CZ 75 SP-01 Shadow'));
      expect(error, isA<StateError>());

      // Rollback : l'arme du râtelier et la session déjà modifiée reviennent à l'état initial.
      expect((await service.listAll()).single.name, 'CZ 75');
      final all = await sessionRepo.getAll();
      expect(all.firstWhere((s) => s.id == 1).weapon, 'CZ 75');
      expect(all.firstWhere((s) => s.id == 2).weapon, 'CZ 75');
    });
  });

  group('WeaponService.deleteWeapon', () {
    test('supprime l\'arme du râtelier sans modifier les sessions existantes', () async {
      final weaponRepo = _MemWeaponRepo();
      final sessionRepo = _MemSessionRepo();
      final service = WeaponService(weaponRepository: weaponRepo, sessionRepository: sessionRepo);

      final w = await service.addWeapon('Glock 17');
      await sessionRepo.insert(_session(id: 1, weapon: 'Glock 17'));

      await service.deleteWeapon(w.id);

      expect(await service.listAll(), isEmpty);
      final session = (await sessionRepo.getAll()).single;
      expect(session.weapon, 'Glock 17'); // inchangé
    });
  });
}
