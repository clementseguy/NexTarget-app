import '../data/local_db_hive.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import 'session_repository.dart';
import '../services/logger.dart';

/// Hive-backed implementation of [SessionRepository].
class HiveSessionRepository
    implements
        SessionRepository,
        StrictSessionRepository,
        AtomicSessionRepository {
  final LocalDatabaseHive _hive = LocalDatabaseHive();

  @override
  Future<void> clearAll() async {
    await _hive.clearAllSessions();
  }

  @override
  Future<void> delete(int id) async {
    await _hive.deleteSession(id);
  }

  @override
  Future<List<ShootingSession>> getAll() => _getAll(rethrowOnError: false);

  @override
  Future<List<ShootingSession>> getAllStrict() => _getAll(rethrowOnError: true);

  Future<List<ShootingSession>> _getAll({required bool rethrowOnError}) async {
    final raw = await _hive.getSessionsWithSeries(
      rethrowOnError: rethrowOnError,
    );
    return raw.map((e) {
      final sessionMap = e['session'];
      final seriesList = e['series'] as List<dynamic>? ?? [];
      final sessionMapFixed = Map<String, dynamic>.from(sessionMap as Map);
      // Les séries sont stockées séparément par Hive. Les réunir avant la
      // désérialisation permet au modèle de valider un brouillon complet.
      sessionMapFixed['series'] = seriesList;
      final session = ShootingSession.fromMap(sessionMapFixed);
      if (session is DetailedShootingSession) {
        session.series = seriesList
            .map((s) => Series.fromMap(
                  s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s),
                ))
            .toList();
      }
      return session;
    }).toList();
  }

  @override
  Future<int> insert(ShootingSession session) async {
    // Utiliser la nouvelle API qui retourne directement l'ID
    final series = session is DetailedShootingSession
        ? session.series.map((s) => s.toMap()).toList()
        : <Map<String, dynamic>>[];
    final key = await _hive.insertSession(session.toMap(), series);

    // Si key est null (erreur), retourner -1
    if (key == null) return -1;

    // Retourner directement la clé générée (plus besoin de relire toute la base)
    return key is int ? key : -1;
  }

  @override
  Future<List<int>> insertAll(List<ShootingSession> sessions) async {
    final entries = sessions.map((session) {
      final series = session is DetailedShootingSession
          ? session.series.map((item) => item.toMap()).toList()
          : <Map<String, dynamic>>[];
      return (session: session.toMap(), series: series);
    }).toList();
    return _hive.insertSessions(entries);
  }

  @override
  Future<bool> update(ShootingSession session,
      {bool preserveExistingSeriesIfEmpty = true}) async {
    final seriesMaps = session is DetailedShootingSession
        ? session.series.map((s) => s.toMap()).toList()
        : <Map<String, dynamic>>[];

    // Si on doit préserver les séries existantes et que la session n'a pas de séries
    if (session is DetailedShootingSession &&
        preserveExistingSeriesIfEmpty &&
        session.id != null &&
        seriesMaps.isEmpty) {
      try {
        final existing = await _hive.getSessionsWithSeries();
        final match = existing.firstWhere(
          (e) => (e['session']?['id'] == session.id),
          orElse: () => {},
        );

        if (match.isNotEmpty) {
          final existingSeries = (match['series'] as List<dynamic>? ?? [])
              .map((s) => (s is Map<String, dynamic>)
                  ? s
                  : Map<String, dynamic>.from(s))
              .toList();

          if (existingSeries.isNotEmpty) {
            final success =
                await _hive.updateSession(session.toMap(), existingSeries);
            if (!success) {
              throw StateError(
                  'Échec d\'écriture Hive (fallback séries) pour la session ${session.id}');
            }
            return true; // Si la mise à jour a réussi, c'est un fallback
          }
        }
      } catch (e) {
        AppLogger.I
            .error('Erreur lors de la récupération des séries existantes', e);
        // En cas d'erreur, on continue avec l'update normal
      }
    }

    final success = await _hive.updateSession(session.toMap(), seriesMaps);
    if (!success) {
      throw StateError('Échec d\'écriture Hive pour la session ${session.id}');
    }
    return false; // pas de fallback
  }
}
