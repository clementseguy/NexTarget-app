import 'dart:math';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../repositories/session_repository.dart';

/// High-level operations for exercises (sorting, id generation).
class ExerciseService {
  final ExerciseRepository _repo;
  final SessionRepository _sessionRepository;
  ExerciseService({
    ExerciseRepository? repository,
    SessionRepository? sessionRepository,
  })  : _repo = repository ?? HiveExerciseRepository(),
        _sessionRepository = sessionRepository ?? HiveSessionRepository();

  /// Generate a short unique id: base36 timestamp + random suffix.
  String generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 20).toRadixString(36);
    return '${ts}_$rnd';
  }

  Future<List<Exercise>> listAll() => _repo.getAll();

  Future<void> addExercise({
    required String name,
    required dynamic category, // accepts ExerciseCategory or legacy String
    ExerciseType type = ExerciseType.stand,
    String? description,
    int priority = 9999,
    List<String>? goalIds,
    int? durationMinutes,
    String? equipment,
    List<String>? consignes,
  }) async {
    final ExerciseCategory catEnum = category is ExerciseCategory
        ? category
        : parseExerciseCategory(category.toString());
    final ex = Exercise(
      id: generateId(),
      name: name.trim(),
      categoryEnum: catEnum,
      type: type,
      description:
          (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      createdAt: DateTime.now(),
      priority: priority,
      goalIds: goalIds ?? const [],
      durationMinutes: durationMinutes,
      equipment: (equipment?.trim().isEmpty ?? true) ? null : equipment!.trim(),
      consignes:
          consignes?.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );
    await createExercise(ex);
  }

  Future<void> createExercise(Exercise exercise) async {
    final snapshot = Exercise.fromMap(exercise.toMap());
    await _repo.put(snapshot);
  }

  Exercise prepareDuplication(Exercise source) => Exercise(
        id: generateId(),
        name: '${source.name} (copie)',
        categoryEnum: source.categoryEnum,
        type: source.type,
        description: source.description,
        durationMinutes: source.durationMinutes,
        equipment: source.equipment,
        createdAt: DateTime.now(),
        priority: 9999,
        goalIds: List<String>.from(source.goalIds),
        consignes: List<String>.from(source.consignes),
      );

  /// Backward compatibility helper (accept legacy string category names).
  // Legacy alias kept temporarily (now redundant since addExercise handles strings)
  Future<void> addExerciseLegacy({
    required String name,
    required String category,
    ExerciseType type = ExerciseType.stand,
    String? description,
    int priority = 9999,
    List<String>? goalIds,
    int? durationMinutes,
    String? equipment,
    List<String>? consignes,
  }) =>
      addExercise(
        name: name,
        category: category,
        type: type,
        description: description,
        priority: priority,
        goalIds: goalIds,
        durationMinutes: durationMinutes,
        equipment: equipment,
        consignes: consignes,
      );

  Future<void> updateExercise(Exercise exercise) => _repo.put(exercise);

  Future<ExerciseDeletionEligibility> checkDeletionEligibility(
      String id) async {
    final repository = _sessionRepository;
    final sessions = repository is StrictSessionRepository
        ? await (repository as StrictSessionRepository).getAllStrict()
        : await repository.getAll();
    final linkedCount =
        sessions.where((session) => session.exercises.contains(id)).length;
    return ExerciseDeletionEligibility(linkedSessionCount: linkedCount);
  }

  Future<void> deleteExercise(String id) async {
    final eligibility = await checkDeletionEligibility(id);
    if (!eligibility.canDelete) {
      throw ExerciseLinkedSessionsException(eligibility.linkedSessionCount);
    }
    await _repo.delete(id);
  }

  Future<void> reorder(List<Exercise> ordered) async {
    int idx = 0;
    for (final ex in ordered) {
      await _repo.put(ex.copyWith(priority: idx++));
    }
  }

  Future<void> clearAll() => _repo.clear();

  /// Replace goal associations for an exercise.
  Future<void> setGoals(Exercise exercise, List<String> goalIds) async {
    final distinct = goalIds.toSet().toList();
    await _repo.put(exercise.copyWith(goalIds: distinct));
  }

  /// Replace consignes (steps) for an exercise.
  Future<void> setConsignes(Exercise exercise, List<String> consignes) async {
    final cleaned =
        consignes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await _repo.put(exercise.copyWith(consignes: cleaned));
  }
}

class ExerciseDeletionEligibility {
  final int linkedSessionCount;

  const ExerciseDeletionEligibility({required this.linkedSessionCount});

  bool get canDelete => linkedSessionCount == 0;
}

class ExerciseLinkedSessionsException implements Exception {
  final int linkedSessionCount;

  const ExerciseLinkedSessionsException(this.linkedSessionCount);

  @override
  String toString() =>
      'L’exercice doit d’abord être dissocié de $linkedSessionCount session(s).';
}
