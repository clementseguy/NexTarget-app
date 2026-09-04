import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/preferences_service.dart';
import 'package:tir_sportif/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    await AppConfig.load();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nt_prefs_caliber_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_preferences');
  });

  tearDown(() async {
    if (Hive.isBoxOpen('app_preferences')) await Hive.box('app_preferences').close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('PreferencesService stores and reads default caliber', () async {
    final prefs = PreferencesService();
    await prefs.setDefaultCaliber('.40 S&W');
    expect(prefs.getDefaultCaliber(), '.40 S&W');

    await prefs.setDefaultCaliber('');
    expect(prefs.getDefaultCaliber(), isNull);
  });

  test('PreferencesService refuse un calibre inconnu', () async {
    final prefs = PreferencesService();
    await expectLater(
      prefs.setDefaultCaliber('calibre maison'),
      throwsArgumentError,
    );
    expect(prefs.getDefaultCaliber(), isNull);
  });

  test('PreferencesService ignore une ancienne préférence invalide', () async {
    await Hive.box('app_preferences').put('default_caliber', 'Autre');
    expect(PreferencesService().getDefaultCaliber(), isNull);
  });
}
