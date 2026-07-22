import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/services/preferences_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppConfig.load();
    tempDir = Directory.systemTemp.createTempSync('nextarget_prefs_');
    Hive.init(tempDir.path);
    await Hive.openBox('app_preferences');
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  test('PreferencesService stores and reads default caliber', () async {
    final prefs = PreferencesService();
    await prefs.setDefaultCaliber('40 s&w');
    expect(prefs.getDefaultCaliber(), '.40 S&W');

    await prefs.setDefaultCaliber('');
    expect(prefs.getDefaultCaliber(), isNull);
  });

  test('PreferencesService stores and reads last caliber alias', () async {
    final prefs = PreferencesService();
    await prefs.setLastCaliber('22lr');
    expect(prefs.getLastCaliber(), '.22 LR');
    expect(prefs.getDefaultCaliber(), '.22 LR');
  });
}
