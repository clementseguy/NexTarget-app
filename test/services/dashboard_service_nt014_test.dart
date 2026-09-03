import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/dashboard_service.dart';

void main() {
  final now = DateTime(2026, 9, 3, 12, 30);

  group('DashboardService NT-014', () {
    test('inclut précisément J-30 et J-90 dans les fenêtres emboîtées', () {
      final data = DashboardService(
        [
          _session(now.subtract(const Duration(days: 30)), 60, 20),
          _session(now.subtract(const Duration(days: 90)), 30, 28),
          _session(
            now.subtract(const Duration(days: 90, microseconds: 1)),
            100,
            1,
          ),
          _session(now.add(const Duration(microseconds: 1)), 100, 1),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.hasRequiredPopulation, isTrue);
      expect(data.score.recentSeriesCount, 1);
      expect(data.score.earlierSeriesCount, 1);
      expect(data.score.avg30Days, 60);
      expect(data.score.avg90Days, 45);
      expect(data.score.absoluteDelta, 15);
      expect(data.score.relativeDeltaPercent, closeTo(33.333, 0.001));
      expect(data.groupSize.avg30Days, 20);
      expect(data.groupSize.avg90Days, 24);
      expect(data.groupSize.absoluteDelta, -4);
      expect(data.groupSize.relativeDeltaPercent, closeTo(-16.667, 0.001));
    });

    test('exclut sessions prévues, libres et sans date', () {
      final recent = _session(now.subtract(const Duration(days: 2)), 40, 20);
      final earlier = _session(now.subtract(const Duration(days: 40)), 20, 30);
      final planned = _session(
        now.subtract(const Duration(days: 1)),
        100,
        1,
        status: SessionConstants.statusPrevue,
      );
      final withoutDate = _session(null, 100, 1);
      final simple = SimpleShootingSession(
        date: now.subtract(const Duration(days: 1)),
        weapon: 'Pistolet',
        caliber: '9 mm',
        shotCount: 50,
        distance: 25,
      );

      final data = DashboardService(
        [recent, earlier, planned, withoutDate, simple],
        now: now,
      ).generateEvolutionComparison();

      expect(data.score.avg30Days, 40);
      expect(data.score.avg90Days, 30);
      expect(data.score.sessionPoints, hasLength(2));
    });

    test(
        'un score nul est valide et la division par une base nulle est explicite',
        () {
      final data = DashboardService(
        [
          _session(now.subtract(const Duration(days: 1)), 0, 10),
          _session(now.subtract(const Duration(days: 31)), 0, 12),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.hasRequiredPopulation, isTrue);
      expect(data.score.avg30Days, 0);
      expect(data.score.avg90Days, 0);
      expect(data.score.absoluteDelta, 0);
      expect(data.score.relativeDeltaPercent, isNull);
    });

    test('refuse le comparatif si une des deux populations score manque', () {
      final recentOnly = DashboardService(
        [_session(now.subtract(const Duration(days: 1)), 40, 10)],
        now: now,
      ).generateEvolutionComparison();
      final earlierOnly = DashboardService(
        [_session(now.subtract(const Duration(days: 31)), 40, 10)],
        now: now,
      ).generateEvolutionComparison();

      expect(recentOnly.hasRequiredPopulation, isFalse);
      expect(recentOnly.score.recentSeriesCount, 1);
      expect(recentOnly.score.earlierSeriesCount, 0);
      expect(earlierOnly.hasRequiredPopulation, isFalse);
      expect(earlierOnly.score.recentSeriesCount, 0);
      expect(earlierOnly.score.earlierSeriesCount, 1);
    });

    test('ignore les groupements invalides pour cette seule métrique', () {
      final data = DashboardService(
        [
          _multiSeriesSession(
            now.subtract(const Duration(days: 1)),
            [
              Series(distance: 25, points: 0, groupSize: 0),
              Series(distance: 25, points: 40, groupSize: double.nan),
            ],
          ),
          _multiSeriesSession(
            now.subtract(const Duration(days: 31)),
            [Series(distance: 25, points: 20, groupSize: -2)],
          ),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.hasRequiredPopulation, isTrue);
      expect(data.score.recentSeriesCount, 2);
      expect(data.score.earlierSeriesCount, 1);
      expect(data.score.avg30Days, 20);
      expect(data.groupSize.hasComparison, isFalse);
      expect(data.groupSize.sessionPoints, isEmpty);
    });

    test('score et groupement peuvent évoluer dans des directions opposées',
        () {
      final data = DashboardService(
        [
          _session(now.subtract(const Duration(days: 1)), 50, 30),
          _session(now.subtract(const Duration(days: 31)), 30, 20),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.score.absoluteDelta, greaterThan(0));
      expect(data.groupSize.absoluteDelta, greaterThan(0));
      expect(data.score.relativeDeltaPercent, greaterThan(0));
      expect(data.groupSize.relativeDeltaPercent, greaterThan(0));
    });

    test('sparkline apparaît à cinq sessions exploitables, pas à quatre', () {
      final fourSessions = [
        _session(now.subtract(const Duration(days: 70)), 10, 0),
        _session(now.subtract(const Duration(days: 40)), 20, 12),
        _session(now.subtract(const Duration(days: 20)), 30, 10),
        _session(now.subtract(const Duration(days: 1)), 40, 8),
      ];
      final four = DashboardService(fourSessions, now: now)
          .generateEvolutionComparison();

      expect(four.score.sessionPoints, hasLength(4));
      expect(four.score.hasSparkline, isFalse);
      expect(four.groupSize.sessionPoints, hasLength(3));
      expect(four.groupSize.hasSparkline, isFalse);

      final five = DashboardService(
        [
          ...fourSessions,
          _session(now.subtract(const Duration(days: 10)), 35, 9),
          _session(now.subtract(const Duration(days: 5)), 38, 7),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(five.score.sessionPoints, hasLength(6));
      expect(five.score.hasSparkline, isTrue);
      expect(five.groupSize.sessionPoints, hasLength(5));
      expect(five.groupSize.hasSparkline, isTrue);
      expect(
        five.score.sessionPoints.map((point) => point.value),
        [10, 20, 30, 35, 38, 40],
      );
    });

    test('un point de sparkline est la moyenne des séries de sa session', () {
      final data = DashboardService(
        [
          _multiSeriesSession(
            now.subtract(const Duration(days: 31)),
            [
              Series(distance: 25, points: 10, groupSize: 0),
              Series(distance: 25, points: 30, groupSize: 20),
            ],
          ),
          _multiSeriesSession(
            now.subtract(const Duration(days: 1)),
            [
              Series(distance: 25, points: 40, groupSize: 10),
              Series(distance: 25, points: 50, groupSize: 14),
            ],
          ),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.score.sessionPoints.map((point) => point.value), [20, 45]);
      expect(
          data.groupSize.sessionPoints.map((point) => point.value), [20, 12]);
    });

    test('ne tronque pas une population supérieure à mille séries', () {
      final earlierSeries = List.generate(
        1001,
        (_) => Series(distance: 25, points: 10, groupSize: 20),
      );
      final data = DashboardService(
        [
          _multiSeriesSession(
            now.subtract(const Duration(days: 31)),
            earlierSeries,
          ),
          _session(now.subtract(const Duration(days: 1)), 20, 10),
        ],
        now: now,
      ).generateEvolutionComparison();

      expect(data.score.earlierSeriesCount, 1001);
      expect(data.score.avg90Days, closeTo(10030 / 1002, 0.0001));
    });
  });
}

DetailedShootingSession _session(
  DateTime? date,
  int points,
  double groupSize, {
  String status = SessionConstants.statusRealisee,
}) {
  return _multiSeriesSession(
    date,
    [Series(distance: 25, points: points, groupSize: groupSize)],
    status: status,
  );
}

DetailedShootingSession _multiSeriesSession(
  DateTime? date,
  List<Series> series, {
  String status = SessionConstants.statusRealisee,
}) {
  return DetailedShootingSession(
    date: date,
    weapon: 'Pistolet',
    caliber: '9 mm',
    status: status,
    series: series,
  );
}
