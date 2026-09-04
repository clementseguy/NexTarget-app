import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/guided_session_preparation_screen.dart';
import 'package:tir_sportif/screens/guided_session_screen.dart';
import 'package:tir_sportif/screens/session_detail_screen.dart';
import 'package:tir_sportif/screens/sessions_history_screen.dart';
import 'package:tir_sportif/services/preferences_service.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/weapon_service.dart';
import 'package:tir_sportif/theme/app_theme.dart';
import 'package:tir_sportif/widgets/guided_draft_card.dart';
import 'package:tir_sportif/widgets/caliber_autocomplete_field.dart';

import '../support/fake_session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FakeSessionRepository repository;
  late SessionService service;

  setUpAll(AppConfig.load);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt131_widgets_');
    Hive.init(directory.path);
    await Hive.openBox('app_preferences', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
    await Hive.openBox('weapons', bytes: Uint8List(0));
    repository = FakeSessionRepository();
    service = SessionService(repository: repository);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Finder textField(String label) => find.widgetWithText(TextFormField, label);

  Future<void> setLargeSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  testWidgets('préremplit les préférences et crée le brouillon nominal',
      (tester) async {
    await setLargeSurface(tester);
    await PreferencesService().setDefaultCaliber('.45 ACP');
    await PreferencesService().setDefaultHandMethod(HandMethod.oneHand);

    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionPreparationScreen(
          sessionService: service,
          initialDate: DateTime(2026, 9, 4, 14, 30),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('10 séries · 5 coups par série · 50 coups prévus'),
        findsOneWidget);
    expect(
      tester
          .widget<CaliberAutocompleteField>(
            find.byType(CaliberAutocompleteField),
          )
          .controller
          .text,
      '.45 ACP',
    );

    await tester.enterText(textField('Arme'), 'Arme libre');
    await tester.tap(find.byKey(const Key('start_guided_session')));
    await tester.pumpAndSettle();

    expect(find.byType(GuidedSessionScreen), findsOneWidget);
    final draft = (await service.getGuidedDrafts()).single;
    expect(draft.weapon, 'Arme libre');
    expect(draft.series, hasLength(10));
    expect(draft.series.first.handMethod, HandMethod.oneHand);
  });

  testWidgets('sans préférence garde le calibre libre et suggère le râtelier',
      (tester) async {
    await setLargeSurface(tester);
    await WeaponService().addWeapon('CZ 75 SP-01 Shadow');
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionPreparationScreen(sessionService: service),
      ),
    );
    await tester.pumpAndSettle();

    final caliber = tester.widget<CaliberAutocompleteField>(
      find.byType(CaliberAutocompleteField),
    );
    expect(caliber.controller.text, isEmpty);
    await tester.enterText(textField('Arme'), 'CZ');
    await tester.pumpAndSettle();
    expect(find.text('CZ 75 SP-01 Shadow'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('guided_shots_per_series')),
      '12',
    );
    await tester.pump();
    expect(find.textContaining('120 coups prévus'), findsOneWidget);
  });

  testWidgets('sauvegarde, hérite, navigue et applique les raccourcis distance',
      (tester) async {
    await setLargeSurface(tester);
    final draft = await service.createGuidedDraft(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      category: 'entraînement',
      exercises: const [],
      seriesCount: 2,
      shotsPerSeries: 7,
      initialDistance: 25,
      initialHandMethod: HandMethod.oneHand,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionScreen(draft: draft, sessionService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('guided_points')), '0');
    await tester.enterText(find.byKey(const Key('guided_group')), '8,5');
    await tester.tap(find.widgetWithText(ActionChip, '15 m'));
    await tester.pump(const Duration(milliseconds: 700));

    var restored = (await service.getGuidedDrafts()).single;
    expect(restored.series.first.isDraftStarted, isTrue);
    expect(restored.series.first.distance, 15);

    await tester.tap(find.byKey(const Key('guided_next')));
    await tester.pumpAndSettle();
    expect(find.text('Série 2 / 2'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('guided_distance')),
          )
          .controller
          ?.text,
      '15',
    );

    await tester.tap(find.byKey(const Key('guided_previous')));
    await tester.pumpAndSettle();
    expect(find.text('Série 1 / 2'), findsOneWidget);
    restored = (await service.getGuidedDrafts()).single;
    expect(restored.series.first.isCompleted, isTrue);
    expect(restored.series.first.points, 0);
  });

  testWidgets('ajoute une série et termine plus tôt après confirmation',
      (tester) async {
    await setLargeSurface(tester);
    final draft = await service.createGuidedDraft(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      category: 'entraînement',
      exercises: const [],
      seriesCount: 2,
      shotsPerSeries: 5,
      initialDistance: 25,
      initialHandMethod: HandMethod.twoHands,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionScreen(draft: draft, sessionService: service),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajouter une série'));
    await tester.pumpAndSettle();
    expect(find.text('Série 3 / 3'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('guided_points')), '42');
    await tester.enterText(find.byKey(const Key('guided_group')), '9');
    await tester.tap(find.byKey(const Key('guided_next')));
    await tester.pumpAndSettle();
    expect(find.text('Terminer plus tôt ?'), findsOneWidget);
    expect(find.textContaining('2 séries non renseignées'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Synthèse de la séance'), findsOneWidget);
  });

  testWidgets('clôture puis redirige directement vers le détail',
      (tester) async {
    await setLargeSurface(tester);
    final draft = await service.createGuidedDraft(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      category: 'match',
      exercises: const [],
      seriesCount: 1,
      shotsPerSeries: 6,
      initialDistance: 25,
      initialHandMethod: HandMethod.twoHands,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionScreen(draft: draft, sessionService: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('guided_points')), '50');
    await tester.enterText(find.byKey(const Key('guided_group')), '7');
    await tester.tap(find.byKey(const Key('guided_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('complete_guided_session')));
    await tester.pumpAndSettle();

    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect((await service.getGuidedDrafts()), isEmpty);
    expect((await service.getAllSessions()).single.status, 'réalisée');
  });

  testWidgets('une erreur de clôture conserve le brouillon et l’explique',
      (tester) async {
    await setLargeSurface(tester);
    final draft = await service.createGuidedDraft(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      category: 'match',
      exercises: const [],
      seriesCount: 1,
      shotsPerSeries: 5,
      initialDistance: 25,
      initialHandMethod: HandMethod.twoHands,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GuidedSessionScreen(draft: draft, sessionService: service),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('guided_points')), '45');
    await tester.enterText(find.byKey(const Key('guided_group')), '8');
    await tester.tap(find.byKey(const Key('guided_next')));
    await tester.pumpAndSettle();
    repository.failOnUpdateCallNumber = repository.updateCallCount + 2;

    await tester.tap(find.byKey(const Key('complete_guided_session')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Le brouillon est conservé'), findsOneWidget);
    final restored = (await service.getGuidedDrafts()).single;
    expect(restored.series.single.points, 45);
    expect(restored.status, 'brouillon');
  });

  testWidgets('affiche le brouillon séparément dans l’historique',
      (tester) async {
    await setLargeSurface(tester);
    await service.createGuidedDraft(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      category: 'entraînement',
      exercises: const [],
      seriesCount: 3,
      shotsPerSeries: 5,
      initialDistance: 25,
      initialHandMethod: HandMethod.twoHands,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionsHistoryScreen(sessionService: service),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Séances en cours'), findsOneWidget);
    expect(find.text('Séance en cours'), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);
    expect(find.text('0 / 3 séries · 0 coups enregistrés'), findsOneWidget);
  });

  testWidgets('la carte de brouillon reste lisible dans les deux thèmes',
      (tester) async {
    final draft = DetailedShootingSession(
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      status: 'brouillon',
      series: [
        Series(
          shotCount: 5,
          distance: 25,
          points: 45,
          groupSize: 8,
          isCompleted: true,
        ),
      ],
    );
    for (final theme in AppThemeType.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forType(theme),
          home: Scaffold(
            body: GuidedDraftCard(
              draft: draft,
              onResume: () {},
              onAbandon: () {},
            ),
          ),
        ),
      );
      expect(find.text('Séance en cours'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
