import '../models/exercise.dart';

enum ExerciseDifficultyFilter { all, unspecified, beginner, advanced, expert }

List<Exercise> filterExercises(
  List<Exercise> exercises, {
  Set<ExerciseCategory> categories = const {},
  Set<ExerciseType> types = const {},
  ExerciseDifficultyFilter difficulty = ExerciseDifficultyFilter.all,
}) =>
    exercises.where((exercise) {
      if (categories.isNotEmpty &&
          !categories.contains(exercise.categoryEnum)) {
        return false;
      }
      if (types.isNotEmpty && !types.contains(exercise.type)) return false;
      return switch (difficulty) {
        ExerciseDifficultyFilter.all => true,
        ExerciseDifficultyFilter.unspecified => exercise.difficulty == null,
        ExerciseDifficultyFilter.beginner =>
          exercise.difficulty == ExerciseDifficulty.beginner,
        ExerciseDifficultyFilter.advanced =>
          exercise.difficulty == ExerciseDifficulty.advanced,
        ExerciseDifficultyFilter.expert =>
          exercise.difficulty == ExerciseDifficulty.expert,
      };
    }).toList();
