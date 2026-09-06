import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/backup_service_test_fixture.dart';

void main() {
  late Directory tempDirectory;
  late BackupServiceTestFixture fixture;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'nt_backup_file_read_test_',
    );
    fixture = await BackupServiceTestFixture.create(tempDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('privilégie les octets du sélecteur à un chemin inaccessible', () async {
    const json = '{"format":"mycoach-data"}';

    final content = await fixture.service.readSelectedJson(
      bytes: utf8.encode(json),
      path: '${tempDirectory.path}/absent.json',
    );

    expect(content, json);
  });

  test(
    'lit le chemin local lorsque le sélecteur ne fournit pas les octets',
    () async {
      final file = File('${tempDirectory.path}/export.json');
      await file.writeAsString('{"version":3}');

      final content = await fixture.service.readSelectedJson(path: file.path);

      expect(content, '{"version":3}');
    },
  );

  test('signale une sélection sans octets ni chemin exploitable', () async {
    await expectLater(
      fixture.service.readSelectedJson(),
      throwsA(isA<FileSystemException>()),
    );
  });
}
