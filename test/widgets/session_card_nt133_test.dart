import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/theme/app_theme.dart';
import 'package:tir_sportif/widgets/session_card.dart';
import 'package:tir_sportif/widgets/session_chip.dart';

void main() {
  testWidgets('une session prévue sans date ne prend pas la date du jour',
      (tester) async {
    final session = DetailedShootingSession(
      date: null,
      weapon: 'Pistolet',
      caliber: '22LR',
      status: 'prévue',
      series: [Series(distance: 25, points: 0, groupSize: 0)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionCard(
            session: session.toMap(),
            series: session.series.map((item) => item.toMap()).toList(),
          ),
        ),
      ),
    );

    expect(find.text('Sans date'), findsOneWidget);
  });

  for (final theme in AppThemeType.values) {
    testWidgets('carte libre compacte et lisible en thème ${theme.name}',
        (tester) async {
      final themeData = AppTheme.forType(theme);
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
          theme: themeData,
          home: Scaffold(
            body: SessionCard(session: session.toMap(), series: const []),
          ),
        ),
      );

      expect(find.text('Libre'), findsNothing);
      expect(find.byIcon(simpleSessionIcon), findsOneWidget);
      expect(find.byTooltip('Session libre'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(simpleSessionIcon)).color,
        themeData.colorScheme.secondary,
      );
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.text('CZ 75'), findsOneWidget);
      expect(find.text('9 mm'), findsOneWidget);
      expect(find.text('Test matériel'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('25 m'), findsOneWidget);
      expect(find.text('2 exercice(s)'), findsOneWidget);
      expect(find.textContaining('Score'), findsNothing);
      expect(find.textContaining('Groupement'), findsNothing);
      expect(find.textContaining('Ne doit pas apparaître'), findsNothing);
      expect(
        tester.getCenter(find.byKey(const Key('sessionCardDateColumn'))).dy,
        closeTo(
          tester.getCenter(find.byKey(const Key('sessionCardContent'))).dy,
          0.1,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la carte libre ne dépasse pas la carte détaillée',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final simple = SimpleShootingSession(
      date: DateTime(2026, 9, 3),
      weapon: 'CZ 75',
      caliber: '9 mm',
      shotCount: 40,
      distance: 25,
      category: 'entraînement',
      exercises: const ['e1'],
    );
    final detailed = DetailedShootingSession(
      date: DateTime(2026, 9, 3),
      weapon: 'CZ 75',
      caliber: '9 mm',
      category: 'entraînement',
      analyse: 'Analyse disponible',
      exercises: const ['e1'],
      series: [Series(points: 45, groupSize: 8, distance: 25)],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              SessionCard(
                key: const Key('simpleCard'),
                session: simple.toMap(),
                series: const [],
              ),
              SessionCard(
                key: const Key('detailedCard'),
                session: detailed.toMap(),
                series: detailed.series.map((item) => item.toMap()).toList(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('simpleCard'))).height,
      lessThanOrEqualTo(
        tester.getSize(find.byKey(const Key('detailedCard'))).height,
      ),
    );
    expect(find.byIcon(Icons.analytics), findsOneWidget);
    expect(find.text('Coach'), findsNothing);
  });
}
