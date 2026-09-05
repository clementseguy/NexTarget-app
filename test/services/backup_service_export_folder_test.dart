import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/backup_service_test_fixture.dart';

void main() {
  group('BackupService exportAllSessionsToUserFolder', () {
    late Directory tempDirectory;
    late Directory exportDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'nt_backup_export_folder_test_',
      );
      exportDirectory = await Directory(
        '${tempDirectory.path}/exports',
      ).create();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('écrit le fichier nommé dans le dossier choisi au format version 3',
        () async {
      final fixture = await BackupServiceTestFixture.create(
        tempDirectory,
        selectedDirectory: exportDirectory.path,
      );

      final file = await fixture.service.exportAllSessionsToUserFolder(
        suggestedFileName: 'sauvegarde_nex_target.json',
      );

      expect(file, isNotNull);
      expect(file!.path, '${exportDirectory.path}/sauvegarde_nex_target.json');
      expect(await file.exists(), isTrue);
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(data['format'], 'mycoach-data');
      expect(data['version'], 3);
      expect(data['sessions_count'], 1);
      expect(data['goals_count'], 1);
      expect(data['weapons_count'], 1);
      expect((data['sessions'] as List).single['weapon'], 'Pistolet de test');
      expect((data['goals'] as List).single['id'], 'goal-export');
      expect((data['weapons'] as List).single['id'], 'weapon-export');
      expect(DateTime.tryParse(data['exported_at'] as String), isNotNull);
    });

    test('une annulation retourne null et ne crée aucun fichier', () async {
      final fixture = await BackupServiceTestFixture.create(tempDirectory);

      final file = await fixture.service.exportAllSessionsToUserFolder();

      expect(file, isNull);
      expect(await exportDirectory.list().toList(), isEmpty);
    });

    test('une erreur d’écriture est propagée sans fichier partiel', () async {
      final invalidDirectory = File('${tempDirectory.path}/not_a_directory');
      await invalidDirectory.writeAsString('blocage');
      final fixture = await BackupServiceTestFixture.create(
        tempDirectory,
        selectedDirectory: invalidDirectory.path,
      );

      await expectLater(
        fixture.service.exportAllSessionsToUserFolder(
          suggestedFileName: 'export.json',
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(await invalidDirectory.readAsString(), 'blocage');
    });
  });
}
