import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
      expect(file.uri.pathSegments.last, startsWith('sessions_export_'));
      expect(await file.exists(), isTrue);
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(data['format'], 'mycoach-data');
      expect(data['version'], 3);
      expect(data['sessions_count'], 1);
      expect(data['goals_count'], 1);
      expect(data['weapons_count'], 1);
    });
  });
}
