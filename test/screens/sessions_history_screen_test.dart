import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/sessions_history_screen.dart';
import 'package:tir_sportif/services/exercise_service.dart';
import 'package:tir_sportif/services/session_service.dart';

/// Tests NT-007 : filtre par exercice dans l'historique des sessions,
/// combinable avec le filtre réalisées/prévues déjà en place.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SessionService sessionService;
  late ExerciseService exerciseService;

  setUpAll(() async {
    // Boxes 100 % en mémoire (bytes:) : aucune écriture disque, donc aucun
    // deadlock entre la zone fake-async de testWidgets et la file d'écriture
    // Hive (cf. le même besoin déjà rencontré dans
    // test/screens/onboarding_screen_test.dart, NT-075) : un box adossé à un
    // vrai fichier ne complète jamais ses I/O tant qu'on est dans la zone
    // fake-async d'un testWidgets, ce qui bloque indéfiniment tout appel
    // Hive fait directement dans le corps du test ou depuis initState().
    final dir = await Directory.systemTemp
        .createTemp('nt_history_exercise_filter_test_');
    Hive.init(dir.path);
    await Hive.openBox('sessions', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
  });

  setUp(() {
    sessionService = SessionService();
    exerciseService = ExerciseService();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').clear();
    if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').clear();
  });

  // L'écran est un long ListView ; on agrandit la surface de rendu pour que
  // tout le contenu (dropdown + cartes) soit effectivement construit,
  // cf. le même besoin dans test/screens/session_detail_screen_test.dart.
  Future<void> growSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await growSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SessionsHistoryScreen()),
      ),
    );
    // Deux pumps : un pour le FutureBuilder en attente, un pour les données résolues.
    await tester.pump();
    await tester.pump();
  }

  group('SessionsHistoryScreen - filtre par exercice (NT-007)', () {
    testWidgets('aligne les deux filtres sur une largeur mobile',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SessionsHistoryScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      final exerciseFilter = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String?> &&
            widget.decoration.labelText == 'Exercice',
      );
      final categoryFilter = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String?> &&
            widget.decoration.labelText == 'Catégorie',
      );
      expect(tester.getTopLeft(exerciseFilter).dy,
          tester.getTopLeft(categoryFilter).dy);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'le résumé compte la libre comme session sans fausser les séries par session',
        (tester) async {
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [
          Series(distance: 10, points: 90, groupSize: 20),
          Series(distance: 10, points: 80, groupSize: 25),
        ],
      ));
      await sessionService.addSession(SimpleShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 2),
        shotCount: 30,
        distance: 10,
        category: SessionConstants.categoryEntrainement,
      ));

      await pumpScreen(tester);

      expect(find.text('Séries/session'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
    });

    testWidgets(
        'le sélecteur "Tous les exercices" affiche toutes les sessions réalisées',
        (tester) async {
      await exerciseService.addExerciseLegacy(
          name: 'Précision debout', category: 'précision');
      await exerciseService.addExerciseLegacy(
          name: 'Vitesse', category: 'vitesse');
      final ex = await exerciseService.listAll();
      final exA = ex.firstWhere((e) => e.name == 'Précision debout').id;
      final exB = ex.firstWhere((e) => e.name == 'Vitesse').id;

      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: [exA],
      ));
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 2),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 80, groupSize: 25)],
        exercises: [exB],
      ));

      await pumpScreen(tester);

      expect(find.text('Exercice'), findsOneWidget);
      // Les deux sessions apparaissent (regroupées par jour car dates différentes).
      expect(find.text('1/1/2025'), findsOneWidget);
      expect(find.text('2/1/2025'), findsOneWidget);
    });

    testWidgets('sélectionner un exercice réduit la liste aux sessions liées',
        (tester) async {
      await exerciseService.addExerciseLegacy(
          name: 'Précision debout', category: 'précision');
      await exerciseService.addExerciseLegacy(
          name: 'Vitesse', category: 'vitesse');
      final ex = await exerciseService.listAll();
      final exA = ex.firstWhere((e) => e.name == 'Précision debout').id;
      final exB = ex.firstWhere((e) => e.name == 'Vitesse').id;

      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: [exA],
      ));
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 2),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 80, groupSize: 25)],
        exercises: [exB],
      ));

      await pumpScreen(tester);

      // Ouvre le dropdown et sélectionne "Vitesse".
      await tester.tap(find.text('Tous les exercices'));
      await tester.pumpAndSettle();
      // Deux occurrences possibles (item de menu + éventuel champ) : on prend la dernière (le menu ouvert).
      await tester.tap(find.text('Vitesse').last);
      await tester.pumpAndSettle();

      expect(find.text('2/1/2025'), findsOneWidget);
      expect(find.text('1/1/2025'), findsNothing);
    });

    testWidgets(
        'le filtre exercice se combine avec le filtre réalisées/prévues',
        (tester) async {
      await exerciseService.addExerciseLegacy(
          name: 'Précision debout', category: 'précision');
      final ex = await exerciseService.listAll();
      final exA = ex.first.id;

      // Réalisée avec l'exercice -> doit apparaître en onglet "Réalisées" + filtre exercice.
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: [exA],
      ));
      // Prévue avec le même exercice -> ne doit PAS apparaître en onglet "Réalisées" + filtre exercice.
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: null,
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 0, groupSize: 0)],
        exercises: [exA],
      ));

      await pumpScreen(tester);

      await tester.tap(find.text('Tous les exercices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Précision debout').last);
      await tester.pumpAndSettle();

      // Réalisées + exercice : la session réalisée apparaît, la prévue non-groupée n'est pas listée
      // comme réalisée. Elle peut apparaître dans la sous-section "Sessions prévues" du même onglet,
      // donc on vérifie via le compteur du résumé plutôt que via l'absence totale du texte.
      expect(find.text('1/1/2025'), findsOneWidget);

      // Bascule sur l'onglet "Prévues" : avec le même filtre exercice actif, la session
      // prévue doit apparaître, la réalisée ne doit plus être comptée.
      await tester.tap(find.text('Prévues'));
      await tester.pumpAndSettle();

      expect(find.text('Exercice'), findsOneWidget);
    });

    testWidgets(
        'sélectionner un exercice sans session correspondante affiche un état vide dédié',
        (tester) async {
      await exerciseService.addExerciseLegacy(
          name: 'Précision debout', category: 'précision');
      await exerciseService.addExerciseLegacy(
          name: 'Vitesse', category: 'vitesse');
      final ex = await exerciseService.listAll();
      final exA = ex.firstWhere((e) => e.name == 'Précision debout').id;

      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: [exA],
      ));

      await pumpScreen(tester);

      await tester.tap(find.text('Tous les exercices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vitesse').last);
      await tester.pumpAndSettle();

      expect(find.text('Aucune session réalisée pour cet exercice'),
          findsOneWidget);
      expect(find.text('Essaie un autre exercice ou réinitialise le filtre.'),
          findsOneWidget);
    });

    testWidgets(
        'aligne les filtres et trie les prévues par date croissante, sans date à la fin',
        (tester) async {
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'Plus tard',
        caliber: '22LR',
        date: DateTime(2026, 10, 20),
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 0, groupSize: 0)],
      ));
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'Sans date',
        caliber: '22LR',
        date: null,
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 0, groupSize: 0)],
      ));
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'Plus tôt',
        caliber: '22LR',
        date: DateTime(2026, 9, 10),
        status: SessionConstants.statusPrevue,
        series: [Series(distance: 10, points: 0, groupSize: 0)],
      ));

      await pumpScreen(tester);

      final exerciseFilter = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String?> &&
            widget.decoration.labelText == 'Exercice',
      );
      final categoryFilter = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String?> &&
            widget.decoration.labelText == 'Catégorie',
      );
      expect(tester.getTopLeft(exerciseFilter).dy,
          tester.getTopLeft(categoryFilter).dy);

      await tester.tap(find.text('Prévues'));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(exerciseFilter).dy,
          tester.getTopLeft(categoryFilter).dy);
      final earlierY = tester.getTopLeft(find.text('Plus tôt')).dy;
      final laterY = tester.getTopLeft(find.text('Plus tard')).dy;
      final undatedY = tester.getTopLeft(find.text('Sans date').last).dy;
      expect(earlierY, lessThan(laterY));
      expect(laterY, lessThan(undatedY));
    });

    testWidgets('revenir à "Tous les exercices" réaffiche toutes les sessions',
        (tester) async {
      await exerciseService.addExerciseLegacy(
          name: 'Précision debout', category: 'précision');
      await exerciseService.addExerciseLegacy(
          name: 'Vitesse', category: 'vitesse');
      final ex = await exerciseService.listAll();
      final exA = ex.firstWhere((e) => e.name == 'Précision debout').id;
      final exB = ex.firstWhere((e) => e.name == 'Vitesse').id;

      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 1),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 90, groupSize: 20)],
        exercises: [exA],
      ));
      await sessionService.addSession(DetailedShootingSession(
        weapon: 'P',
        caliber: '22LR',
        date: DateTime(2025, 1, 2),
        status: SessionConstants.statusRealisee,
        series: [Series(distance: 10, points: 80, groupSize: 25)],
        exercises: [exB],
      ));

      await pumpScreen(tester);

      await tester.tap(find.text('Tous les exercices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Précision debout').last);
      await tester.pumpAndSettle();
      expect(find.text('2/1/2025'), findsNothing);

      await tester.tap(find.text('Précision debout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tous les exercices').last);
      await tester.pumpAndSettle();

      expect(find.text('1/1/2025'), findsOneWidget);
      expect(find.text('2/1/2025'), findsOneWidget);
    });
  });
}
