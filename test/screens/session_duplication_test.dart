import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/session_detail_screen.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/services/auth_service.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
    final directory = await Directory.systemTemp.createTemp('session_dup_ui_');
    Hive.init(directory.path);
    for (final boxName in [
      'app_preferences',
      'sessions',
      'exercises',
      'weapons',
    ]) {
      await Hive.openBox(boxName, bytes: Uint8List(0));
    }
  });

  setUp(() async {
    await Hive.box('sessions').clear();
    await Hive.box('exercises').clear();
  });

  tearDownAll(() async => Hive.close());

  testWidgets('la duplication détaillée préremplit tout sauf la date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = DetailedShootingSession(
      id: 12,
      date: DateTime(2026, 8, 1),
      weapon: 'Pistolet source',
      caliber: '9 mm',
      category: SessionConstants.categoryMatch,
      synthese: 'Synthèse source',
      analyse: 'Analyse source',
      exercises: const ['ex-1'],
      series: [
        Series(
          shotCount: 10,
          distance: 25,
          points: 91,
          groupSize: 5,
          comment: 'Commentaire source',
          handMethod: HandMethod.oneHand,
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(
          AuthService(authBaseUrl: 'https://example.invalid'),
        ),
        child: MaterialApp(
          home: SessionDetailScreen(
            sessionData: {
              'session': session.toMap(),
              'series': session.series.map((item) => item.toMap()).toList(),
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dupliquer la session'), findsOneWidget);
    expect(find.byTooltip('Copier résumé'), findsNothing);
    expect(find.text('Résumé copié'), findsNothing);
    await tester.tap(find.byTooltip('Dupliquer la session'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle session'), findsOneWidget);
    expect(find.text('Date ?'), findsOneWidget);
    expect(find.text('1/8/2026'), findsNothing);
    final weapon = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Arme (optionnel si prévue)'),
    );
    final caliber = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Calibre'),
    );
    expect(weapon.controller!.text, 'Pistolet source');
    expect(caliber.controller!.text, '9 mm');
    expect(find.text('Synthèse source'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(Hive.box('sessions').isEmpty, isTrue);
  });

  testWidgets(
      'la duplication libre exige une nouvelle date et annuler ne crée rien',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = SimpleShootingSession(
      id: 5,
      date: DateTime(2026, 8, 2),
      weapon: 'Carabine source',
      caliber: '.22 LR',
      shotCount: 30,
      distance: 50,
      synthese: 'Libre source',
      exercises: const ['ex-libre'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SessionDetailScreen(
          sessionData: {'session': session.toMap(), 'series': const []},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dupliquer la session'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle session libre'), findsOneWidget);
    expect(find.text('Date ?'), findsOneWidget);
    expect(find.text('2/8/2026'), findsNothing);
    final shots = tester.widget<TextFormField>(
      find.byKey(const Key('simpleShotCount')),
    );
    final distance = tester.widget<TextFormField>(
      find.byKey(const Key('simpleDistance')),
    );
    expect(shots.controller!.text, '30');
    expect(distance.controller!.text, '50');

    await tester.tap(find.byTooltip('Enregistrer la session libre'));
    await tester.pump();
    expect(find.text('La date est obligatoire.'), findsOneWidget);
    expect(Hive.box('sessions').isEmpty, isTrue);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(Hive.box('sessions').isEmpty, isTrue);
  });

  testWidgets('aucune action de duplication sur un brouillon guidé',
      (tester) async {
    final draft = DetailedShootingSession(
      id: 2,
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      status: SessionConstants.statusDraft,
      series: [
        Series(
          distance: 25,
          points: 0,
          groupSize: 0,
          isCompleted: false,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SessionDetailScreen(
          sessionData: {
            'session': draft.toMap(),
            'series': draft.series.map((item) => item.toMap()).toList(),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Dupliquer la session'), findsNothing);
  });
}
