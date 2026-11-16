import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/services/coach_experience_preference_service.dart';

void main() {
  late Box<dynamic> preferencesBox;

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('nt155_');
    Hive.init(directory.path);
    preferencesBox = await Hive.openBox(
      'app_preferences',
      bytes: Uint8List(0),
    );
  });

  setUp(() => preferencesBox.clear());
  tearDownAll(Hive.close);

  test('reprend une seule fois un niveau valide du profil en cache', () async {
    final service = CoachExperiencePreferenceService(preferencesBox);

    var cacheReads = 0;
    await service.initializeFromCachedProfile(() async {
      cacheReads++;
      return {'experience_level': 'advanced'};
    });
    await service.initializeFromCachedProfile(() async {
      cacheReads++;
      return {'experience_level': 'expert'};
    });

    expect(service.experienceLevel, 'advanced');
    expect(service.isInitialized, isTrue);
    expect(cacheReads, 1);
  });

  test('initialise sans valeur quand le profil historique est absent',
      () async {
    final service = CoachExperiencePreferenceService(preferencesBox);

    await service.initializeFromCachedProfile(() async => null);

    expect(service.experienceLevel, isNull);
    expect(service.isInitialized, isTrue);
  });

  test('une valeur volontairement vide ne peut pas être restaurée', () async {
    final service = CoachExperiencePreferenceService(preferencesBox);
    await service.updateExperienceLevel(null);

    await service.initializeFromCachedProfile(
      () async => {'experience_level': 'expert'},
    );

    expect(service.experienceLevel, isNull);
    expect(service.isInitialized, isTrue);
  });

  test('le niveau persiste dans une nouvelle instance', () async {
    final service = CoachExperiencePreferenceService(preferencesBox);
    await service.updateExperienceLevel('beginner');

    final restarted = CoachExperiencePreferenceService(preferencesBox);

    expect(restarted.experienceLevel, 'beginner');
  });

  test('un changement de profil ou son absence ne modifie pas le choix',
      () async {
    final service = CoachExperiencePreferenceService(preferencesBox);
    await service.updateExperienceLevel('expert');

    await service.initializeFromCachedProfile(() async => null);
    await service.initializeFromCachedProfile(
      () async => {'experience_level': 'beginner'},
    );

    expect(service.experienceLevel, 'expert');
  });

  test('refuse une valeur inconnue sans modifier la préférence', () async {
    final service = CoachExperiencePreferenceService(preferencesBox);

    await expectLater(
      service.updateExperienceLevel('confirmed'),
      throwsArgumentError,
    );

    expect(service.experienceLevel, isNull);
    expect(service.isInitialized, isFalse);
  });

  test('un cache indisponible ne marque pas la migration comme terminée',
      () async {
    final service = CoachExperiencePreferenceService(preferencesBox);

    await expectLater(
      service.initializeFromCachedProfile(
        () async => throw StateError('cache indisponible'),
      ),
      throwsStateError,
    );

    expect(service.experienceLevel, isNull);
    expect(service.isInitialized, isFalse);
  });
}
