import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/providers/settings_provider.dart';

void main() {
  late Box<dynamic> preferencesBox;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync('coach_consent_');
    Hive.init(directory.path);
    preferencesBox = await Hive.openBox(
      'app_preferences',
      bytes: Uint8List(0),
    );
  });

  setUp(() => preferencesBox.clear());

  tearDownAll(Hive.close);

  test('le consentement est refusé par défaut', () {
    final settings = SettingsProvider(preferencesBox: preferencesBox);

    expect(settings.isCoachDataSharingAllowed, isFalse);
  });

  test('le choix est persisté et notifie les consommateurs', () async {
    final settings = SettingsProvider(preferencesBox: preferencesBox);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.updateCoachDataSharingAllowed(true);

    final reloaded = SettingsProvider(preferencesBox: preferencesBox);
    expect(reloaded.isCoachDataSharingAllowed, isTrue);
    expect(
      preferencesBox.get('coach_data_sharing_allowed'),
      isTrue,
    );
    expect(notifications, 1);

    await reloaded.updateCoachDataSharingAllowed(false);
    expect(reloaded.isCoachDataSharingAllowed, isFalse);
    expect(preferencesBox.get('coach_data_sharing_allowed'), isFalse);
  });

  test('une valeur stockée invalide reste un refus', () async {
    await preferencesBox.put('coach_data_sharing_allowed', 'true');

    final settings = SettingsProvider(preferencesBox: preferencesBox);

    expect(settings.isCoachDataSharingAllowed, isFalse);
  });

  test('le niveau Coach nullable est persisté et notifie', () async {
    final settings = SettingsProvider(preferencesBox: preferencesBox);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.updateCoachExperienceLevel('advanced');
    expect(settings.coachExperienceLevel, 'advanced');

    final restarted = SettingsProvider(preferencesBox: preferencesBox);
    expect(restarted.coachExperienceLevel, 'advanced');

    await restarted.updateCoachExperienceLevel(null);
    expect(restarted.coachExperienceLevel, isNull);
    expect(notifications, 1);
  });
}
