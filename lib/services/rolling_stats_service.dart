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

    double sum30 = 0;
    double sum60 = 0;
    int count30 = 0;
    int count60 = 0;
    int detailedCount30 = 0;
    int detailedCount60 = 0;

    for (final s in sessions) {
      final d = s.date;
      if (d == null) continue;
      if (d.isAfter(limit60)) {
        count60++;
        if (d.isAfter(limit30)) {
          count30++;
        }
        if (s is DetailedShootingSession) {
          final totalPoints = s.series.fold<int>(0, (acc, e) => acc + e.points);
          sum60 += totalPoints.toDouble();
          detailedCount60++;
          if (d.isAfter(limit30)) {
            sum30 += totalPoints.toDouble();
            detailedCount30++;
          }
        }
      }
    }

    final double avg60 = detailedCount60 == 0 ? 0 : (sum60 / detailedCount60);
    final double avg30 = detailedCount30 == 0 ? 0 : (sum30 / detailedCount30);
    final double delta = avg30 - avg60;

    AppLogger.I.debug(
        'Rolling stats: avg30=$avg30 avg60=$avg60 delta=$delta sessions30=$count30 sessions60=$count60');

    return RollingStatsSnapshot(
      avg30: avg30.toDouble(),
      avg60: avg60.toDouble(),
      delta: delta.toDouble(),
      sessions30: count30,
      sessions60: count60,
    );
  }
}
