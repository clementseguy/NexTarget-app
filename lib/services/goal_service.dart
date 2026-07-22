import '../models/goal.dart';
import '../models/series.dart';
import '../models/shooting_session.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../repositories/goal_repository.dart';
import '../interfaces/goal_service_interface.dart';

/// Lot B: objet valeur regroupant les stats macro pour l'écran Objectifs.
class MacroAchievementStats {
  final int totalCompleted;
  final int totalActive;
  final int completedLast7;
  final int completedLast30;
  final int completedLast60;
  final int completedLast90;
  const MacroAchievementStats({
    required this.totalCompleted,
    required this.totalActive,
    required this.completedLast7,
    required this.completedLast30,
    required this.completedLast60,
    required this.completedLast90,
  });
}

class GoalService implements IGoalService {
  final SessionRepository _sessions;
  final GoalRepository _goals;

  GoalService(
      {SessionRepository? sessionRepository, GoalRepository? goalRepository})
      : _sessions = sessionRepository ?? HiveSessionRepository(),
        _goals = goalRepository ?? HiveGoalRepository();

  @override
  Future<void> init() async {
    // Trigger box open via repository
    final list = await _goals.getAll();
    // Migration légère : attribuer des priorités séquentielles si absentes (>=9999)
    int idx = 0;
    for (final g in list) {
      if (g.priority >= 9999) {
        await _goals.put(g.copyWith(priority: idx));
      }
      idx++;
    }
  }

  @override
  Future<List<Goal>> listAll() => _goals.getAll();

  @override
  Future<void> addGoal(Goal goal) => _goals.put(goal);

  @override
  Future<void> updateGoal(Goal goal) => _goals.put(goal);

  @override
  Future<void> deleteGoal(String id) => _goals.delete(id);

  Future<void> recomputeAllProgress() async {
    final sessions = await _sessions.getAll();
    final goals = await _goals.getAll();
    for (final goal in goals) {
      final updated = _computeProgress(goal, sessions);
      await _goals.put(updated);
    }
  }

  // --- Lot A additions ---
  static const double kGoalDeltaNeutralEpsilon = 0.001;

  /// Returns active (non achieved, non archived, non failed) goals sorted by
  /// lastProgress desc then priority asc (tie-break) limited to n.
  @override
  Future<List<Goal>> topActiveGoals(int n) async {
    final all = await _goals.getAll();
    final filtered = all.where((g) => g.status == GoalStatus.active).toList();
    filtered.sort((a, b) {
      final pa = a.lastProgress ?? 0;
      final pb = b.lastProgress ?? 0;
      if (pb.compareTo(pa) != 0) return pb.compareTo(pa);
      return a.priority.compareTo(b.priority);
    });
    if (filtered.length <= n) return filtered;
    return filtered.sublist(0, n);
  }

  Future<int> countActiveGoals() async {
    final all = await _goals.getAll();
    return all.where((g) => g.status == GoalStatus.active).length;
  }

  Future<int> countAchievedGoals() async {
    final all = await _goals.getAll();
    return all.where((g) => g.status == GoalStatus.achieved).length;
  }

  /// Count goals achieved within the last [days] days (inclusive).
  Future<int> achievementsWithin(int days) async {
    if (days <= 0) return 0;
    final all = await _goals.getAll();
    final now = DateTime.now();
    final threshold = now.subtract(Duration(days: days));
    return all.where((g) {
      if (g.status != GoalStatus.achieved) return false;
      final d = g.achievementDate;
      if (d == null) return false;
      return !d.isBefore(threshold) && !d.isAfter(now);
    }).length;
  }

  /// --- Lot B additions ---
  /// Calcule toutes les stats macro en un seul passage sur la liste des objectifs.
  Future<MacroAchievementStats> macroAchievementStats() async {
    final all = await _goals.getAll();
    final now = DateTime.now();
    final t7 = now.subtract(const Duration(days: 7));
    final t30 = now.subtract(const Duration(days: 30));
    final t60 = now.subtract(const Duration(days: 60));
    final t90 = now.subtract(const Duration(days: 90));
    int totalCompleted = 0;
    int totalActive = 0;
    int c7 = 0;
    int c30 = 0;
    int c60 = 0;
    int c90 = 0;
    for (final g in all) {
      if (g.status == GoalStatus.achieved) {
        totalCompleted++;
        final d = g.achievementDate;
        if (d != null) {
          if (!d.isBefore(t7)) c7++;
          if (!d.isBefore(t30)) c30++;
          if (!d.isBefore(t60)) c60++;
          if (!d.isBefore(t90)) c90++;
        }
      } else if (g.status == GoalStatus.active) {
        totalActive++;
      }
    }
    return MacroAchievementStats(
      totalCompleted: totalCompleted,
      totalActive: totalActive,
      completedLast7: c7,
      completedLast30: c30,
      completedLast60: c60,
      completedLast90: c90,
    );
  }

  /// --- End Lot B additions ---
  // --- End Lot A additions ---

  Goal _computeProgress(Goal goal, List<ShootingSession> sessions) {
    // Filtrer selon la période si définie
    List<ShootingSession> filtered = sessions;
    // Conserver copie brute pour calcul tendance (période précédente)
    List<ShootingSession> previousSlice = const [];
    if (goal.period != GoalPeriod.none) {
      final now = DateTime.now();
      DateTime threshold;
      switch (goal.period) {
        case GoalPeriod.rollingWeek:
          threshold = now.subtract(const Duration(days: 7));
          break;
        case GoalPeriod.rollingMonth:
          threshold = now.subtract(const Duration(days: 30));
          break;
        case GoalPeriod.none:
          threshold = DateTime.fromMillisecondsSinceEpoch(0);
          break;
      }
      filtered = sessions.where((s) {
        final d = s.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return d.isAfter(threshold);
      }).toList();
      // Fenêtre précédente (même durée juste avant)
      final prevStart = goal.period == GoalPeriod.rollingWeek
          ? now.subtract(const Duration(days: 14))
          : now.subtract(const Duration(days: 60));
      final prevEnd = goal.period == GoalPeriod.rollingWeek
          ? now.subtract(const Duration(days: 7))
          : now.subtract(const Duration(days: 30));
      previousSlice = sessions.where((s) {
        final d = s.date ?? DateTime.fromMillisecondsSinceEpoch(0);
        return d.isAfter(prevStart) && d.isBefore(prevEnd);
      }).toList();
    }

    double? value;
    switch (goal.metric) {
      case GoalMetric.averagePoints:
        value = _averageScorePoints(filtered);
        break;
      case GoalMetric.sessionCount:
        value = filtered.length.toDouble();
        break;
      case GoalMetric.totalPoints:
        value = _totalScorePoints(filtered);
        break;
      case GoalMetric.groupSize:
        final allSeries = filtered.expand((s) => s.series);
        final groups = allSeries.map((s) => s.groupSize).toList();
        if (groups.isNotEmpty) {
          value = groups.reduce((a, b) => a + b) / groups.length;
        }
        break;
      case GoalMetric.averageSessionPoints:
        // Moyenne des points moyens par session (chaque session: somme points séries / nb séries)
        value = _averageSessionScorePoints(filtered);
        break;
      case GoalMetric.bestSeriesPoints:
        value = _bestSeriesScorePoints(filtered);
        break;
      case GoalMetric.bestSessionPoints:
        if (filtered.isNotEmpty) {
          value = _bestSessionScorePoints(filtered);
        }
        break;
      case GoalMetric.bestGroupSize:
        final allSeries2 = filtered.expand((s) => s.series).toList();
        if (allSeries2.isNotEmpty) {
          value = allSeries2
              .map((s) => s.groupSize)
              .reduce((a, b) => a < b ? a : b);
        }
        break;
    }

    double? progress;
    double? previousValue;
    if (previousSlice.isNotEmpty && goal.period != GoalPeriod.none) {
      previousValue = _computeMetricValue(goal.metric, previousSlice);
    }
    if (value != null) {
      switch (goal.comparator) {
        case GoalComparator.greaterOrEqual:
          progress = value / goal.targetValue;
          break;
        case GoalComparator.lessOrEqual:
          progress = goal.targetValue == 0 ? 0 : goal.targetValue / value;
          break;
      }
      if (progress.isNaN || progress.isInfinite) {
        progress = 0;
      }
      progress = progress.clamp(0, 1);
    }

    var status = goal.status;
    DateTime? achievementDate = goal.achievementDate;
    if (progress != null) {
      final achieved = (goal.comparator == GoalComparator.greaterOrEqual &&
              value! >= goal.targetValue) ||
          (goal.comparator == GoalComparator.lessOrEqual &&
              value! <= goal.targetValue);
      if (achieved && status == GoalStatus.active) {
        status = GoalStatus.achieved;
        achievementDate ??= DateTime.now();
      }
    }

    double? delta;
    if (value != null && previousValue != null) {
      // Pour les métriques où plus grand est mieux (greaterOrEqual) delta = value - previous.
      // Pour les métriques où plus petit est mieux (lessOrEqual) delta = previous - value (donc positif si amélioration).
      if (goal.comparator == GoalComparator.greaterOrEqual) {
        delta = value - previousValue;
      } else {
        delta = previousValue - value;
      }
    }
    return goal.copyWith(
      lastProgress: progress ?? goal.lastProgress,
      lastMeasuredValue: value ?? goal.lastMeasuredValue,
      status: status,
      achievementDate: achievementDate,
      previousMeasuredValue: previousValue ?? goal.previousMeasuredValue,
      improvementDelta: delta ?? goal.improvementDelta,
    );
  }

  double? _computeMetricValue(
      GoalMetric metric, List<ShootingSession> sessions) {
    if (sessions.isEmpty) return null;
    switch (metric) {
      case GoalMetric.averagePoints:
        return _averageScorePoints(sessions);
      case GoalMetric.sessionCount:
        return sessions.length.toDouble();
      case GoalMetric.totalPoints:
        return _totalScorePoints(sessions);
      case GoalMetric.groupSize:
        final allSeries = sessions.expand((s) => s.series);
        final groups = allSeries.map((s) => s.groupSize).toList();
        if (groups.isNotEmpty) {
          return groups.reduce((a, b) => a + b) / groups.length;
        }
        return null;
      case GoalMetric.averageSessionPoints:
        return _averageSessionScorePoints(sessions);
      case GoalMetric.bestSeriesPoints:
        return _bestSeriesScorePoints(sessions);
      case GoalMetric.bestSessionPoints:
        return _bestSessionScorePoints(sessions);
      case GoalMetric.bestGroupSize:
        final allSeries2 = sessions.expand((s) => s.series).toList();
        if (allSeries2.isNotEmpty) {
          return allSeries2
              .map((s) => s.groupSize)
              .reduce((a, b) => a < b ? a : b);
        }
        return null;
    }
  }

  Iterable<Series> _scoreSeries(List<ShootingSession> sessions) {
    return sessions.expand((s) => s.series).where((s) => s.isScoreCounted);
  }

  double? _averageScorePoints(List<ShootingSession> sessions) {
    final points =
        _scoreSeries(sessions).map((s) => s.scoredPoints.toDouble()).toList();
    if (points.isEmpty) return null;
    return points.reduce((a, b) => a + b) / points.length;
  }

  double _totalScorePoints(List<ShootingSession> sessions) {
    final points =
        _scoreSeries(sessions).map((s) => s.scoredPoints.toDouble()).toList();
    return points.isEmpty ? 0 : points.reduce((a, b) => a + b);
  }

  double? _averageSessionScorePoints(List<ShootingSession> sessions) {
    double sum = 0;
    int count = 0;
    for (final session in sessions) {
      final scoreSeries =
          session.series.where((s) => s.isScoreCounted).toList();
      if (scoreSeries.isEmpty) continue;
      final pts = scoreSeries
          .map((s) => s.scoredPoints.toDouble())
          .reduce((a, b) => a + b);
      sum += pts / scoreSeries.length;
      count++;
    }
    return count > 0 ? sum / count : null;
  }

  double? _bestSeriesScorePoints(List<ShootingSession> sessions) {
    final points =
        _scoreSeries(sessions).map((s) => s.scoredPoints.toDouble()).toList();
    if (points.isEmpty) return null;
    return points.reduce((a, b) => a > b ? a : b);
  }

  double _bestSessionScorePoints(List<ShootingSession> sessions) {
    double best = 0;
    for (final session in sessions) {
      final scoreSeries =
          session.series.where((s) => s.isScoreCounted).toList();
      if (scoreSeries.isEmpty) continue;
      final total = scoreSeries
          .map((s) => s.scoredPoints.toDouble())
          .reduce((a, b) => a + b);
      if (total > best) best = total;
    }
    return best;
  }
}
