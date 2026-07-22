import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/session_template_service.dart';

void main() {
  late Directory tempDir;
  late SessionTemplateService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppConfig.load();
    tempDir = Directory.systemTemp.createTempSync('nextarget_templates_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_preferences');
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
    service = SessionTemplateService();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('recordLastSetup stores a canonical setup outside sessions', () async {
    final session = ShootingSession(
      weapon: 'Pistolet Unique DES',
      caliber: '22lr',
      category: SessionConstants.categoryEntrainement,
      status: SessionConstants.statusRealisee,
      disciplineCode: '830',
      disciplineSeason: '2025-2026',
      series: [Series(distance: 25, points: 92, groupSize: 0)],
    );

    await service.recordLastSetup(session);

    final setup = service.getLastSetup();
    expect(setup, isNotNull);
    expect(setup!.weapon, 'Pistolet Unique DES');
    expect(setup.caliber, '.22 LR');
    expect(setup.disciplineCode, '830');
    expect(setup.disciplineSeason, '2025-2026');
  });

  test('favorites are named, canonicalized, and newest first', () async {
    final first = ShootingSession(
      weapon: 'Pistolet 9',
      caliber: '9 x 19 mm',
      category: SessionConstants.categoryMatch,
      series: const [],
    );
    final second = ShootingSession(
      weapon: 'Pistolet 22',
      caliber: '22lr',
      category: SessionConstants.categoryEntrainement,
      series: const [],
    );

    await service.saveFavoriteFromSession(first, name: 'Match 9');
    await service.saveFavoriteFromSession(second, name: 'Precision 22');

    final favorites = service.getFavorites();
    expect(favorites, hasLength(2));
    expect(favorites.first.name, 'Precision 22');
    expect(favorites.first.caliber, '.22 LR');
    expect(favorites.last.name, 'Match 9');
    expect(favorites.last.caliber, '9mm (9x19)');
  });

  test('template initial data keeps status and optional discipline fields',
      () async {
    final session = ShootingSession(
      weapon: 'Pistolet TAR',
      caliber: '22lr',
      category: SessionConstants.categoryEntrainement,
      disciplineCode: '831',
      disciplineSeason: '2025-2026',
      series: const [],
    );

    await service.recordLastSetup(session);
    final data = service
        .getLastSetup()!
        .toInitialSessionData(status: SessionConstants.statusPrevue);
    final sessionData = data['session'] as Map<String, dynamic>;

    expect(sessionData['status'], SessionConstants.statusPrevue);
    expect(sessionData['weapon'], 'Pistolet TAR');
    expect(sessionData['caliber'], '.22 LR');
    expect(sessionData['discipline_code'], '831');
    expect(sessionData['discipline_season'], '2025-2026');
    expect(data['series'], isEmpty);
  });
}
