import '../models/shooting_session.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../interfaces/session_service_interface.dart';
import '../interfaces/session_photo_service_interface.dart';
import 'logger.dart';
import '../models/exercise.dart';
import '../models/series.dart';
import 'session_photo_service.dart';

class SessionService implements ISessionService {
  final SessionRepository _repo;
  final ISessionPhotoService _photoService;

  SessionService({SessionRepository? repository, ISessionPhotoService? photoService})
      : _repo = repository ?? HiveSessionRepository(),
        _photoService = photoService ?? SessionPhotoService();

  @override
  Future<List<ShootingSession>> getAllSessions() async {
    return _repo.getAll();
  }

  @override
  Future<void> addSession(ShootingSession session) async {
    final id = await _repo.insert(session);
    if (id >= 0) {
      session.id = id;
    }
  }

  @override
  Future<void> updateSession(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
    bool warnOnFallback = true,
  }) async {
    // Capture l'ancienne photo (si existante) avant écrasement, pour pouvoir nettoyer
    // le fichier local si elle a été remplacée ou supprimée par cette mise à jour.
    final previousPhotoPath = await _findPhotoPath(session.id);
    final fallback = await _repo.update(
      session,
      preserveExistingSeriesIfEmpty: preserveExistingSeriesIfEmpty,
    );
    if (fallback && warnOnFallback) {
      AppLogger.I.warn('Session ${session.id} update used fallback (empty series ignored).');
    }
    if (previousPhotoPath != null && previousPhotoPath != session.photoPath) {
      await _photoService.deleteIfExists(previousPhotoPath);
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    final photoPath = await _findPhotoPath(id);
    await _repo.delete(id);
    if (photoPath != null) {
      await _photoService.deleteIfExists(photoPath);
    }
  }

  @override
  Future<void> clearAllSessions() async {
    AppLogger.I.debug('Clearing all sessions');
    try {
      final all = await _repo.getAll();
      for (final s in all) {
        if (s.hasPhoto) await _photoService.deleteIfExists(s.photoPath);
      }
    } catch (e) {
      AppLogger.I.error('Erreur lors du nettoyage des photos avant purge des sessions', e);
    }
    await _repo.clearAll();
  }

  /// Récupère le photoPath actuellement persisté pour la session [sessionId], si connu.
  Future<String?> _findPhotoPath(int? sessionId) async {
    if (sessionId == null) return null;
    try {
      final all = await _repo.getAll();
      final match = all.where((s) => s.id == sessionId);
      return match.isEmpty ? null : match.first.photoPath;
    } catch (e) {
      AppLogger.I.error('Erreur lors de la récupération de la photo existante', e);
      return null;
    }
  }

  /// Convert a planned session (status 'prévue') into a realized one.
  /// Applies provided field overrides, forces date to now if not supplied.
  @override
  Future<ShootingSession> convertPlannedToRealized({
    required ShootingSession session,
    String? weapon,
    String? caliber,
    String? category,
    String? synthese,
    DateTime? forcedDate,
    List<Series>? updatedSeries,
  }) async {
    if (session.status != 'prévue') {
      throw StateError('Session ${session.id} is not planned.');
    }
    // Apply overrides in-memory
    if (weapon != null) session.weapon = weapon;
    if (caliber != null) session.caliber = caliber;
    if (category != null) session.category = category;
    if (synthese != null) session.synthese = synthese;
    if (updatedSeries != null) {
      session.series = updatedSeries;
    }
    session.status = 'réalisée';
    session.date = forcedDate ?? DateTime.now();
    await updateSession(session, preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
    return session;
  }

  /// Persist a single series change in a planned session before final conversion.
  @override
  Future<void> updateSingleSeries(ShootingSession session, int seriesIndex, Series newSeries) async {
    if (seriesIndex < 0 || seriesIndex >= session.series.length) return;
    session.series[seriesIndex] = newSeries;
    // Keep status as is (likely 'prévue') during incremental updates
    await updateSession(session, preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
  }

  /// Create a planned session from an Exercise definition.
  /// One empty Series is generated per consigne (or single if none).
  @override
  Future<ShootingSession> planFromExercise(Exercise exercise) async {
    if (exercise.type != ExerciseType.stand) {
      throw StateError('Seuls les exercices de type Stand peuvent être planifiés.');
    }
    final List<Series> series = [];
    final steps = exercise.consignes;
    if (steps.isEmpty) {
      series.add(Series(distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: '')); // placeholder minimal série
    } else {
      for (final step in steps) {
        series.add(Series(distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: step));
      }
    }
    final session = ShootingSession(
      weapon: '',
      caliber: '',
      date: null,
      status: 'prévue',
      series: series,
      exercises: [exercise.id],
      category: 'entraînement',
      synthese: 'Session créée à partir de ${exercise.name}',
    );
    await addSession(session);
    // Récupération post-insertion pour garantir séries présentes et id assigné
    try {
      final all = await getAllSessions();
      final match = all.where((s)=> s.exercises.contains(exercise.id)).toList();
      if (match.isNotEmpty) {
        // On choisit la plus récente (souvent la dernière insérée)
        match.sort((a,b)=> (b.id ?? 0).compareTo(a.id ?? 0));
        return match.first;
      }
    } catch (_) {}
    return session;
  }
}
