import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show Response;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/repositories/goal_repository.dart';
import 'package:tir_sportif/screens/exercises_list_screen.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/coach_catalog_service.dart';
import 'package:tir_sportif/services/goal_service.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/theme/app_theme.dart';

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

class _CountingCatalogService extends CoachCatalogService {
  int calls = 0;

  _CountingCatalogService(ExerciseRepository repository)
      : super(baseUrl: 'https://server.test', repository: repository);

  @override
  Future<Exercise> downloadById(String requestedId) async {
    calls++;
    throw StateError('Le téléchargement ne doit pas démarrer.');
  }
}

class _ExperienceAuthProvider extends AuthProvider {
  final Map<String, dynamic> _user;

  _ExperienceAuthProvider(String experienceLevel)
      : _user = {'experience_level': experienceLevel},
        super(
          AuthService(
            authBaseUrl: 'https://server.test',
            httpClient: MockClient((_) async => Response('', 500)),
          ),
        );

  @override
  Map<String, dynamic> get currentUser => _user;
}

Exercise _exercise() => Exercise(
      id: 'ex-1',
      name: 'Exercice source',
      categoryEnum: ExerciseCategory.speed,
      type: ExerciseType.stand,
      difficulty: ExerciseDifficulty.advanced,
      description: 'Description complète',
      durationMinutes: 15,
      equipment: 'Timer',
      createdAt: DateTime(2026, 1, 1),
      goalIds: ['goal-1'],
      consignes: ['Première consigne', 'Deuxième consigne'],
    );

Exercise _coachExercise() => Exercise(
      id: 'coach-1',
      name: 'Exercice Coach',
      categoryEnum: ExerciseCategory.technique,
      type: ExerciseType.stand,
      origin: ExerciseOrigin.coachCatalog,
      description: 'Description Coach',
      createdAt: DateTime(2026, 9, 11),
      consignes: ['Consigne Coach'],
    );

void main() {
  Future<
      ({
        _ExerciseRepository exerciseRepository,
        FakeSessionRepository sessionRepository,
      })> pumpList(
    WidgetTester tester, {
    List<ShootingSession> sessions = const [],
    List<Exercise>? exercises,
    ThemeData? theme,
    bool debugCatalogControlEnabled = true,
    CoachCatalogService? catalogService,
    String? experienceLevel,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final exerciseRepository = _ExerciseRepository(exercises ?? [_exercise()]);
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
    final screen = ExercisesListScreen(
      key: ObjectKey(exerciseService),
      exerciseService: exerciseService,
      sessionService: sessionService,
      goalService: goalService,
      catalogService: catalogService,
      debugCatalogControlEnabled: debugCatalogControlEnabled,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: experienceLevel == null
            ? screen
            : ChangeNotifierProvider<AuthProvider>(
                key: ObjectKey(exerciseService),
                create: (_) => _ExperienceAuthProvider(experienceLevel),
                child: screen,
              ),
      ),
    );
    await tester.pumpAndSettle();
    return (
      exerciseRepository: exerciseRepository,
      sessionRepository: sessionRepository,
    );
  }

  testWidgets('le contrôle de téléchargement DEBUG est dans la topbar',
      (tester) async {
    await pumpList(tester);

    expect(find.byTooltip('Télécharger un exercice Coach'), findsOneWidget);

    await tester.tap(find.byTooltip('Télécharger un exercice Coach'));
    await tester.pumpAndSettle();
    expect(find.text('Télécharger un exercice Coach'), findsOneWidget);
    expect(find.byKey(const Key('coach_catalog_id_field')), findsOneWidget);
  });

  testWidgets('n’effectue aucun téléchargement à l’ouverture', (tester) async {
    final repository = _ExerciseRepository([_exercise()]);
    final catalogService = _CountingCatalogService(repository);

    await pumpList(tester, catalogService: catalogService);

    expect(catalogService.calls, 0);
  });

  testWidgets('le contrôle peut être masqué hors configuration DEBUG',
      (tester) async {
    await pumpList(tester, debugCatalogControlEnabled: false);

    expect(find.byTooltip('Télécharger un exercice Coach'), findsNothing);
  });

  testWidgets(
    'affiche la provenance Coach et ouvre un détail sans mutations',
    (tester) async {
      await pumpList(tester, exercises: [_coachExercise()]);

      expect(find.text('Créé par le Coach'), findsOneWidget);
      expect(find.byTooltip('Modifier'), findsNothing);
      expect(find.byTooltip('Actions sur Exercice Coach'), findsNothing);

      await tester.tap(find.text('Exercice Coach'));
      await tester.pumpAndSettle();

      expect(find.text('Détail de l’exercice'), findsOneWidget);
      expect(find.text('Créé par le Coach'), findsOneWidget);
      expect(find.text('Description Coach'), findsOneWidget);
      expect(find.text('Consigne Coach'), findsOneWidget);
      expect(find.byTooltip('Enregistrer'), findsNothing);
      expect(find.byTooltip('Supprimer'), findsNothing);
    },
  );

  testWidgets(
    'Dupliquer ouvre un formulaire de création entièrement prérempli',
    (tester) async {
      await pumpList(tester);

      await tester.tap(find.byTooltip('Actions sur Exercice source'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dupliquer'));
      await tester.pumpAndSettle();
      await tester.binding.setSurfaceSize(const Size(390, 1000));
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
      final difficulty = tester.widget<SegmentedButton<String>>(
        find.byKey(const Key('exercise_difficulty')),
      );
      expect(difficulty.selected, {'advanced'});
      expect(
        tester.getTopLeft(find.byKey(const Key('exercise_category'))).dy,
        tester.getTopLeft(find.byKey(const Key('exercise_type'))).dy,
      );
      expect(find.text('N/A'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.text('Première consigne'), findsOneWidget);
      expect(find.text('Deuxième consigne'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Exercice source'), findsOneWidget);
      expect(find.text('Exercice source (copie)'), findsNothing);
    },
  );

  testWidgets('la carte reste lisible dans le thème France', (tester) async {
    await pumpList(tester, theme: AppTheme.bleuBlancRougeTheme);

    final type = tester.widget<Text>(find.text('Stand'));
    final difficulty = tester.widget<Text>(find.text('Avancé'));
    final duration = tester.widget<Text>(find.text('15 min'));

    expect(type.style?.color?.computeLuminance(), lessThan(0.5));
    expect(difficulty.style?.color?.computeLuminance(), lessThan(0.5));
    expect(duration.style?.color?.computeLuminance(), lessThan(0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la carte mobile reste compacte et réserve 38 px aux actions', (
    tester,
  ) async {
    await pumpList(tester);
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('exercise_card_ex-1'));
    final actions = find.byKey(const ValueKey('exercise_actions_ex-1'));

    expect(tester.getSize(actions).width, 38);
    expect(tester.getSize(card).height, lessThan(180));
    expect(find.text('1 objectif'), findsOneWidget);
    expect(find.text('Vitesse'), findsOneWidget);
    expect(find.text('Stand'), findsOneWidget);
    expect(find.text('Avancé'), findsOneWidget);
    expect(find.text('2 consignes'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('Description complète'), findsNothing);
    expect(find.text('Timer'), findsNothing);
    expect(find.byTooltip('Modifier'), findsNothing);
    expect(find.byTooltip('Planifier une session'), findsOneWidget);
    expect(find.byTooltip('Actions sur Exercice source'), findsOneWidget);

    await tester.tap(find.text('Exercice source'));
    await tester.pumpAndSettle();

    expect(find.text('Modifier exercice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final themeType in AppThemeType.values) {
    testWidgets(
      'les couleurs conditionnelles respectent le thème ${themeType.name}',
      (tester) async {
        final theme = AppTheme.forType(themeType);
        await pumpList(
          tester,
          theme: theme,
          experienceLevel: 'advanced',
        );

        final planButton = tester.widget<IconButton>(
          find.byKey(const ValueKey('exercise_plan_ex-1')),
        );
        final planColor = (planButton.icon as Icon).color;
        final type = tester.widget<Text>(find.text('Stand'));
        final goal = tester.widget<Text>(find.text('1 objectif'));
        final instructions = tester.widget<Text>(find.text('2 consignes'));
        final difficulty = tester.widget<Text>(find.text('Avancé'));
        final expectedGreen = theme.brightness == Brightness.dark
            ? theme.colorScheme.secondary
            : const Color(0xFF147A3D);
        final leading = tester.widget<SizedBox>(
          find.byKey(const ValueKey('exercise_leading_ex-1')),
        );

        expect(leading.child, isA<Icon>());
        expect(planButton.icon, isA<Icon>());
        expect(type.style?.color, planColor);
        expect(instructions.style?.color, goal.style?.color);
        expect(difficulty.style?.color, expectedGreen);

        await pumpList(
          tester,
          theme: theme,
          exercises: [_exercise().copyWith(type: ExerciseType.home)],
          experienceLevel: 'beginner',
        );

        final homeType = tester.widget<Text>(find.text('Maison'));
        final unmatchedDifficulty = tester.widget<Text>(find.text('Avancé'));
        expect(find.byKey(const ValueKey('exercise_plan_ex-1')), findsNothing);
        expect(homeType.style?.color, isNot(planColor));
        expect(unmatchedDifficulty.style?.color, isNot(expectedGreen));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Réinitialiser resynchronise le filtre de difficulté affiché', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.byTooltip('Déplier'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('exercise_difficulty_filter_all'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expert').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('exercise_difficulty_filter_expert')),
      findsOneWidget,
    );

    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('exercise_difficulty_filter_all')),
      findsOneWidget,
    );
    expect(find.text('Tous'), findsOneWidget);
  });

  testWidgets(
    'modifie puis crée la copie et rafraîchit sans changer la source',
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
      await tester.tap(find.text('Débutant'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Exercice source'), findsOneWidget);
      expect(find.text('Exercice personnalisé'), findsOneWidget);
      expect(repositories.exerciseRepository.store.length, 2);
      final source = repositories.exerciseRepository.store['ex-1']!;
      final copy = repositories.exerciseRepository.store.values.singleWhere(
        (exercise) => exercise.id != 'ex-1',
      );
      expect(source.name, 'Exercice source');
      expect(source.consignes, ['Première consigne', 'Deuxième consigne']);
      expect(copy.name, 'Exercice personnalisé');
      expect(copy.id, isNot(source.id));
      expect(copy.createdAt, isNot(source.createdAt));
      expect(source.difficulty, ExerciseDifficulty.advanced);
      expect(copy.difficulty, ExerciseDifficulty.beginner);
    },
  );

  testWidgets('refuse la suppression liée avec le nombre de sessions', (
    tester,
  ) async {
    final linked = DetailedShootingSession(
      date: DateTime(2026, 9, 1),
      weapon: 'Pistolet',
      caliber: '9 mm',
      series: [Series(distance: 25, points: 40, groupSize: 5)],
      exerciseId: 'ex-1',
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

  testWidgets('annule puis confirme la suppression et rafraîchit la liste', (
    tester,
  ) async {
    final repositories = await pumpList(tester);

    Future<void> openDelete() async {
      await tester.tap(find.byTooltip('Actions sur Exercice source'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
    }

    await openDelete();
    expect(
      find.text('Supprimer définitivement « Exercice source » ?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(repositories.exerciseRepository.store, contains('ex-1'));

    await openDelete();
    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();
    expect(repositories.exerciseRepository.store, isEmpty);
    expect(find.text('Créer le premier exercice'), findsOneWidget);
  });

  testWidgets('affiche l’erreur d’écriture sans état mensonger', (
    tester,
  ) async {
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
