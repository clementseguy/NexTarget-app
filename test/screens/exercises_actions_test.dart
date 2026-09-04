import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/screens/exercises_list_screen.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/session_service.dart';

import '../support/fake_session_repository.dart';

class _ExerciseRepository implements ExerciseRepository {
  final Map<String, Exercise> store;
  bool failDelete = false;

  _ExerciseRepository(Iterable<Exercise> exercises)
      : store = {for (final exercise in exercises) exercise.id: exercise};

  @override
  Future<void> clear() async => store.clear();

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('Échec simulé');
    store.remove(id);
  }

  @override
  Future<List<Exercise>> getAll() async =>
      store.values.map((item) => Exercise.fromMap(item.toMap())).toList();

  @override
  Future<void> put(Exercise exercise) async {
    store[exercise.id] = Exercise.fromMap(exercise.toMap());
  }
}

class _GoalRepository implements GoalRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteAll() async {}

  @override
  Future<List<Goal>> getAll() async => const [];

  @override
  Future<void> put(Goal goal) async {}
}

Exercise _exercise() => Exercise(
      id: 'ex-1',
      name: 'Exercice source',
      categoryEnum: ExerciseCategory.speed,
      type: ExerciseType.stand,
      description: 'Description complète',
      durationMinutes: 15,
      equipment: 'Timer',
      createdAt: DateTime(2026, 1, 1),
      goalIds: ['goal-1'],
      consignes: ['Première consigne', 'Deuxième consigne'],
    );

void main() {
  Future<
      ({
        _ExerciseRepository exerciseRepository,
        FakeSessionRepository sessionRepository,
      })> pumpList(
    WidgetTester tester, {
    List<ShootingSession> sessions = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final exerciseRepository = _ExerciseRepository([_exercise()]);
    final sessionRepository = FakeSessionRepository();
    for (final session in sessions) {
      await sessionRepository.insert(session);
    }
    final exerciseService = ExerciseService(
      repository: exerciseRepository,
      sessionRepository: sessionRepository,
    );
    final sessionService = SessionService(repository: sessionRepository);
    final goalService = GoalService(
      goalRepository: _GoalRepository(),
      sessionRepository: sessionRepository,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExercisesListScreen(
          exerciseService: exerciseService,
          sessionService: sessionService,
          goalService: goalService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      exerciseRepository: exerciseRepository,
      sessionRepository: sessionRepository,
    );
  }

  testWidgets('Dupliquer ouvre un formulaire de création entièrement prérempli',
      (tester) async {
    await pumpList(tester);

    await tester.tap(find.byTooltip('Actions sur Exercice source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvel exercice'), findsOneWidget);
    final name = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Nom de l\'exercice'),
    );
    final description = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Description'),
    );
    final duration = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Durée'),
    );
    final equipment = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Matériel requis'),
    );
    expect(name.controller!.text, 'Exercice source (copie)');
    expect(description.controller!.text, 'Description complète');
    expect(duration.controller!.text, '15');
    expect(equipment.controller!.text, 'Timer');
    expect(find.text('Première consigne'), findsOneWidget);
    expect(find.text('Deuxième consigne'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Exercice source'), findsOneWidget);
    expect(find.text('Exercice source (copie)'), findsNothing);
  });

  testWidgets('modifie puis crée la copie et rafraîchit sans changer la source',
      (tester) async {
    final repositories = await pumpList(tester);

    await tester.tap(find.byTooltip('Actions sur Exercice source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom de l\'exercice'),
      'Exercice personnalisé',
    );
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Exercice source'), findsOneWidget);
    expect(find.text('Exercice personnalisé'), findsOneWidget);
    expect(repositories.exerciseRepository.store.length, 2);
    final source = repositories.exerciseRepository.store['ex-1']!;
    final copy = repositories.exerciseRepository.store.values
        .singleWhere((exercise) => exercise.id != 'ex-1');
    expect(source.name, 'Exercice source');
    expect(source.consignes, ['Première consigne', 'Deuxième consigne']);
    expect(copy.name, 'Exercice personnalisé');
    expect(copy.id, isNot(source.id));
    expect(copy.createdAt, isNot(source.createdAt));
  });

  testWidgets('refuse la suppression liée avec le nombre de sessions',
      (tester) async {
    final linked = DetailedShootingSession(
      date: DateTime(2026, 9, 1),
      weapon: 'Pistolet',
      caliber: '9 mm',
      series: [Series(distance: 25, points: 40, groupSize: 5)],
      exercises: const ['ex-1'],
    );
    final repositories = await pumpList(tester, sessions: [linked, linked]);

    await tester.tap(find.byTooltip('Actions sur Exercice source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('2 session(s) concernée(s)'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(repositories.exerciseRepository.store, contains('ex-1'));
    expect((await repositories.sessionRepository.getAll()).length, 2);
  });

  testWidgets('annule puis confirme la suppression et rafraîchit la liste',
      (tester) async {
    final repositories = await pumpList(tester);

    Future<void> openDelete() async {
      await tester.tap(find.byTooltip('Actions sur Exercice source'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
    }

    await openDelete();
    expect(find.text('Supprimer définitivement « Exercice source » ?'),
        findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repositories.exerciseRepository.store, contains('ex-1'));

    await openDelete();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(repositories.exerciseRepository.store, isEmpty);
    expect(find.text('Créer le premier exercice'), findsOneWidget);
  });

  testWidgets('affiche l’erreur d’écriture sans état mensonger',
      (tester) async {
    final repositories = await pumpList(tester);
    repositories.exerciseRepository.failDelete = true;

    await tester.tap(find.byTooltip('Actions sur Exercice source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Suppression impossible'), findsOneWidget);
    expect(repositories.exerciseRepository.store, contains('ex-1'));
    expect(find.text('Exercice source'), findsOneWidget);
  });
}
