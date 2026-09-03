import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/screens/home_screen.dart';
import 'package:tir_sportif/widgets/help_button.dart';

/// NT-075 — bouton d'aide contextuelle « ? ».
void main() {
  testWidgets('HelpButton ouvre une bottom sheet avec titre et points',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: HelpButton(
          title: 'Écran de test',
          points: ['Premier point d\'aide.', 'Second point d\'aide.'],
        ),
      ),
    ));

    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('Écran de test'), findsOneWidget);
    expect(find.text('Premier point d\'aide.'), findsOneWidget);
    expect(find.text('Second point d\'aide.'), findsOneWidget);
  });

  testWidgets('aide statistiques explique les indicateurs complexes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HelpButton(
            title: 'Comprendre les statistiques',
            points: dashboardStatisticsHelpPoints,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('Régularité :'), findsOneWidget);
    expect(find.textContaining('Progression :'), findsOneWidget);
    expect(find.textContaining('Dynamique des performances :'), findsOneWidget);
    expect(find.textContaining('chaque point de la courbe'), findsOneWidget);
  });
}
