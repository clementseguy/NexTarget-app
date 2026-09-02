import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'async_test_helpers.dart';
import 'fake_session_repository.dart';

ShootingSession _session({int? id, required String weapon}) => ShootingSession(
      id: id,
      weapon: weapon,
      caliber: '9mm',
      series: const [],
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

    test('update persiste normalement quand aucune panne n\'est configurée', () async {
      final repo = FakeSessionRepository();
      await repo.insert(_session(weapon: 'Glock 17'));
      final toUpdate = (await repo.getAll()).single..weapon = 'Glock 19';

      await repo.update(toUpdate);

      expect((await repo.getAll()).single.weapon, 'Glock 19');
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
