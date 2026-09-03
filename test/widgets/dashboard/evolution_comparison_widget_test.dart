import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/dashboard_data.dart';
import 'package:tir_sportif/theme/app_theme.dart';
import 'package:tir_sportif/widgets/dashboard/evolution_comparison_widget.dart';

void main() {
  testWidgets('affiche deux métriques et leurs deltas indépendants',
      (tester) async {
    final data = EvolutionComparisonData(
      title: 'Dynamique des performances · 30 j vs 90 j',
      hasRequiredPopulation: true,
      score: _metric(avg30: 50, avg90: 40, delta: 10, relative: 25),
      groupSize: _metric(
        avg30: 24,
        avg90: 28,
        delta: -4,
        relative: -14.2857,
      ),
    );

    await _pump(tester, data, AppTheme.darkTheme);

    expect(find.text('Points par série'), findsOneWidget);
    expect(find.text('Groupement par série'), findsOneWidget);
    final scoreTitle = find.text('Points par série');
    final groupTitle = find.text('Groupement par série');
    expect(
      find.descendant(
        of: find.ancestor(of: scoreTitle, matching: find.byType(Row)),
        matching: find.byIcon(Icons.trending_up),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(of: groupTitle, matching: find.byType(Row)),
        matching: find.byIcon(Icons.center_focus_strong),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Les 90 derniers jours incluent les 30 derniers jours.'),
      findsNothing,
    );
    expect(find.text('+10,0 pts · +25,0 %'), findsOneWidget);
    expect(find.text('-4,0 cm · +14,3 %'), findsOneWidget);
    expect(find.text('Delta'), findsNWidgets(2));
    expect(find.textContaining('d’amélioration'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
      'rend la division par zéro et les données insuffisantes explicites',
      (tester) async {
    final data = EvolutionComparisonData(
      title: 'Dynamique des performances · 30 j vs 90 j',
      hasRequiredPopulation: true,
      score: _metric(avg30: 0, avg90: 0, delta: 0, relative: null),
      groupSize: const EvolutionMetricComparison.empty(),
    );

    await _pump(tester, data, AppTheme.bleuBlancRougeTheme);

    expect(
      find.text(
        '±0,0 pts · pourcentage indisponible (base 90 j nulle)',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Données insuffisantes pour cette métrique'),
      findsOneWidget,
    );
  });

  testWidgets('masque la sparkline à quatre sessions et l’affiche à cinq',
      (tester) async {
    final four = EvolutionComparisonData(
      title: 'Dynamique des performances · 30 j vs 90 j',
      hasRequiredPopulation: true,
      score: _metric(pointCount: 4),
      groupSize: _metric(pointCount: 4),
    );
    await _pump(tester, four, AppTheme.darkTheme);

    expect(find.text('Tendance masquée : 4/5 sessions exploitables.'),
        findsNWidgets(2));
    expect(
        find.byKey(const ValueKey('sparkline-Points par série')), findsNothing);
    expect(
      find.byKey(const ValueKey('sparkline-Groupement par série')),
      findsNothing,
    );

    final five = EvolutionComparisonData(
      title: 'Dynamique des performances · 30 j vs 90 j',
      hasRequiredPopulation: true,
      score: _metric(pointCount: 5),
      groupSize: _metric(pointCount: 5),
    );
    await _pump(tester, five, AppTheme.darkTheme);

    expect(find.byKey(const ValueKey('sparkline-Points par série')),
        findsOneWidget);
    expect(
      find.byKey(const ValueKey('sparkline-Groupement par série')),
      findsOneWidget,
    );
    expect(find.textContaining('5 sessions · un point par session'),
        findsNWidgets(2));
  });

  for (final theme in [AppTheme.darkTheme, AppTheme.bleuBlancRougeTheme]) {
    testWidgets(
        'reste lisible à petite largeur en thème ${theme.brightness.name}',
        (tester) async {
      final data = EvolutionComparisonData(
        title: 'Dynamique des performances · 30 j vs 90 j',
        hasRequiredPopulation: true,
        score: _metric(pointCount: 5),
        groupSize: _metric(pointCount: 5),
      );

      await _pump(tester, data, theme, width: 240);

      expect(tester.takeException(), isNull);
      expect(find.text('30 j'), findsNWidgets(2));
      expect(find.text('90 j'), findsNWidgets(2));
      expect(find.textContaining('Ancien'), findsNWidgets(2));
      expect(find.textContaining('Récent'), findsNWidgets(2));
    });
  }

  testWidgets('explique la population minimale globale', (tester) async {
    await _pump(
      tester,
      const EvolutionComparisonData.empty(
        'Dynamique des performances · 30 j vs 90 j',
      ),
      AppTheme.darkTheme,
    );

    expect(find.textContaining('une autre entre J-90 et J-31'), findsOneWidget);
    expect(find.text('Points par série'), findsNothing);
  });

  testWidgets('augmente la précision si l’arrondi masque un écart réel',
      (tester) async {
    final data = EvolutionComparisonData(
      title: 'Dynamique des performances · 30 j vs 90 j',
      hasRequiredPopulation: true,
      score: _metric(),
      groupSize: _metric(
        avg30: 14.44,
        avg90: 14.4,
        delta: 0.04,
        relative: 0.2777,
      ),
    );

    await _pump(tester, data, AppTheme.darkTheme);

    expect(find.text('14,44 cm'), findsOneWidget);
    expect(find.text('14,40 cm'), findsOneWidget);
    expect(
      find.text('+0,04 cm · -0,3 %'),
      findsOneWidget,
    );
  });
}

EvolutionMetricComparison _metric({
  double avg30 = 40,
  double avg90 = 35,
  double delta = 5,
  double? relative = 14.2857,
  int pointCount = 0,
}) {
  return EvolutionMetricComparison(
    avg30Days: avg30,
    avg90Days: avg90,
    absoluteDelta: delta,
    relativeDeltaPercent: relative,
    recentSeriesCount: 1,
    earlierSeriesCount: 1,
    sessionPoints: List.generate(
      pointCount,
      (index) => SessionMetricPoint(
        date: DateTime(2026, 1, index + 1),
        value: index.toDouble(),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  EvolutionComparisonData data,
  ThemeData theme, {
  double width = 320,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: EvolutionComparisonWidget(data: data),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
