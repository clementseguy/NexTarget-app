import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/screens/settings_screen.dart';
import 'package:tir_sportif/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  bool signInCalled = false;

  _FakeAuthService() : super(authBaseUrl: 'https://example.test');

  @override
  Future<void> signInWithGoogle() async {
    signInCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load();
    final dir = await Directory.systemTemp.createTemp('nt_settings_test_');
    Hive.init(dir.path);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences', bytes: Uint8List(0));
    }
  });

  setUp(() async {
    await Hive.box('app_preferences').clear();
  });

  Future<_FakeAuthService> pumpSettings(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 3600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authService = _FakeAuthService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(
              preferencesBox: Hive.box('app_preferences'),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
    return authService;
  }

  group('SettingsScreen', () {
    testWidgets('affiche les préférences tir et met à jour la prise par défaut',
        (tester) async {
      final box = Hive.box('app_preferences');
      await box.put('default_hand_method', 'two');
      await box.put('default_caliber', '.22 LR');

      await pumpSettings(tester);

      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('Préférences Tir'), findsOneWidget);
      expect(find.text('Prise par défaut (pistolet)'), findsOneWidget);
      expect(find.text('Calibre par défaut'), findsOneWidget);
      expect(find.text('.22 LR'), findsOneWidget);

      await tester.tap(find.text('1 main'));
      await tester.pump();

      expect(box.get('default_hand_method'), 'one');
      expect(find.text('Prise par défaut: 1 main'), findsOneWidget);
    });

    testWidgets('sélectionner un calibre dans l’autocomplete le persiste',
        (tester) async {
      final box = Hive.box('app_preferences');

      await pumpSettings(tester);

      await tester
          .tap(find.widgetWithText(TextFormField, 'Calibre (prérempli)'));
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calibre (prérempli)'),
        '45',
      );
      await tester.pump();
      await tester.tap(find.text('.45 ACP').last);
      await tester.pump();

      expect(box.get('default_caliber'), '.45 ACP');
      expect(find.text('Calibre par défaut: .45 ACP'), findsOneWidget);
    });

    testWidgets('le bouton connexion déclenche le provider d’authentification',
        (tester) async {
      final authService = await pumpSettings(tester);

      await tester.tap(find.byTooltip('Se connecter'));
      await tester.pump();

      expect(authService.signInCalled, isTrue);
    });
  });
}
