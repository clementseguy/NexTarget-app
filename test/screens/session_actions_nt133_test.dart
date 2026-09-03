import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/navigation/app_router.dart';
import 'package:tir_sportif/providers/navigation_provider.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('nt_actions133_');
    Hive.init(directory.path);
    await Hive.openBox('sessions', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
    if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').close();
  });

  Future<void> pumpSessions(WidgetTester tester) async {
    final navigation = NavigationProvider()..changeIndex(3);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: navigation,
        child: MaterialApp(home: AppNavigator()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('les deux actions sont visibles uniquement dans Réalisées',
      (tester) async {
    await pumpSessions(tester);

    expect(find.byTooltip('Créer une session détaillée'), findsOneWidget);
    expect(find.byTooltip('Créer une session libre'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);

    await tester.tap(find.text('Prévues'));
    await tester.pump();

    expect(find.byTooltip('Créer une session détaillée'), findsOneWidget);
    expect(find.byTooltip('Créer une session libre'), findsNothing);
  });

  testWidgets('le retour vers Sessions resynchronise l’onglet Réalisées',
      (tester) async {
    await pumpSessions(tester);

    await tester.tap(find.text('Prévues'));
    await tester.pump();
    expect(find.byTooltip('Créer une session libre'), findsNothing);

    await tester.tap(find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Coach'),
    ));
    await tester.pump();
    await tester.tap(find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Sessions'),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.text('Réalisées'), findsOneWidget);
    expect(find.byTooltip('Créer une session libre'), findsOneWidget);
  });

  testWidgets('l’aide explique les sessions détaillées et libres',
      (tester) async {
    await pumpSessions(tester);
    await tester.tap(find.byTooltip('Aide'));
    await tester.pumpAndSettle();

    expect(find.textContaining('session libre sans séries'), findsOneWidget);
    expect(find.textContaining('Chaque session contient vos séries'),
        findsOneWidget);
  });
}
