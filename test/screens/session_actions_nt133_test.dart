import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/navigation/app_router.dart';
import 'package:tir_sportif/providers/navigation_provider.dart';
import 'package:tir_sportif/widgets/help_button.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('nt_actions133_');
    Hive.init(directory.path);
    await Hive.openBox('sessions', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box('sessions').clear();
    await Hive.box('exercises').clear();
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

  testWidgets('affiche Au stand et le menu secondaire explicite',
      (tester) async {
    await pumpSessions(tester);

    expect(find.byTooltip('Au stand'), findsOneWidget);
    expect(find.byTooltip('Autres créations'), findsOneWidget);

    await tester.tap(find.byTooltip('Autres créations'));
    await tester.pumpAndSettle();

    expect(find.text('Session planifiée'), findsOneWidget);
    expect(find.text('Session réalisée détaillée'), findsOneWidget);
    expect(find.text('Session libre'), findsOneWidget);
  });

  testWidgets('le retour vers Sessions resynchronise l’onglet Réalisées',
      (tester) async {
    await pumpSessions(tester);

    await tester.tap(find.text('Prévues'));
    await tester.pump();
    expect(find.byTooltip('Au stand'), findsOneWidget);

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
    expect(find.byTooltip('Au stand'), findsOneWidget);
  });

  testWidgets('l’aide explique les sessions détaillées et libres',
      (tester) async {
    await pumpSessions(tester);
    final help = tester.widget<HelpButton>(find.byType(HelpButton));
    expect(help.points, contains(contains('hors statistiques et Coach')));
    expect(
        help.points, contains(contains('Chaque session contient vos séries')));
    await tester.tap(find.byTooltip('Aide'));
    await tester.pumpAndSettle();

    expect(find.textContaining('créer rapidement une session'), findsOneWidget);
    expect(find.textContaining('planifier des sessions dans le futur'),
        findsOneWidget);
    expect(find.textContaining('sessions libres ou des sessions détaillées'),
        findsOneWidget);
  });

  testWidgets('un brouillon conserve Au stand et se reprend depuis sa carte',
      (tester) async {
    await Hive.box('sessions').put(1, {
      'session': {
        'sessionType': 'detailed',
        'id': 1,
        'date': DateTime(2026, 9, 4).toIso8601String(),
        'weapon': 'Pistolet',
        'caliber': '9 mm',
        'status': 'brouillon',
        'category': 'entraînement',
        'exercises': <String>[],
      },
      'series': [
        {
          'shot_count': 5,
          'distance': 25,
          'points': 0,
          'group_size': 0,
          'completed': false,
          'draft_started': false,
        },
      ],
    });

    await pumpSessions(tester);

    expect(find.byTooltip('Au stand'), findsOneWidget);
    expect(find.byTooltip('Reprendre la séance'), findsNothing);
    expect(find.text('Reprendre'), findsOneWidget);

    await tester.tap(find.byTooltip('Au stand'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reprenez-la depuis sa carte'), findsOneWidget);
  });
}
