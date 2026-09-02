import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/session_repository.dart';

/// Fake en mémoire de [SessionRepository] pour les tests (NT-058).
///
/// IMPORTANT : [getAll] clone chaque session (comme le fait
/// `HiveSessionRepository`, qui reconstruit toujours des objets frais depuis
/// les maps sérialisées). Ne jamais revenir à un simple `List.of(sessions)` :
/// `ShootingSession` est mutable, et partager les références permettrait à
/// une mutation en mémoire (ex. `session.weapon = ...`) de « persister »
/// silencieusement même si l'écriture (`update`) échoue ensuite — bug réel
/// rencontré lors du développement de NT-008 (rollback du renommage d'arme).
class FakeSessionRepository implements SessionRepository {
  final List<ShootingSession> sessions = [];
  int updateCallCount = 0;

  /// 1-based : simule l'échec de la Nième mise à jour (utile pour tester un rollback).
  int? failOnUpdateCallNumber;

  @override
  Future<void> clearAll() async => sessions.clear();

  @override
  Future<void> delete(int id) async => sessions.removeWhere((s) => s.id == id);

  @override
  Future<List<ShootingSession>> getAll() async =>
      sessions.map((s) => ShootingSession.fromMap(s.toMap())).toList();

  @override
  Future<int> insert(ShootingSession session) async {
    final id = sessions.length + 1;
    session.id = id;
    sessions.add(session);
    return id;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    updateCallCount++;
    if (failOnUpdateCallNumber != null && updateCallCount == failOnUpdateCallNumber) {
      throw StateError('Échec simulé de mise à jour de session (FakeSessionRepository)');
    }
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) sessions[idx] = session;
    return false;
  }
}
