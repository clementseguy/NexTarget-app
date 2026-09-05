import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../interfaces/session_service_interface.dart';
import '../interfaces/session_photo_service_interface.dart';
import 'logger.dart';
import '../models/exercise.dart';
import '../models/series.dart';
import 'preferences_service.dart';
import 'session_photo_service.dart';

class SessionService implements ISessionService {
  final SessionRepository _repo;
  final ISessionPhotoService _photoService;
  final PreferencesService _preferencesService;

  SessionService({
    SessionRepository? repository,
    ISessionPhotoService? photoService,
    PreferencesService? preferencesService,
  })  : _repo = repository ?? HiveSessionRepository(),
        _photoService = photoService ?? SessionPhotoService(),
        _preferencesService = preferencesService ?? PreferencesService();

  @override
  Future<List<ShootingSession>> getAllSessions() async {
    return _repo.getAll();
  }

  @override
  Future<void> addSession(ShootingSession session) async {
    _validateSession(session);
    final id = await _repo.insert(session);
    if (id < 0) throw StateError('Échec de l’écriture de la session.');
    session.id = id;
  }

  SessionDuplicationDraft prepareDuplication(ShootingSession source) {
    if (source is DetailedShootingSession && source.isDraft) {
      throw StateError('Un brouillon guidé ne peut pas être dupliqué.');
    }
    final sourceSnapshot = ShootingSession.fromMap(source.toMap());
    final sessionMap = Map<String, dynamic>.from(sourceSnapshot.toMap())
      ..['id'] = null
      ..['date'] = null;
    final series = sourceSnapshot is DetailedShootingSession
        ? sourceSnapshot.series
            .map((item) => Map<String, dynamic>.from(item.toMap()))
            .toList()
        : <Map<String, dynamic>>[];
    sessionMap['exercises'] = List<String>.from(sourceSnapshot.exercises);
    return SessionDuplicationDraft(
      source: sourceSnapshot,
      initialSessionData: {'session': sessionMap, 'series': series},
    );
  }

  Future<ShootingSession> saveDuplication({
    required SessionDuplicationDraft draft,
    required ShootingSession editedCopy,
  }) async {
    if (draft.source is DetailedShootingSession &&
        (draft.source as DetailedShootingSession).isDraft) {
      throw StateError('Un brouillon guidé ne peut pas être dupliqué.');
    }
    final copyMap = Map<String, dynamic>.from(editedCopy.toMap())
      ..['id'] = null;
    final copy = ShootingSession.fromMap(copyMap);
    if (copy.status == SessionConstants.statusRealisee && copy.date == null) {
      throw ArgumentError(
        'Une nouvelle date est obligatoire pour dupliquer une session réalisée.',
      );
    }
    final sourcePhotoPath = draft.source.photoPath;
    final submittedPhotoPath = copy.photoPath;
    String? createdPhotoPath;
    try {
      if (sourcePhotoPath != null &&
          sourcePhotoPath.trim().isNotEmpty &&
          submittedPhotoPath == sourcePhotoPath) {
        createdPhotoPath =
            await _photoService.duplicateStoredPhoto(sourcePhotoPath);
        copy.photoPath = createdPhotoPath;
      }
      await addSession(copy);
      editedCopy.id = copy.id;
      editedCopy.photoPath = copy.photoPath;
      return copy;
    } catch (_) {
      if (createdPhotoPath != null) {
        await _photoService.deleteIfExists(createdPhotoPath);
      }
      editedCopy.id = null;
      editedCopy.photoPath = submittedPhotoPath;
      rethrow;
    }
  }

  Future<void> addSessionsAtomically(List<ShootingSession> sessions) async {
    if (_repo is! AtomicSessionRepository) {
      throw StateError(
          'Le repository ne prend pas en charge l’import atomique.');
    }
    final incomingDrafts = sessions
        .whereType<DetailedShootingSession>()
        .where((session) => session.status == SessionConstants.statusDraft)
        .toList();
    for (final draft in incomingDrafts) {
      _validateSession(draft);
    }
    final incomingDraftCount = incomingDrafts.length;
    if (incomingDraftCount > 0) {
      final existingDraftCount = (await getGuidedDrafts()).length;
      if (incomingDraftCount + existingDraftCount > 1) {
        throw StateError(
          'L’import créerait plusieurs séances en cours. Abandonnez ou '
          'terminez le brouillon existant avant de réessayer.',
        );
      }
    }
    final ids = await (_repo as AtomicSessionRepository).insertAll(sessions);
    if (ids.length != sessions.length) {
      throw StateError('Import incomplet des sessions.');
    }
    for (var index = 0; index < sessions.length; index++) {
      sessions[index].id = ids[index];
    }
  }

  @override
  Future<void> updateSession(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
    bool warnOnFallback = true,
  }) async {
    _validateSession(session);
    // Capture l'ancienne photo (si existante) avant écrasement, pour pouvoir nettoyer
    // le fichier local si elle a été remplacée ou supprimée par cette mise à jour.
    final previousPhotoPath = await _findPhotoPath(session.id);
    final fallback = await _repo.update(
      session,
      preserveExistingSeriesIfEmpty: preserveExistingSeriesIfEmpty,
    );
    if (fallback && warnOnFallback) {
      AppLogger.I.warn(
          'Session ${session.id} update used fallback (empty series ignored).');
    }
    if (previousPhotoPath != null && previousPhotoPath != session.photoPath) {
      await _photoService.deleteIfExists(previousPhotoPath);
    }
  }

  void _validateSession(ShootingSession session) {
    if (session is SimpleShootingSession) {
      session.validate();
      return;
    }
    final detailed = session as DetailedShootingSession;
    if (!SessionConstants.detailedStatuses.contains(detailed.status)) {
      throw ArgumentError('État de session détaillée inconnu.');
    }
    if (detailed.status == SessionConstants.statusDraft &&
        (detailed.date == null ||
            detailed.weapon.trim().isEmpty ||
            detailed.caliber.trim().isEmpty ||
            !SessionConstants.categories.contains(detailed.category) ||
            detailed.series.isEmpty)) {
      throw ArgumentError('Brouillon de séance guidée invalide.');
    }
    for (final series in detailed.series) {
      if (detailed.status == SessionConstants.statusDraft &&
          !series.isCompleted) {
        continue;
      }
      if (series.distance <= 0 ||
          series.distance != series.distance.truncateToDouble()) {
        throw ArgumentError(
          'La distance doit être un entier strictement positif.',
        );
      }
      if (detailed.status == SessionConstants.statusDraft) {
        if (series.shotCount <= 0) {
          throw ArgumentError(
            'Le nombre de coups doit être strictement positif.',
          );
        }
        if (series.points < 0) {
          throw ArgumentError('Le score ne peut pas être négatif.');
        }
        if (!series.isScoreEntered) {
          throw ArgumentError('Le score est obligatoire.');
        }
        if (series.groupSize <= 0) {
          throw ArgumentError('Le groupement doit être strictement positif.');
        }
      }
    }
  }

  @override
  Future<DetailedShootingSession> createGuidedDraft({
    required DateTime date,
    required String weapon,
    required String caliber,
    required String category,
    required List<String> exercises,
    required int seriesCount,
    required int shotsPerSeries,
    required int initialDistance,
    required HandMethod initialHandMethod,
  }) async {
    if ((await getGuidedDrafts()).isNotEmpty) {
      throw StateError(
        'Une séance est déjà en cours. Reprenez-la ou abandonnez-la avant '
        'd’en commencer une nouvelle.',
      );
    }
    if (weapon.trim().isEmpty) {
      throw ArgumentError('L’arme est obligatoire.');
    }
    if (caliber.trim().isEmpty) {
      throw ArgumentError('Le calibre est obligatoire.');
    }
    if (!SessionConstants.categories.contains(category)) {
      throw ArgumentError('Catégorie de session inconnue.');
    }
    if (seriesCount <= 0) {
      throw ArgumentError('Le nombre de séries doit être strictement positif.');
    }
    if (shotsPerSeries <= 0) {
      throw ArgumentError('Le nombre de coups doit être strictement positif.');
    }
    if (initialDistance <= 0) {
      throw ArgumentError('La distance doit être strictement positive.');
    }
    final draft = DetailedShootingSession(
      date: date,
      weapon: weapon.trim(),
      caliber: caliber.trim(),
      status: SessionConstants.statusDraft,
      category: category,
      exercises: List<String>.from(exercises),
      series: List.generate(
        seriesCount,
        (_) => Series(
          shotCount: shotsPerSeries,
          distance: initialDistance.toDouble(),
          points: 0,
          groupSize: 0,
          handMethod: initialHandMethod,
          isCompleted: false,
          isDraftStarted: false,
          isScoreEntered: false,
        ),
      ),
    );
    await addSession(draft);
    return draft;
  }

  @override
  Future<List<DetailedShootingSession>> getGuidedDrafts() async {
    final drafts = (await _repo.getAll())
        .whereType<DetailedShootingSession>()
        .where((session) => session.status == SessionConstants.statusDraft)
        .toList();
    drafts.sort((a, b) {
      final dateOrder =
          (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970));
      return dateOrder != 0 ? dateOrder : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return drafts;
  }

  @override
  Future<DetailedShootingSession> saveGuidedDraft(
    DetailedShootingSession draft,
  ) async {
    if (draft.id == null || draft.status != SessionConstants.statusDraft) {
      throw StateError('La séance n’est pas un brouillon persistant.');
    }
    final snapshot = DetailedShootingSession.fromMap(draft.toMap());
    await updateSession(
      snapshot,
      preserveExistingSeriesIfEmpty: false,
      warnOnFallback: false,
    );
    return snapshot;
  }

  @override
  Future<DetailedShootingSession> completeGuidedDraft(
    DetailedShootingSession draft,
  ) async {
    if (draft.id == null || draft.status != SessionConstants.statusDraft) {
      throw StateError('La séance n’est pas un brouillon persistant.');
    }
    final completedSeries = draft.series
        .where((series) => series.isCompleted)
        .map((series) => Series.fromMap(series.toMap()))
        .toList();
    if (completedSeries.isEmpty) {
      throw StateError('Au moins une série doit être enregistrée.');
    }
    for (final series in completedSeries) {
      _validateCompletedGuidedSeries(series);
    }
    final realized = DetailedShootingSession.fromMap(draft.toMap())
      ..status = SessionConstants.statusRealisee
      ..series = completedSeries;
    await updateSession(
      realized,
      preserveExistingSeriesIfEmpty: false,
      warnOnFallback: false,
    );
    return realized;
  }

  void _validateCompletedGuidedSeries(Series series) {
    if (series.shotCount <= 0) {
      throw ArgumentError('Le nombre de coups doit être strictement positif.');
    }
    if (series.distance <= 0 ||
        series.distance != series.distance.truncateToDouble()) {
      throw ArgumentError(
          'La distance doit être un entier strictement positif.');
    }
    if (series.points < 0) {
      throw ArgumentError('Le score ne peut pas être négatif.');
    }
    if (!series.isScoreEntered) {
      throw ArgumentError('Le score est obligatoire.');
    }
    if (series.groupSize <= 0) {
      throw ArgumentError('Le groupement doit être strictement positif.');
    }
  }

  @override
  Future<void> abandonGuidedDraft(DetailedShootingSession draft) async {
    if (draft.id == null || draft.status != SessionConstants.statusDraft) {
      throw StateError('La séance n’est pas un brouillon persistant.');
    }
    await deleteSession(draft.id!);
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
      AppLogger.I.error(
          'Erreur lors du nettoyage des photos avant purge des sessions', e);
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
      AppLogger.I
          .error('Erreur lors de la récupération de la photo existante', e);
      return null;
    }
  }

  /// Convert a planned session (status 'prévue') into a realized one.
  /// Applies provided field overrides, forces date to now if not supplied.
  @override
  Future<DetailedShootingSession> convertPlannedToRealized({
    required DetailedShootingSession session,
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
    await updateSession(session,
        preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
    return session;
  }

  /// Persist a single series change in a planned session before final conversion.
  @override
  Future<void> updateSingleSeries(DetailedShootingSession session,
      int seriesIndex, Series newSeries) async {
    if (seriesIndex < 0 || seriesIndex >= session.series.length) return;
    session.series[seriesIndex] = newSeries;
    // Keep status as is (likely 'prévue') during incremental updates
    await updateSession(session,
        preserveExistingSeriesIfEmpty: false, warnOnFallback: false);
  }

  /// Create a planned session from an Exercise definition.
  /// One empty Series is generated per consigne (or single if none).
  @override
  Future<DetailedShootingSession> planFromExercise(Exercise exercise) async {
    if (exercise.type != ExerciseType.stand) {
      throw StateError(
          'Seuls les exercices de type Stand peuvent être planifiés.');
    }
    final List<Series> series = [];
    final steps = exercise.consignes;
    if (steps.isEmpty) {
      series.add(Series(
          distance: 1,
          points: 0,
          groupSize: 0,
          shotCount: 1,
          comment: '')); // placeholder minimal série
    } else {
      for (final step in steps) {
        series.add(Series(
            distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: step));
      }
    }
    final session = DetailedShootingSession(
      weapon: '',
      caliber: _preferencesService.getDefaultCaliber() ?? '',
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
      final match =
          all.where((s) => s.exercises.contains(exercise.id)).toList();
      if (match.isNotEmpty && match.first is DetailedShootingSession) {
        // On choisit la plus récente (souvent la dernière insérée)
        match.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        return match.first as DetailedShootingSession;
      }
    } catch (_) {}
    return session;
  }
}

class SessionDuplicationDraft {
  final ShootingSession source;
  final Map<String, dynamic> initialSessionData;

  const SessionDuplicationDraft({
    required this.source,
    required this.initialSessionData,
  });

  bool get isSimple => source is SimpleShootingSession;
}
