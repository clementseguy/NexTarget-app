import '../models/shooting_session.dart';

/// Abstraction layer for session persistence.
abstract class SessionRepository {
  Future<List<ShootingSession>> getAll();
  Future<int> insert(ShootingSession session);

  /// Returns true if a fallback (preserving existing series) was applied instead of provided empty list.
  Future<bool> update(ShootingSession session,
      {bool preserveExistingSeriesIfEmpty = true});
  Future<void> delete(int id);
  Future<void> clearAll();
}

/// Capacité optionnelle d'un repository à garantir qu'une erreur de lecture
/// est propagée au lieu d'être convertie en liste vide.
abstract class StrictSessionRepository {
  Future<List<ShootingSession>> getAllStrict();
}

abstract class AtomicSessionRepository {
  Future<List<int>> insertAll(List<ShootingSession> sessions);
}
