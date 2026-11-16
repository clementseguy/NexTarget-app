import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';

void main() {
  group('Exercise model mapping & labels', () {
    test('toMap/fromMap roundtrip preserves enum via string and labels', () {
      final ex = Exercise(
        id: 'e1',
        name: 'Drill',
        categoryEnum: ExerciseCategory.technique,
        type: ExerciseType.home,
        difficulty: ExerciseDifficulty.advanced,
        origin: ExerciseOrigin.coachCatalog,
        description: 'desc',
        createdAt: DateTime(2025, 10, 7),
        priority: 5,
        goalIds: ['g1', 'g2'],
        consignes: ['a', 'b'],
      );
      final map = ex.toMap();
      expect(map['category'], 'technique');
      expect(map['type'], 'home');
      expect(map['difficulty'], 'advanced');
      expect(map['origin'], 'coach_catalog');
      final ex2 = Exercise.fromMap({
        ...map,
      });
      expect(ex2.categoryEnum, ExerciseCategory.technique);
      expect(ex2.type, ExerciseType.home);
      expect(ex2.difficulty, ExerciseDifficulty.advanced);
      expect(ex2.origin, ExerciseOrigin.coachCatalog);
      expect(ex2.difficultyLabelFr, 'Avancé');
      expect(ex2.categoryLabelFr, 'Technique');
      expect(ex2.typeLabelFr, 'Maison');
    });

    test('une sauvegarde historique ou une valeur inconnue reste valide', () {
      final base = {
        'id': 'legacy',
        'name': 'Historique',
        'category': 'precision',
        'type': 'stand',
        'createdAt': DateTime(2025).toIso8601String(),
      };
      expect(Exercise.fromMap(base).difficulty, isNull);
      expect(Exercise.fromMap(base).origin, ExerciseOrigin.personal);
      expect(Exercise.fromMap({...base, 'difficulty': 'unknown'}).difficulty,
          isNull);
      expect(Exercise.fromMap(base).difficultyLabelFr, 'Non renseignée');
    });

    test('rejette une provenance inconnue', () {
      final map = {
        'id': 'invalid-origin',
        'name': 'Invalide',
        'category': 'precision',
        'type': 'stand',
        'origin': 'server',
        'createdAt': DateTime(2026).toIso8601String(),
      };

      expect(() => Exercise.fromMap(map), throwsFormatException);
    });

    test('le contrat JSON complet utilise les noms et valeurs partagés', () {
      final exercise = Exercise(
        id: 'exercise-contract',
        name: 'Contrat',
        categoryEnum: ExerciseCategory.group,
        type: ExerciseType.stand,
        difficulty: ExerciseDifficulty.beginner,
        origin: ExerciseOrigin.coachCatalog,
        description: 'Description',
        durationMinutes: 15,
        equipment: 'Pistolet',
        createdAt: DateTime.utc(2026, 9, 11),
        priority: 3,
        goalIds: ['goal-1'],
        consignes: ['Étape 1'],
      );

      expect(exercise.toMap(), {
        'id': 'exercise-contract',
        'name': 'Contrat',
        'category': 'group',
        'type': 'stand',
        'difficulty': 'beginner',
        'origin': 'coach_catalog',
        'description': 'Description',
        'durationMinutes': 15,
        'equipment': 'Pistolet',
        'createdAt': '2026-09-11T00:00:00.000Z',
        'priority': 3,
        'goalIds': ['goal-1'],
        'consignes': ['Étape 1'],
      });
      expect(ExerciseCategory.values.map((value) => value.name), [
        'precision',
        'group',
        'speed',
        'technique',
        'mental',
        'physical',
      ]);
      expect(ExerciseType.values.map((value) => value.name), ['stand', 'home']);
      expect(ExerciseDifficulty.values.map((value) => value.name), [
        'beginner',
        'advanced',
        'expert',
      ]);
      expect(
        ExerciseOrigin.values.map((value) => value.serializedName),
        ['personal', 'coach_catalog'],
      );
      expect(exercise.toMap().containsKey('serverId'), isFalse);
      expect(exercise.toMap().containsKey('version'), isFalse);
    });

    test('fromMap parses legacy synonyms and defaults', () {
      final ex = Exercise.fromMap({
        'id': 'e2',
        'name': 'Legacy',
        'category': 'groupement',
        'type': 'stand',
        'createdAt': DateTime(2025, 10, 6).toIso8601String(),
        'priority': 1,
        'goalIds': [],
        'consignes': [],
      });
      expect(ex.categoryEnum, ExerciseCategory.group);
      expect(ex.type, ExerciseType.stand);

      // Unknown type defaults to stand
      final ex2 = Exercise.fromMap({
        'id': 'e3',
        'name': 'X',
        'category': 'precision',
        'type': 'unknown',
        'createdAt': DateTime(2025, 10, 6).toIso8601String(),
      });
      expect(ex2.type, ExerciseType.stand);
    });

    test('parseExerciseCategory accepts accented and english inputs', () {
      expect(parseExerciseCategory('précision'), ExerciseCategory.precision);
      expect(parseExerciseCategory('physical'), ExerciseCategory.physical);
      expect(parseExerciseCategory('SPEED'), ExerciseCategory.speed);
    });
  });
}
