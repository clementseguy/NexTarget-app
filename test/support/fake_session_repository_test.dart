import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'async_test_helpers.dart';
import 'fake_session_repository.dart';

ShootingSession _session({int? id, required String weapon, List<Series> series = const []}) =>
    ShootingSession(
      id: id,
      weapon: weapon,
      caliber: '9mm',
      series: series,
    );

void main() {
  group('FakeSessionRepository', () {
    test('getAll clone les sessions : muter le résultat ne modifie pas l\'état interne', () async {
      final repo = FakeSessionRepository();
      await repo.insert(_session(weapon: 'Glock 17'));

      final result = await repo.getAll();
      result.single.weapon = 'Glock 19'; // mutation locale, ne doit rien persister

      final again = await repo.getAll();
      expect(again.single.weapon, 'Glock 17');
    });

    test('insert clone la session : muter l\'objet appelant après coup ne modifie pas l\'état stocké', () async {
      final repo = FakeSessionRepository();
      final session = _session(weapon: 'Glock 17');

      await repo.insert(session);
      session.weapon = 'Glock 19'; // mutation de l'objet appelant, sans update()

      expect((await repo.getAll()).single.weapon, 'Glock 17');
    });

    test('insert n\'attribue jamais un id déjà utilisé, même après suppression', () async {
      final repo = FakeSessionRepository();
      await repo.insert(_session(weapon: 'A')); // id 1
      await repo.insert(_session(weapon: 'B')); // id 2
      await repo.insert(_session(weapon: 'C')); // id 3
      await repo.delete(2);

      final newId = await repo.insert(_session(weapon: 'D'));

      expect(newId, 4); // jamais 3 (déjà utilisé), comme les clés Hive auto-incrémentées
      final all = await repo.getAll();
      expect(all.map((s) => s.id).toSet(), {1, 3, 4});
    });

    test('update persiste normalement quand aucune panne n\'est configurée', () async {
      final repo = FakeSessionRepository();
      await repo.insert(_session(weapon: 'Glock 17'));
      final toUpdate = (await repo.getAll()).single..weapon = 'Glock 19';

      await repo.update(toUpdate);

      expect((await repo.getAll()).single.weapon, 'Glock 19');
    });

    test('update avec series vide et preserveExistingSeriesIfEmpty=true conserve les series existantes (comme Hive)', () async {
      final repo = FakeSessionRepository();
      final existingSeries = [Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)];
      await repo.insert(_session(weapon: 'Glock 17', series: existingSeries));
      final toUpdate = (await repo.getAll()).single
        ..weapon = 'Glock 19'
        ..series = [];

      final fallbackApplied = await repo.update(toUpdate);

      expect(fallbackApplied, isTrue);
      final stored = (await repo.getAll()).single;
      expect(stored.weapon, 'Glock 19');
      expect(stored.series, hasLength(1)); // séries existantes conservées
    });

    test('update avec series vide et preserveExistingSeriesIfEmpty=false écrase quand même', () async {
      final repo = FakeSessionRepository();
      final existingSeries = [Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)];
      await repo.insert(_session(weapon: 'Glock 17', series: existingSeries));
      final toUpdate = (await repo.getAll()).single
        ..weapon = 'Glock 19'
        ..series = [];

      final fallbackApplied = await repo.update(toUpdate, preserveExistingSeriesIfEmpty: false);

      expect(fallbackApplied, isFalse);
      expect((await repo.getAll()).single.series, isEmpty);
    });

    test('update lève l\'erreur simulée au Nième appel sans persister', () async {
      final repo = FakeSessionRepository()..failOnUpdateCallNumber = 1;
      await repo.insert(_session(weapon: 'Glock 17'));
      final toUpdate = (await repo.getAll()).single..weapon = 'Glock 19';

      final error = await captureError(() => repo.update(toUpdate));

      expect(error, isA<StateError>());
      expect((await repo.getAll()).single.weapon, 'Glock 17'); // pas persisté
    });
  });
}

