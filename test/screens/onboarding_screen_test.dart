import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/screens/onboarding_screen.dart';
import 'package:tir_sportif/services/preferences_service.dart';

/// NT-075 — onboarding 3 écrans au premier lancement.
void main() {
  setUpAll(() async {
    // Box 100 % en mémoire (bytes:) : aucune écriture disque, donc aucun
    // deadlock possible entre la zone fake-async de testWidgets et la file
    // d'écriture Hive (les put() déclenchés par les taps ne se complètent
    // jamais si la box est adossée à un fichier).
    Hive.init(Directory.systemTemp.createTempSync('nt_hive_test_').path);
    await Hive.openBox('app_preferences', bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box('app_preferences').delete('onboarding_seen');
  });

  testWidgets('OnboardingGate affiche l\'onboarding au premier lancement', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingGate(child: Text('APP')),
    ));

    expect(find.text('Votre carnet de tir'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('OnboardingGate saute l\'onboarding si déjà vu', (tester) async {
    // runAsync : l'écriture Hive est une vraie I/O, à ne pas awaiter
    // directement dans la zone fake-async de testWidgets (deadlock).
    await tester.runAsync(() => PreferencesService().setOnboardingSeen(true));

    await tester.pumpWidget(const MaterialApp(
      home: OnboardingGate(child: Text('APP')),
    ));

    expect(find.text('APP'), findsOneWidget);
    expect(find.text('Votre carnet de tir'), findsNothing);
  });

  testWidgets('Passer termine l\'onboarding et persiste le flag', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingGate(child: Text('APP')),
    ));

    await tester.tap(find.text('Passer'));
    await tester.pump();

    expect(find.text('APP'), findsOneWidget);
    expect(PreferencesService().isOnboardingSeen(), isTrue);
  });

  testWidgets('parcours complet : 3 pages puis Commencer', (tester) async {
    // Pumps bornés (pas de pumpAndSettle) : la transition du PageView peut
    // continuer à programmer des frames et faire tourner pumpAndSettle
    // jusqu'à son timeout de 10 minutes.
    Future<void> settlePage() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpWidget(const MaterialApp(
      home: OnboardingGate(child: Text('APP')),
    ));

    // Page 1 → 2
    await tester.tap(find.text('Suivant'));
    await settlePage();
    expect(find.text('Progressez avec vos stats'), findsOneWidget);

    // Page 2 → 3
    await tester.tap(find.text('Suivant'));
    await settlePage();
    expect(find.text('Votre coach IA'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pump();

    expect(find.text('APP'), findsOneWidget);
    expect(PreferencesService().isOnboardingSeen(), isTrue);
  });
}
