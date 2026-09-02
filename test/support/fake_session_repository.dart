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

  // Jamais réutilisé, y compris après suppression : imite les clés Hive
  // (`Box.add`), qui ne sont jamais recyclées.
  int _nextId = 1;

  @override
  Future<void> clearAll() async => sessions.clear();

  @override
  Future<void> delete(int id) async => sessions.removeWhere((s) => s.id == id);

  @override
  Future<List<ShootingSession>> getAll() async =>
      sessions.map((s) => ShootingSession.fromMap(s.toMap())).toList();

  @override
  Future<int> insert(ShootingSession session) async {
    final id = _nextId++;
    session.id = id;
    // Clone avant stockage : HiveSessionRepository ne conserve qu'un snapshot
    // (session.toMap()), jamais l'instance de l'appelant.
    sessions.add(ShootingSession.fromMap(session.toMap()));
    return id;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    updateCallCount++;
    if (failOnUpdateCallNumber != null && updateCallCount == failOnUpdateCallNumber) {
      throw StateError('Échec simulé de mise à jour de session (FakeSessionRepository)');
    }
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx == -1) return false;

    // Comme HiveSessionRepository : si la session fournie n'a pas de série et
    // qu'on doit préserver l'existant, on conserve les séries déjà stockées
    // et on signale le fallback en retournant true.
    if (preserveExistingSeriesIfEmpty && session.series.isEmpty && sessions[idx].series.isNotEmpty) {
      session.series = sessions[idx].series;
      sessions[idx] = ShootingSession.fromMap(session.toMap());
      return true;
    }

    sessions[idx] = ShootingSession.fromMap(session.toMap());
    return false;
  }
}
