import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/hive_session_repository.dart';

void main() {
  setUp(() async {
    final dir = await Directory.systemTemp.createTemp('nt_repo_hive_');
    Hive.init(dir.path);
    await Hive.openBox('sessions');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
  });

  test('insert returns an id and getAll returns stored session', () async {
    final repo = HiveSessionRepository();
    final sess = DetailedShootingSession(
      weapon: 'P',
      caliber: '22LR',
      status: 'réalisée',
      date: DateTime.now(),
      series: [Series(distance: 10, points: 50, groupSize: 20, shotCount: 5)],
    );
    final id = await repo.insert(sess);
    expect(id, isNonNegative);
    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.first.series.first.points, 50);
  });

  test('persiste une session libre sans série', () async {
    final repo = HiveSessionRepository();
    final session = SimpleShootingSession(
      date: DateTime(2026, 9, 1),
      weapon: 'Pistolet',
      caliber: '9mm',
      shotCount: 25,
      distance: 15,
      exercises: const ['e1'],
    );

    final id = await repo.insert(session);
    final stored = (await repo.getAll()).single;

    expect(id, isNonNegative);
    expect(stored, isA<SimpleShootingSession>());
    expect((stored as SimpleShootingSession).shotCount, 25);
    expect(stored.series, isEmpty);
  });

  test('update with preserveExistingSeriesIfEmpty keeps prior series',
      () async {
    final repo = HiveSessionRepository();
    final sess = DetailedShootingSession(
      weapon: 'P',
      caliber: '22LR',
      status: 'réalisée',
      date: DateTime.now(),
      series: [Series(distance: 10, points: 40, groupSize: 22, shotCount: 5)],
    );
    final id = await repo.insert(sess);

    // Update with empty series but preserveExistingSeriesIfEmpty=true
    final updated = DetailedShootingSession(
      id: id,
      weapon: 'P',
      caliber: '22LR',
      status: 'réalisée',
      date: sess.date,
      series: const [],
    );
    final usedFallback =
        await repo.update(updated, preserveExistingSeriesIfEmpty: true);
    expect(usedFallback, isTrue);
    final all = await repo.getAll();
    expect(all.first.series, isNotEmpty);
  });

  test('delete and clearAll remove items', () async {
    final repo = HiveSessionRepository();
    final sess = DetailedShootingSession(
      weapon: 'P',
      caliber: '22LR',
      status: 'réalisée',
      date: DateTime.now(),
      series: [Series(distance: 10, points: 40, groupSize: 22, shotCount: 5)],
    );
    final id = await repo.insert(sess);
    await repo.delete(id);
    var all = await repo.getAll();
    expect(all, isEmpty);

    await repo.insert(sess);
    await repo.clearAll();
    all = await repo.getAll();
    expect(all, isEmpty);
  });

  test(
      'update throws when the underlying Hive write fails (au lieu de renvoyer false silencieusement)',
      () async {
    final repo = HiveSessionRepository();
    final sess = DetailedShootingSession(
      weapon: 'P',
      caliber: '22LR',
      status: 'réalisée',
      date: DateTime.now(),
      series: [Series(distance: 10, points: 40, groupSize: 22, shotCount: 5)],
    );
    final id = await repo.insert(sess);
    await Hive.box('sessions').close(); // force l'échec du prochain accès Hive

    final updated = DetailedShootingSession(
        id: id,
        weapon: 'P',
        caliber: '22LR',
        status: 'réalisée',
        series: sess.series);
    await expectLater(
      repo.update(updated, preserveExistingSeriesIfEmpty: false),
      throwsA(isA<StateError>()),
    );

    await Hive.openBox('sessions'); // réouverture pour un tearDown propre
  });
}
