import '../models/shooting_session.dart';
import '../constants/session_constants.dart';

/// Centralized filters for sessions used by stats across the app (Lot C - F24).
class SessionFilters {
  /// Keep only realized sessions that have a date.
  static List<ShootingSession> realizedWithDate(Iterable<ShootingSession> sessions) {
    return sessions
        .where((s) => s.status == SessionConstants.statusRealisee && s.date != null)
        .toList();
  }

  /// Keep only sessions on which the given exercise was worked (NT-007).
  ///
  /// If [exerciseId] is null, no filtering is applied and every session is
  /// returned unchanged (this represents the "all exercises" selection).
  static List<ShootingSession> byExercise(Iterable<ShootingSession> sessions, String? exerciseId) {
    if (exerciseId == null) return sessions.toList();
    return sessions.where((s) => s.exercises.contains(exerciseId)).toList();
  }
}
