import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/wizard/planned_session_wizard.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/session_template_service.dart';

class _FakeSessionService extends SessionService {
  ShootingSession? convertedSession;
  String? convertedWeapon;
  String? convertedCaliber;
  String? convertedCategory;
  String? convertedSynthese;
  Series? updatedSeries;

  @override
  Future<ShootingSession> convertPlannedToRealized({
    required ShootingSession session,
    String? weapon,
    String? caliber,
    String? category,
    String? synthese,
    DateTime? forcedDate,
    List<Series>? updatedSeries,
  }) async {
    convertedSession = session;
    convertedWeapon = weapon;
    convertedCaliber = caliber;
    convertedCategory = category;
    convertedSynthese = synthese;
    session
      ..weapon = weapon ?? session.weapon
      ..caliber = caliber ?? session.caliber
      ..category = category ?? session.category
      ..synthese = synthese
      ..status = SessionConstants.statusRealisee;
    return session;
  }

  @override
  Future<void> updateSingleSeries(
    ShootingSession session,
    int seriesIndex,
    Series newSeries,
  ) async {
    updatedSeries = newSeries;
    session.series[seriesIndex] = newSeries;
  }
}

class _FakeTemplateService extends SessionTemplateService {
  ShootingSession? recorded;

  @override
  Future<void> recordLastSetup(ShootingSession session) async {
    recorded = session;
  }
}

ShootingSession _plannedSession({List<Series> series = const []}) {
  return ShootingSession(
    weapon: 'Pistolet',
    caliber: '',
    status: SessionConstants.statusPrevue,
    category: SessionConstants.categoryEntrainement,
    synthese: 'Session créée à partir de Précision',
    series: List<Series>.from(series),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load();
    final dir = await Directory.systemTemp.createTemp('nt_wizard_test_');
    Hive.init(dir.path);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences', bytes: Uint8List(0));
    }
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
  });

  Future<void> pumpWizard(
    WidgetTester tester, {
    required ShootingSession session,
    required _FakeSessionService sessions,
    required _FakeTemplateService templates,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PlannedSessionWizard(
          session: session,
          sessionService: sessions,
          templateService: templates,
        ),
      ),
    );
    await tester.pump();
  }

  group('PlannedSessionWizard', () {
    testWidgets(
        'préremplit le calibre par défaut et le canonise à la conversion',
        (tester) async {
      await Hive.box('app_preferences').put('default_caliber', '22lr');
      final sessions = _FakeSessionService();
      final templates = _FakeTemplateService();
      final session = _plannedSession();

      await pumpWizard(
        tester,
        session: session,
        sessions: sessions,
        templates: templates,
      );

      final caliberField = tester
          .widget<TextFormField>(find.widgetWithText(TextFormField, 'Calibre'));
      expect(caliberField.controller!.text, '.22 LR');

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Calibre'), '9 x 19 mm');
      await tester.tap(find.text('Commencer'));
      await tester.pump();
      expect(find.text('Synthèse'), findsWidgets);

      await tester.tap(find.text('Terminer'));
      await tester.pump();
      await tester.pump();

      expect(sessions.convertedSession, same(session));
      expect(sessions.convertedCaliber, '9mm (9x19)');
      expect(
        sessions.convertedSynthese,
        'Session créée à partir de Précision\n',
      );
      expect(templates.recorded, same(session));
      expect(session.status, SessionConstants.statusRealisee);
    });

    testWidgets('valide une série prévue avec la prise par défaut une main',
        (tester) async {
      await Hive.box('app_preferences').put('default_hand_method', 'one');
      final sessions = _FakeSessionService();
      final templates = _FakeTemplateService();
      final session = _plannedSession(
        series: [
          Series(
            distance: 1,
            points: 0,
            groupSize: 0,
            shotCount: 1,
            comment: '5 coups précision',
            handMethod: HandMethod.twoHands,
          ),
        ],
      );

      await pumpWizard(
        tester,
        session: session,
        sessions: sessions,
        templates: templates,
      );

      await tester.tap(find.text('Commencer'));
      await tester.pump();
      expect(find.text('5 coups précision'), findsOneWidget);

      await tester.tap(find.text('Suite'));
      await tester.pump();
      expect(find.text('Champs requis: Points, Groupement, Commentaire'),
          findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Points'), '47');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Groupement'), '18.5');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Commentaire série'),
        'Bonne tenue',
      );
      await tester.tap(find.text('Suite'));
      await tester.pump();

      expect(sessions.updatedSeries, isNotNull);
      expect(sessions.updatedSeries!.points, 47);
      expect(sessions.updatedSeries!.groupSize, 18.5);
      expect(sessions.updatedSeries!.shotCount, 5);
      expect(sessions.updatedSeries!.distance, 25);
      expect(sessions.updatedSeries!.comment, 'Bonne tenue');
      expect(sessions.updatedSeries!.handMethod, HandMethod.oneHand);
      expect(find.text('Synthèse'), findsWidgets);
    });
  });
}
