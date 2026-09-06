import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/utils/exercise_filters.dart';
import 'package:tir_sportif/utils/exercise_sorting.dart';

Exercise exercise(
  String id,
  ExerciseCategory category,
  ExerciseType type,
  ExerciseDifficulty? difficulty,
) =>
    Exercise(
      id: id,
      name: id,
      categoryEnum: category,
      type: type,
      difficulty: difficulty,
      createdAt: DateTime(2026),
    );

void main() {
  final exercises = [
    exercise('none', ExerciseCategory.precision, ExerciseType.stand, null),
    exercise('beginner', ExerciseCategory.precision, ExerciseType.home,
        ExerciseDifficulty.beginner),
    exercise('expert', ExerciseCategory.speed, ExerciseType.stand,
        ExerciseDifficulty.expert),
  ];

  test('combine difficulté, catégorie et type', () {
    final result = filterExercises(
      exercises,
      categories: {ExerciseCategory.precision},
      types: {ExerciseType.home},
      difficulty: ExerciseDifficultyFilter.beginner,
    );
    expect(result.map((item) => item.id), ['beginner']);
  });

  test(
      'filtre explicitement les difficultés non renseignées et conserve le tri',
      () {
    final filtered = filterExercises(
      exercises,
      difficulty: ExerciseDifficultyFilter.unspecified,
    );
    expect(sortExercises(filtered, ExerciseSortMode.nameAsc).single.id, 'none');
  });
}
