import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/utils/session_filters.dart';

void main() {
  group('SessionFilters.realizedWithDate', () {
    test('garde uniquement les sessions réalisées avec date non nulle', () {
      final s1 = ShootingSession(
        id: 1,
        date: DateTime(2025, 10, 1),
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
      );
      final s2 = ShootingSession(
        id: 2,
        date: null,
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 80, groupSize: 25)],
      );
      final s3 = ShootingSession(
        id: 3,
        date: DateTime(2025, 10, 2),
        weapon: 'P', caliber: '22LR',
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 100, groupSize: 10)],
      );

      final filtered = SessionFilters.realizedWithDate([s1, s2, s3]);
      expect(filtered.length, 1);
      expect(filtered.first.id, 1);
    });
  });

  group('SessionFilters.byExercise', () {
    ShootingSession makeSession({required int id, required List<String> exercises, String status = SessionConstants.statusRealisee}) {
      return ShootingSession(
        id: id,
        date: DateTime(2025, 10, id),
        weapon: 'P', caliber: '22LR',
        status: status,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: exercises,
      );
    }

    test('ne garde que les sessions liées à l\'exercice donné', () {
      final s1 = makeSession(id: 1, exercises: ['ex-a']);
      final s2 = makeSession(id: 2, exercises: ['ex-b']);
      final s3 = makeSession(id: 3, exercises: ['ex-a', 'ex-b']);

      final filtered = SessionFilters.byExercise([s1, s2, s3], 'ex-a');
      expect(filtered.map((s) => s.id).toSet(), {1, 3});
    });

    test('exerciseId null ne filtre rien (retourne toutes les sessions)', () {
      final s1 = makeSession(id: 1, exercises: ['ex-a']);
      final s2 = makeSession(id: 2, exercises: []);

      final filtered = SessionFilters.byExercise([s1, s2], null);
      expect(filtered.length, 2);
    });

    test('exercice sans aucune session correspondante retourne une liste vide', () {
      final s1 = makeSession(id: 1, exercises: ['ex-a']);

      final filtered = SessionFilters.byExercise([s1], 'ex-inconnu');
      expect(filtered, isEmpty);
    });

    test('est combinable avec un filtre de statut (réalisées + exercice)', () {
      final realizedWithEx = makeSession(id: 1, exercises: ['ex-a']);
      final plannedWithEx = makeSession(id: 2, exercises: ['ex-a'], status: SessionConstants.statusPrevue);
      final realizedWithoutEx = makeSession(id: 3, exercises: ['ex-b']);

      final byExercise = SessionFilters.byExercise([realizedWithEx, plannedWithEx, realizedWithoutEx], 'ex-a');
      final byExerciseAndStatus = SessionFilters.realizedWithDate(byExercise);

      expect(byExerciseAndStatus.map((s) => s.id).toList(), [1]);
    });
  });
}
