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
      final ex2 = Exercise.fromMap({
        ...map,
      });
      expect(ex2.categoryEnum, ExerciseCategory.technique);
      expect(ex2.type, ExerciseType.home);
      expect(ex2.difficulty, ExerciseDifficulty.advanced);
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
      expect(Exercise.fromMap({...base, 'difficulty': 'unknown'}).difficulty,
          isNull);
      expect(Exercise.fromMap(base).difficultyLabelFr, 'Non renseignée');
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
