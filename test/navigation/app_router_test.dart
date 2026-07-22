import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/session_setup_template.dart';
import 'package:tir_sportif/navigation/app_router.dart';
import 'package:tir_sportif/providers/navigation_provider.dart';
import 'package:tir_sportif/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('nt_router_test_');
    Hive.init(dir.path);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences', bytes: Uint8List(0));
    }
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.openBox('sessions', bytes: Uint8List(0));
    }
    if (!Hive.isBoxOpen('exercises')) {
      await Hive.openBox('exercises', bytes: Uint8List(0));
    }
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
    await Hive.box('sessions').clear();
    await Hive.box('exercises').clear();
  });

  test('plannedSessionTemplate reprend le dernier calibre connu', () async {
    await PreferencesService().setLastCaliber('40 s&w');

    final data = AppNavigator.plannedSessionTemplate();
    final session = data['session'] as Map<String, dynamic>;

    expect(session['status'], SessionConstants.statusPrevue);
    expect(session['category'], SessionConstants.categoryEntrainement);
    expect(session['caliber'], '.40 S&W');
    expect(data['series'], isEmpty);
  });

  test('generateRoute résout les routes connues et inconnues', () {
    final routeNames = [
      AppRouter.home,
      AppRouter.dashboard,
      AppRouter.login,
      AppRouter.coach,
      AppRouter.exercises,
      AppRouter.sessions,
      AppRouter.settings,
      AppRouter.createSession,
      AppRouter.editGoal,
      AppRouter.exercisesList,
      '/#access_token=abc',
      '/mystery',
    ];

    for (final name in routeNames) {
      final route = AppRouter.generateRoute(
        RouteSettings(
          name: name,
          arguments:
              name == AppRouter.createSession || name == AppRouter.editGoal
                  ? <String, dynamic>{}
                  : null,
        ),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
    }
  });

  testWidgets('le quick create sheet affiche dernier setup, favoris et vide',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final prefs = PreferencesService();
    await prefs.setLastSessionSetup(
      SessionSetupTemplate(
        id: 'last_setup',
        name: 'Dernier setup',
        weapon: 'Pistolet A',
        caliber: '.22 LR',
        category: SessionConstants.categoryEntrainement,
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    await prefs.saveSessionSetupFavorite(
      SessionSetupTemplate(
        id: 'fav_1',
        name: 'Favori TAR',
        weapon: 'MAS 45',
        caliber: '.22 LR',
        category: 'match',
        disciplineCode: '820',
        updatedAt: DateTime(2026, 1, 2),
      ),
    );

    final navigation = NavigationProvider()..goToSessions();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: navigation,
        child: MaterialApp(home: AppNavigator()),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Dernier setup'), findsOneWidget);
    expect(find.text('Pistolet A - .22 LR - entraînement'), findsOneWidget);
    expect(find.text('Favori TAR'), findsOneWidget);
    expect(find.text('MAS 45 - .22 LR - match - 820'), findsOneWidget);
    expect(find.text('Vide'), findsOneWidget);
  });
}
