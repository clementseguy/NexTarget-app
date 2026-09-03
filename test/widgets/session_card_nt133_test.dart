import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/theme/app_theme.dart';
import 'package:tir_sportif/widgets/session_card.dart';

void main() {
  for (final theme in AppThemeType.values) {
    testWidgets('carte libre compacte et lisible en thème ${theme.name}',
        (tester) async {
      final session = SimpleShootingSession(
        date: DateTime(2026, 9, 3),
        weapon: 'CZ 75',
        caliber: '9 mm',
        shotCount: 40,
        distance: 25,
        category: 'test matériel',
        exercises: const ['e1', 'e2'],
        synthese: 'Ne doit pas apparaître sur la carte',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forType(theme),
          home: Scaffold(
            body: SessionCard(session: session.toMap(), series: const []),
          ),
        ),
      );

      expect(find.text('Libre'), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add), findsOneWidget);
      expect(find.textContaining('CZ 75'), findsOneWidget);
      expect(find.textContaining('9 mm'), findsOneWidget);
      expect(find.textContaining('test matériel'), findsOneWidget);
      expect(find.text('40 tirs à 25 m'), findsOneWidget);
      expect(find.text('2 exercice(s)'), findsOneWidget);
      expect(find.textContaining('Score moyen'), findsNothing);
      expect(find.textContaining('Groupement moyen'), findsNothing);
      expect(find.textContaining('Ne doit pas apparaître'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
