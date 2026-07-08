import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/providers/settings_provider.dart';

/// NT-032 — préférence de persona du coach IA (prompt_variant).
void main() {
  late SettingsProvider settings;

  setUpAll(() async {
    // Box 100 % en mémoire (bytes:) : uniforme avec les widget tests,
    // aucune écriture disque.
    Hive.init(Directory.systemTemp.createTempSync('nt_hive_test_').path);
    await Hive.openBox('app_preferences', bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box('app_preferences').delete('coach_persona');
    settings = SettingsProvider(preferencesBox: Hive.box('app_preferences'));
  });

  test('défaut = coach_neutre', () {
    expect(settings.coachPersona, 'coach_neutre');
  });

  test('updateCoachPersona persiste coach_cool et notifie', () async {
    var notified = false;
    settings.addListener(() => notified = true);

    await settings.updateCoachPersona('coach_cool');

    expect(settings.coachPersona, 'coach_cool');
    expect(notified, isTrue);
    expect(Hive.box('app_preferences').get('coach_persona'), 'coach_cool');
  });

  test('persona inconnue refusée (préférence inchangée)', () async {
    await settings.updateCoachPersona('coach_pirate');
    expect(settings.coachPersona, 'coach_neutre');
  });

  test('valeur corrompue en base → repli sur coach_neutre', () async {
    await Hive.box('app_preferences').put('coach_persona', 'obsolete_value');
    expect(settings.coachPersona, 'coach_neutre');
  });
}
