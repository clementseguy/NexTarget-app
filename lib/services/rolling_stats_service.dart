import '../repositories/session_repository.dart';
import '../utils/session_filters.dart';
import '../interfaces/rolling_stats_service_interface.dart';
import '../models/shooting_session.dart';
import 'stats_contract.dart';
import 'logger.dart';

/// Statistique legacy de total moyen par session sur 30 j et 60 j.
///
/// Elle n'alimente pas le comparatif dashboard NT-014, calculé par série dans
/// [DashboardService].
class RollingStatsService implements IRollingStatsService {
  final SessionRepository _repo;
  RollingStatsService(this._repo);

  @override
  Future<RollingStatsSnapshot> compute() async {
    final sessions = SessionFilters.realizedWithDate(await _repo.getAll());
    if (sessions.isEmpty) {
      return const RollingStatsSnapshot(
        avg30: 0,
        avg60: 0,
        delta: 0,
        sessions30: 0,
        sessions60: 0,
      );
    }
    final now = DateTime.now();
    final limit30 = now.subtract(const Duration(days: 30));
    final limit60 = now.subtract(const Duration(days: 60));

    final stats30 = _computeWindow(sessions, limit30);
    final stats60 = _computeWindow(sessions, limit60);
    final avg60 = stats60.average;
    final avg30 = stats30.average;
    final double delta = avg30 - avg60;

    AppLogger.I.debug(
        'Rolling stats: avg30=$avg30 avg60=$avg60 delta=$delta sessions30=${stats30.sessionCount} sessions60=${stats60.sessionCount}');

    return RollingStatsSnapshot(
      avg30: avg30.toDouble(),
      avg60: avg60.toDouble(),
      delta: delta.toDouble(),
      sessions30: stats30.sessionCount,
      sessions60: stats60.sessionCount,
    );
  }

  _WindowStats _computeWindow(
    List<ShootingSession> sessions,
    DateTime limit,
  ) {
    final inWindow = sessions.where((session) => session.date!.isAfter(limit));
    final detailed = inWindow.whereType<DetailedShootingSession>().toList();
    final total = detailed.fold<double>(
      0,
      (sum, session) =>
          sum +
          session.series.fold<int>(0, (value, item) => value + item.points),
    );
    return _WindowStats(
      sessionCount: inWindow.length,
      average: detailed.isEmpty ? 0 : total / detailed.length,
    );
  }
}

class _WindowStats {
  final int sessionCount;
  final double average;

  const _WindowStats({required this.sessionCount, required this.average});
}
