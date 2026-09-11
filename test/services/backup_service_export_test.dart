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

    test('écrit un export version 6 dans le répertoire temporaire injecté',
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
      expect(data['version'], 6);
      expect(data['sessions_count'], 1);
      expect(data['goals_count'], 1);
      expect(data['weapons_count'], 1);
      expect(data['exercises_count'], 1);
      final session = (data['sessions'] as List).single as Map<String, dynamic>;
      expect(session['exerciseId'], 'exercise-export');
      expect(session.containsKey('exercises'), isFalse);
      expect((data['exercises'] as List).single['difficulty'], 'expert');
      expect((data['exercises'] as List).single['origin'], 'coach_catalog');
    });

    test('conserve difficulté et provenance au cycle export/import', () async {
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
      expect(
        (await fixture.exerciseRepository.getAll()).single.origin,
        ExerciseOrigin.coachCatalog,
      );

      await fixture.exerciseRepository.clear();
      (data['exercises'] as List).single['difficulty'] = 'impossible';
      await fixture.service.importSessionsFromJson(jsonEncode(data));
      expect(
        (await fixture.exerciseRepository.getAll()).single.difficulty,
        isNull,
      );
    });

    test('importe un exercice historique sans provenance comme personnel',
        () async {
      final fixture = await BackupServiceTestFixture.create(tempDirectory);
      final file = await fixture.service.exportAllSessionsToJsonFile();
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      (data['exercises'] as List).single.remove('origin');

      await fixture.exerciseRepository.clear();
      await fixture.service.importSessionsFromJson(jsonEncode(data));

      expect(
        (await fixture.exerciseRepository.getAll()).single.origin,
        ExerciseOrigin.personal,
      );
    });
  });
}
