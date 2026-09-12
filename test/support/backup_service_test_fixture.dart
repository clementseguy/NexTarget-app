import 'dart:io';

import 'package:tir_sportif/interfaces/backup_location_provider.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/weapon_service.dart';

import 'fake_session_repository.dart';

class FakeBackupLocationProvider implements BackupLocationProvider {
  FakeBackupLocationProvider({
    required this.temporaryDirectory,
    this.selectedDirectory,
  });

  Directory temporaryDirectory;
  String? selectedDirectory;
  Object? selectionError;
  String? savedFileName;
  List<int>? savedBytes;

  @override
  Future<Directory> getTemporaryDirectory() async => temporaryDirectory;

  @override
  Future<File?> saveExportFile(
    String suggestedFileName,
    List<int> bytes,
  ) async {
    final error = selectionError;
    if (error != null) throw error;
    final destination = selectedDirectory;
    if (destination == null) return null;
    savedFileName = suggestedFileName;
    savedBytes = List<int>.unmodifiable(bytes);
    final path = destination.toLowerCase().endsWith('.json')
        ? destination
        : '${Directory(destination).path}/$suggestedFileName';
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }
}

class BackupServiceTestFixture {
  BackupServiceTestFixture._({
    required this.service,
    required this.locationProvider,
    required this.exerciseRepository,
  });

  final BackupService service;
  final FakeBackupLocationProvider locationProvider;
  final ExerciseRepository exerciseRepository;

  static Future<BackupServiceTestFixture> create(
    Directory temporaryDirectory, {
    String? selectedDirectory,
  }) async {
    final sessionRepository = FakeSessionRepository();
    final sessionService = SessionService(repository: sessionRepository);
    await sessionService.addSession(
      DetailedShootingSession(
        sessionUuid: 'session-export',
        weapon: 'Pistolet de test',
        caliber: '9 mm',
        date: DateTime(2026, 9, 4),
        status: 'réalisée',
        category: 'entraînement',
        synthese: 'Export déterministe',
        exerciseId: 'exercise-export',
        coachAnalysis: CoachSessionAnalysis(
          analysisId: 'analysis-export',
          sessionId: 'session-export',
          debrief: 'Débrief structuré exporté',
          successes: const ['Régularité observée'],
          attentionPoint: 'Conserver le lâcher',
          limitations: const [],
          exerciseEvaluation: null,
          nextAction: null,
          model: 'test-model',
          generatedAt: DateTime.utc(2026, 9, 4, 12),
        ),
        series: [Series(distance: 25, points: 45, shotCount: 5, groupSize: 8)],
      ),
    );

    final goalRepository = _MemoryGoalRepository([
      Goal(
        id: 'goal-export',
        title: 'Objectif exporté',
        metric: GoalMetric.sessionCount,
        comparator: GoalComparator.greaterOrEqual,
        targetValue: 4,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 2),
        priority: 0,
      ),
    ]);
    final weaponRepository = _MemoryWeaponRepository([
      Weapon(
        id: 'weapon-export',
        name: 'Pistolet de test',
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);
    final locationProvider = FakeBackupLocationProvider(
      temporaryDirectory: temporaryDirectory,
      selectedDirectory: selectedDirectory,
    );
    final exerciseRepository = _MemoryExerciseRepository([
      Exercise(
        id: 'exercise-export',
        name: 'Exercice exporté',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        difficulty: ExerciseDifficulty.expert,
        origin: ExerciseOrigin.coachCatalog,
        createdAt: DateTime(2026, 9, 1),
      ),
    ]);
    final service = BackupService(
      sessionService: sessionService,
      goalService: GoalService(
        sessionRepository: sessionRepository,
        goalRepository: goalRepository,
      ),
      weaponService: WeaponService(
        weaponRepository: weaponRepository,
        sessionRepository: sessionRepository,
      ),
      exerciseService: ExerciseService(
        repository: exerciseRepository,
        sessionRepository: sessionRepository,
      ),
      locationProvider: locationProvider,
    );
    return BackupServiceTestFixture._(
      service: service,
      locationProvider: locationProvider,
      exerciseRepository: exerciseRepository,
    );
  }
}

class _MemoryExerciseRepository implements ExerciseRepository {
  _MemoryExerciseRepository(Iterable<Exercise> exercises)
      : exercises = {for (final exercise in exercises) exercise.id: exercise};

  final Map<String, Exercise> exercises;

  @override
  Future<void> clear() async => exercises.clear();

  @override
  Future<void> delete(String id) async => exercises.remove(id);

  @override
  Future<List<Exercise>> getAll() async => exercises.values
      .map((exercise) => Exercise.fromMap(exercise.toMap()))
      .toList();

  @override
  Future<void> put(Exercise exercise) async {
    exercises[exercise.id] = Exercise.fromMap(exercise.toMap());
  }
}

class _MemoryGoalRepository implements GoalRepository {
  _MemoryGoalRepository(this.goals);

  final List<Goal> goals;

  @override
  Future<void> delete(String id) async =>
      goals.removeWhere((goal) => goal.id == id);

  @override
  Future<void> deleteAll() async => goals.clear();

  @override
  Future<List<Goal>> getAll() async => List<Goal>.from(goals);

  @override
  Future<void> put(Goal goal) async {
    goals.removeWhere((item) => item.id == goal.id);
    goals.add(goal);
  }
}

class _MemoryWeaponRepository implements WeaponRepository {
  _MemoryWeaponRepository(this.weapons);

  final List<Weapon> weapons;

  @override
  Future<void> clear() async => weapons.clear();

  @override
  Future<void> delete(String id) async =>
      weapons.removeWhere((weapon) => weapon.id == id);

  @override
  Future<List<Weapon>> getAll() async => List<Weapon>.from(weapons);

  @override
  Future<void> put(Weapon weapon) async {
    weapons.removeWhere((item) => item.id == weapon.id);
    weapons.add(weapon);
  }
}
