import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import '../support/fake_session_repository.dart';

class _MemExerciseRepo implements ExerciseRepository {
  final Map<String, Exercise> _store = {};
  bool failPut = false;
  bool failDelete = false;
  @override
  Future<void> clear() async => _store.clear();
  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('Échec de suppression');
    _store.remove(id);
  }

  @override
  Future<List<Exercise>> getAll() async {
    final list = _store.values.toList();
    list.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  @override
  Future<void> put(Exercise exercise) async {
    if (failPut) throw StateError('Échec d’écriture');
    _store[exercise.id] = Exercise.fromMap(exercise.toMap());
  }
}

class _FailingReadSessionRepository extends FakeSessionRepository {
  @override
  Future<List<ShootingSession>> getAll() async =>
      throw StateError('Échec de lecture');
}

void main() {
  group('ExerciseService', () {
    late ExerciseService service;
    late _MemExerciseRepo repo;
    late FakeSessionRepository sessionRepository;

    setUp(() {
      repo = _MemExerciseRepo();
      sessionRepository = FakeSessionRepository();
      service = ExerciseService(
        repository: repo,
        sessionRepository: sessionRepository,
      );
    });

    test('generateId returns base36_ts_random format', () {
      final id = service.generateId();
      expect(id.contains('_'), isTrue);
      final parts = id.split('_');
      expect(parts.length, 2);
      // base36 strings should be alphanumeric
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(parts[0]), isTrue);
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(parts[1]), isTrue);
    });

    test('addExercise trims inputs and accepts legacy string category',
        () async {
      await service.addExercise(
          name: '  Drill  ',
          category: 'stand',
          type: ExerciseType.stand,
          description: '  desc  ',
          consignes: ['  a  ', '   ', 'b']);
      final all = await service.listAll();
      expect(all.length, 1);
      expect(all.first.name, 'Drill');
      expect(all.first.description, 'desc');
      // 'stand' as legacy category string defaults to precision via parser
      expect(all.first.categoryEnum, ExerciseCategory.precision);
      expect(all.first.consignes, ['a', 'b']);
    });

    test('setGoals deduplicates and setConsignes trims/filters', () async {
      await service.addExercise(
          name: 'X', category: ExerciseCategory.precision, consignes: ['x']);
      var all = await service.listAll();
      final ex = all.first;
      await service.setGoals(ex, ['g1', 'g1', 'g2']);
      all = await service.listAll();
      expect(all.first.goalIds, ['g1', 'g2']);

      await service.setConsignes(all.first, ['  step1  ', '', 'step2  ']);
      all = await service.listAll();
      expect(all.first.consignes, ['step1', 'step2']);
    });

    test('prépare une duplication complète et profonde', () {
      final source = Exercise(
        id: 'source',
        name: 'Précision',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        description: 'Description',
        durationMinutes: 20,
        equipment: 'Pistolet',
        createdAt: DateTime(2026, 1, 1),
        priority: 2,
        goalIds: ['g1', 'g2'],
        consignes: ['A', 'B'],
      );

      final duplicate = service.prepareDuplication(source);

      expect(duplicate.id, isNot(source.id));
      expect(duplicate.createdAt.isAfter(source.createdAt), isTrue);
      expect(duplicate.name, 'Précision (copie)');
      expect(duplicate.categoryEnum, source.categoryEnum);
      expect(duplicate.type, source.type);
      expect(duplicate.description, source.description);
      expect(duplicate.durationMinutes, source.durationMinutes);
      expect(duplicate.equipment, source.equipment);
      expect(duplicate.priority, 9999);
      expect(duplicate.goalIds, source.goalIds);
      expect(duplicate.consignes, source.consignes);
      duplicate.goalIds.removeAt(0);
      duplicate.consignes[0] = 'Copie';
      expect(source.goalIds, ['g1', 'g2']);
      expect(source.consignes, ['A', 'B']);
    });

    test('supprime un exercice sans session liée', () async {
      await service.addExercise(name: 'Libre', category: 'precision');
      final exercise = (await service.listAll()).single;

      await service.deleteExercise(exercise.id);

      expect(await service.listAll(), isEmpty);
    });

    test('compte tous les types et statuts de sessions liées et refuse',
        () async {
      const exerciseId = 'ex';
      final sessions = <ShootingSession>[
        DetailedShootingSession(
          date: DateTime(2026, 9, 1),
          weapon: 'A',
          caliber: '9 mm',
          status: SessionConstants.statusRealisee,
          series: [Series(distance: 25, points: 40, groupSize: 5)],
          exercises: [exerciseId],
        ),
        DetailedShootingSession(
          weapon: '',
          caliber: '',
          status: SessionConstants.statusPrevue,
          series: [Series(distance: 25, points: 0, groupSize: 0)],
          exercises: [exerciseId],
        ),
        DetailedShootingSession(
          date: DateTime(2026, 9, 2),
          weapon: 'B',
          caliber: '.22 LR',
          status: SessionConstants.statusDraft,
          series: [
            Series(
              distance: 25,
              points: 0,
              groupSize: 0,
              isCompleted: false,
            ),
          ],
          exercises: [exerciseId],
        ),
        SimpleShootingSession(
          date: DateTime(2026, 9, 3),
          weapon: 'C',
          caliber: '.22 LR',
          shotCount: 20,
          distance: 25,
          exercises: [exerciseId],
        ),
      ];
      for (final session in sessions) {
        await sessionRepository.insert(session);
      }
      await repo.put(Exercise(
        id: exerciseId,
        name: 'Lié',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 1, 1),
      ));

      final eligibility = await service.checkDeletionEligibility(exerciseId);
      expect(eligibility.linkedSessionCount, 4);
      await expectLater(
        service.deleteExercise(exerciseId),
        throwsA(
          isA<ExerciseLinkedSessionsException>().having(
            (error) => error.linkedSessionCount,
            'linkedSessionCount',
            4,
          ),
        ),
      );
      expect((await repo.getAll()).single.id, exerciseId);
      expect((await sessionRepository.getAll()).length, 4);
    });

    test('une erreur de lecture empêche la suppression', () async {
      final failingService = ExerciseService(
        repository: repo,
        sessionRepository: _FailingReadSessionRepository(),
      );
      await repo.put(Exercise(
        id: 'ex',
        name: 'Exercice',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 1, 1),
      ));

      await expectLater(
        failingService.deleteExercise('ex'),
        throwsStateError,
      );
      expect((await repo.getAll()).single.id, 'ex');
    });

    test('une erreur de suppression laisse l’exercice présent', () async {
      await repo.put(Exercise(
        id: 'ex',
        name: 'Exercice',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 1, 1),
      ));
      repo.failDelete = true;

      await expectLater(service.deleteExercise('ex'), throwsStateError);
      expect((await repo.getAll()).single.id, 'ex');
    });

    test('une erreur d’écriture ne crée aucune duplication partielle',
        () async {
      final source = Exercise(
        id: 'source',
        name: 'Source',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 1, 1),
      );
      await repo.put(source);
      final duplicate = service.prepareDuplication(source);
      repo.failPut = true;

      await expectLater(service.createExercise(duplicate), throwsStateError);
      expect((await repo.getAll()).map((item) => item.id), ['source']);
    });
  });
}
