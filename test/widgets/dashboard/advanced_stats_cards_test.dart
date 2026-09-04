import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/dashboard/advanced_stats_cards.dart';
import 'package:tir_sportif/widgets/dashboard/stat_card.dart';
import 'package:tir_sportif/models/dashboard_data.dart';

void main() {
  group('AdvancedStatsCards', () {
    testWidgets('displays loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              summary: DashboardSummary.empty(),
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(StatCardLoading), findsNWidgets(4));
    });

    testWidgets('displays empty state with proper fallbacks',
        (WidgetTester tester) async {
      const emptyData = AdvancedStatsData.empty();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: emptyData,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('Régularité'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Prise dominante'), findsOneWidget);

      // Vérifier les valeurs par défaut
      expect(find.text('-'), findsAtLeastNWidgets(4));
    });

    testWidgets('displays valid data correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: const AdvancedStatsData(
                consistency: 85.5,
                progression: 12.3,
                dominantHandMethod: 'two',
                dominantHandMethodPercentage: 75.5,
              ),
              comparisonData: _comparison(group: -14.2857, score: 25),
              summary: const DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('85.5%'), findsOneWidget);
      expect(find.text('+14,3 %'), findsOneWidget);
      expect(find.text('+25,0 %'), findsOneWidget);
      expect(find.text('2 mains (75.5%)'), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsNWidgets(2));
    });

    testWidgets('handles negative progression', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: const AdvancedStatsData(
                consistency: 65.0,
                progression: -8.2,
                dominantHandMethod: 'one',
                dominantHandMethodPercentage: 40.2,
              ),
              comparisonData: _comparison(group: 8.2, score: -10),
              summary: const DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('65.0%'), findsOneWidget);
      expect(find.text('-8,2 %'), findsOneWidget);
      expect(find.text('-10,0 %'), findsOneWidget);
      expect(find.text('1 main (40.2%)'), findsOneWidget);
    });

    testWidgets('handles unavailable comparison', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 70.0,
        progression: double.nan,
        dominantHandMethod: 'two',
        dominantHandMethodPercentage: 88.9,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      expect(find.text('70.0%'), findsOneWidget);
      expect(find.text('-'), findsAtLeastNWidgets(2));
      expect(find.text('2 mains (88.9%)'), findsOneWidget);
    });

    testWidgets('displays widgets correctly', (WidgetTester tester) async {
      const data = AdvancedStatsData(
        consistency: 80.0,
        progression: 5.0,
        dominantHandMethod: 'two',
        dominantHandMethodPercentage: 66.7,
      );

      // Test simple sans contraintes spécifiques
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdvancedStatsCards(
              data: data,
              summary: DashboardSummary.empty(),
            ),
          ),
        ),
      );

      // Vérifier que les cartes utilisent GridView
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(StatCard), findsNWidgets(3));

      // Vérifier le contenu
      expect(find.text('Sessions ce mois'), findsOneWidget);
      expect(find.text('Régularité'), findsOneWidget);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('Prise dominante'), findsOneWidget);
    });

    testWidgets('progression reste lisible sur petite largeur', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdvancedStatsCards(
                data: const AdvancedStatsData.empty(),
                comparisonData: _comparison(group: -14.2857, score: 25),
                summary: const DashboardSummary.empty(),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Progression'), findsOneWidget);
      expect(find.text('+14,3 %'), findsOneWidget);
      expect(find.text('+25,0 %'), findsOneWidget);
    });
  });
}

EvolutionComparisonData _comparison({
  required double group,
  required double score,
}) {
  EvolutionMetricComparison metric(double relative) =>
      EvolutionMetricComparison(
        avg30Days: 1,
        avg90Days: 1,
        absoluteDelta: 0,
        relativeDeltaPercent: relative,
        recentSeriesCount: 1,
        earlierSeriesCount: 1,
        sessionPoints: const [],
      );
  return EvolutionComparisonData(
    score: metric(score),
    groupSize: metric(group),
    hasRequiredPopulation: true,
    title: 'Dynamique des performances · 30 j vs 90 j',
  );
}
