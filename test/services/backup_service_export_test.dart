import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';

import '../support/backup_service_test_fixture.dart';

void main() {
  group('BackupService exportAllSessionsToJsonFile', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'nt_backup_export_temp_test_',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('écrit un export version 3 dans le répertoire temporaire injecté',
        () async {
      final fixture = await BackupServiceTestFixture.create(tempDirectory);

      final file = await fixture.service.exportAllSessionsToJsonFile();

      expect(file.parent.path, tempDirectory.path);
      expect(file.path, endsWith('.json'));
      expect(file.uri.pathSegments.last, startsWith('nextarget_export_'));
      expect(await file.exists(), isTrue);
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(data['format'], 'mycoach-data');
      expect(data['version'], 3);
      expect(data['sessions_count'], 1);
      expect(data['goals_count'], 1);
      expect(data['weapons_count'], 1);
      expect(data['exercises_count'], 1);
      expect((data['exercises'] as List).single['difficulty'], 'expert');
    });

    test('conserve la difficulté au cycle export/import et ignore une inconnue',
        () async {
      final fixture = await BackupServiceTestFixture.create(tempDirectory);
      final file = await fixture.service.exportAllSessionsToJsonFile();
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      await fixture.exerciseRepository.clear();
      await fixture.service.importSessionsFromJson(jsonEncode(data));
      expect(
        (await fixture.exerciseRepository.getAll()).single.difficulty,
        ExerciseDifficulty.expert,
      );

      await fixture.exerciseRepository.clear();
      (data['exercises'] as List).single['difficulty'] = 'impossible';
      await fixture.service.importSessionsFromJson(jsonEncode(data));
      expect(
        (await fixture.exerciseRepository.getAll()).single.difficulty,
        isNull,
      );
    });
  });
}
