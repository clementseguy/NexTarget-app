import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/services/dashboard_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/rolling_stats_service.dart';
import 'package:tir_sportif/services/stats_service.dart';
import 'package:tir_sportif/utils/session_filters.dart';

class _SessionRepo implements SessionRepository {
  final List<ShootingSession> sessions;
  _SessionRepo(this.sessions);

  @override
  Future<void> clearAll() async => sessions.clear();
  @override
  Future<void> delete(int id) async => sessions.removeWhere((s) => s.id == id);
  @override
  Future<List<ShootingSession>> getAll() async => sessions;
  @override
  Future<int> insert(ShootingSession session) async => 1;
  @override
  Future<bool> update(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
  }) async =>
      false;
}

class _GoalRepo implements GoalRepository {
  final Map<String, Goal> goals = {};
  @override
  Future<void> delete(String id) async => goals.remove(id);
  @override
  Future<void> deleteAll() async => goals.clear();
  @override
  Future<List<Goal>> getAll() async => goals.values.toList();
  @override
  Future<void> put(Goal goal) async => goals[goal.id] = goal;
}

void main() {
  setUpAll(AppConfig.load);

  group('Agrégats NT-133', () {
    late DateTime now;
    late DetailedShootingSession detailed;
    late SimpleShootingSession simple;

    setUp(() {
      now = DateTime.now();
      detailed = DetailedShootingSession(
        id: 1,
        date: now.subtract(const Duration(days: 1)),
        weapon: 'Glock 17',
        caliber: '9mm',
        category: 'match',
        exercises: const ['precision'],
        series: [
          Series(
            shotCount: 5,
            distance: 25,
            points: 45,
            groupSize: 8,
          ),
        ],
      );
      simple = SimpleShootingSession(
        id: 2,
        date: now,
        weapon: 'Glock 17',
        caliber: 'calibre inconnu',
        shotCount: 30,
        distance: 25,
        category: 'entraînement',
        exercises: const ['vitesse'],
      );
    });

    test('inclut la libre dans assiduité mais pas dans les métriques de séries',
        () {
      final stats = StatsService([detailed, simple], now: now);

      expect(stats.sessionsCountCurrentMonth(), 2);
      expect(stats.categoryDistribution(), {'match': 1, 'entraînement': 1});
      expect(stats.averagePointsLast30Days(), 45);
      expect(stats.bestSeriesByPoints()?.points, 45);
      expect(stats.caliberDistribution().values.fold(0, (a, b) => a + b), 1);
    });

    test('additionne le volume direct dans le compteur NT-017', () {
      final weapon = Weapon(
        id: 'glock-17',
        name: 'Glock 17',
        createdAt: now,
      );
      final counts = DashboardService([detailed, simple])
          .generateWeaponShotCounts([weapon]);
      expect(counts[weapon.id], 35);
    });

    test('filtre catégorie et exercice sur les deux sous-types', () {
      expect(SessionFilters.byCategory([detailed, simple], 'entraînement'),
          [simple]);
      expect(
          SessionFilters.byExercise([detailed, simple], 'vitesse'), [simple]);
      expect(SessionFilters.byExercise([detailed, simple], 'precision'),
          [detailed]);
    });

    test('compte la libre dans les objectifs d’assiduité', () async {
      final goalRepo = _GoalRepo();
      final goal = Goal(
        title: 'Deux séances',
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 2,
      );
      await goalRepo.put(goal);
      final service = GoalService(
        sessionRepository: _SessionRepo([detailed, simple]),
        goalRepository: goalRepo,
      );

      await service.recomputeAllProgress();

      expect((await goalRepo.getAll()).single.lastMeasuredValue, 2);
    });

    test('compte la libre dans l’assiduité roulante sans fausser le score',
        () async {
      final snapshot =
          await RollingStatsService(_SessionRepo([detailed, simple])).compute();
      expect(snapshot.sessions30, 2);
      expect(snapshot.avg30, 45);
    });
  });
}
