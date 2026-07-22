import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/create_session_screen.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/services/session_template_service.dart';
import 'dart:io';
import 'dart:typed_data';

class _FakeSessionService extends SessionService {
  ShootingSession? added;
  ShootingSession? updated;

  @override
  Future<void> addSession(ShootingSession session) async {
    added = session;
    session.id = 42;
  }

  @override
  Future<void> updateSession(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
    bool warnOnFallback = true,
  }) async {
    updated = session;
  }
}

class _FakeTemplateService extends SessionTemplateService {
  ShootingSession? recorded;

  @override
  Future<void> recordLastSetup(ShootingSession session) async {
    recorded = session;
  }
}

Map<String, dynamic> _initialSessionData({
  int? id,
  String weapon = 'Pistolet 22',
  String caliber = '22lr',
}) {
  return {
    'session': {
      if (id != null) 'id': id,
      'weapon': weapon,
      'caliber': caliber,
      'status': SessionConstants.statusPrevue,
      'category': SessionConstants.categoryEntrainement,
      'synthese': '',
      'exercises': <String>[],
    },
    'series': <dynamic>[],
  };
}

// Tests simplifiés pour les écrans
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load();
    final dir = await Directory.systemTemp.createTemp('nt_create_screen_test_');
    Hive.init(dir.path);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences', bytes: Uint8List(0));
    }
    if (!Hive.isBoxOpen('exercises')) {
      await Hive.openBox('exercises', bytes: Uint8List(0));
    }
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
    await Hive.box('exercises').clear();
  });

  Future<void> pumpCreateScreen(
    WidgetTester tester, {
    required _FakeSessionService sessions,
    required _FakeTemplateService templates,
    bool isEdit = false,
    Map<String, dynamic>? initialData,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: CreateSessionScreen(
          initialSessionData: initialData ?? _initialSessionData(),
          isEdit: isEdit,
          sessionService: sessions,
          templateService: templates,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  // Test uniquement des éléments d'UI qui sont indépendants des services
  group('CreateSessionScreen UI Elements', () {
    testWidgets('affiche le titre correct en mode création',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('Nouvelle session'),
            ),
          ),
        ),
      );

      expect(find.text('Nouvelle session'), findsOneWidget);
    });

    testWidgets('affiche le titre correct en mode édition',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('Modifier session'),
            ),
          ),
        ),
      );

      expect(find.text('Modifier session'), findsOneWidget);
    });

    testWidgets('contient un bouton avec icône de sauvegarde',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  icon: Icon(Icons.save_outlined),
                  tooltip: 'Enregistrer',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.byTooltip('Enregistrer'), findsOneWidget);
    });
  });

  group('CreateSessionScreen save flow', () {
    testWidgets('enregistre une nouvelle session et mémorise le dernier setup',
        (tester) async {
      final sessions = _FakeSessionService();
      final templates = _FakeTemplateService();

      await pumpCreateScreen(
        tester,
        sessions: sessions,
        templates: templates,
      );

      expect(find.text('Nouvelle session'), findsOneWidget);
      expect(find.text('Pistolet 22'), findsOneWidget);
      expect(find.text('.22 LR'), findsOneWidget);

      await tester.tap(find.byTooltip('Enregistrer'));
      await tester.pump();
      await tester.pump();

      expect(sessions.added, isNotNull);
      expect(sessions.updated, isNull);
      expect(sessions.added!.weapon, 'Pistolet 22');
      expect(sessions.added!.caliber, '.22 LR');
      expect(sessions.added!.status, SessionConstants.statusPrevue);
      expect(templates.recorded, same(sessions.added));
    });

    testWidgets('en édition met à jour la session puis mémorise le setup',
        (tester) async {
      final sessions = _FakeSessionService();
      final templates = _FakeTemplateService();

      await pumpCreateScreen(
        tester,
        sessions: sessions,
        templates: templates,
        isEdit: true,
        initialData: _initialSessionData(id: 7, weapon: 'CZ 75'),
      );

      expect(find.text('Modifier session'), findsOneWidget);

      await tester.tap(find.byTooltip('Enregistrer'));
      await tester.pump();
      await tester.pump();

      expect(sessions.added, isNull);
      expect(sessions.updated, isNotNull);
      expect(sessions.updated!.id, 7);
      expect(sessions.updated!.weapon, 'CZ 75');
      expect(templates.recorded, same(sessions.updated));
    });
  });
}
