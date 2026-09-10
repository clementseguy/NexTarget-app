import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/screens/coach_screen.dart';

void main() {
  late Box<dynamic> preferencesBox;

  setUpAll(() async {
    final directory = Directory.systemTemp.createTempSync('coach_screen_');
    Hive.init(directory.path);
    preferencesBox = await Hive.openBox(
      'app_preferences',
      bytes: Uint8List(0),
    );
  });

  setUp(() => preferencesBox.clear());

  tearDownAll(Hive.close);

  Future<void> pumpCoach(WidgetTester tester) {
    return tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(preferencesBox: preferencesBox),
        child: const MaterialApp(home: CoachScreen()),
      ),
    );
  }

  testWidgets('le futur Coach exige le partage des données par défaut',
      (tester) async {
    await pumpCoach(tester);

    expect(find.textContaining('Le partage de vos données est requis'),
        findsOneWidget);
    expect(find.text('Paramètres Coach'), findsOneWidget);
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('le futur Coach reste présenté lorsque le partage est autorisé',
      (tester) async {
    await preferencesBox.put('coach_data_sharing_allowed', true);

    await pumpCoach(tester);

    expect(find.text('Coming soon'), findsOneWidget);
    expect(find.textContaining('Le partage de vos données est requis'),
        findsNothing);
  });
}
