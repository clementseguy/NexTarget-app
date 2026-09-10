import 'dart:async';
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

class _FailingSettingsAuthService extends AuthService {
  _FailingSettingsAuthService() : super(authBaseUrl: 'http://unused');

  int calls = 0;

  @override
  Future<bool> hasToken() async => false;

  @override
  Future<void> signInWithGoogle() async {
    calls++;
    throw TimeoutException('détail technique interne');
  }
}

class _NoTokenAuthService extends AuthService {
  _NoTokenAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<bool> hasToken() async => false;
}

void main() {
  setUpAll(() async {
    await AppConfig.load();
    final directory = await Directory.systemTemp.createTemp('settings_order_');
    Hive.init(directory.path);
    for (final boxName in [
      'app_preferences',
      'sessions',
      'weapons',
      'exercises',
      'goals',
    ]) {
      await Hive.openBox(boxName, bytes: Uint8List(0));
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  Future<void> pumpSettings(
    WidgetTester tester, {
    required String theme,
    AuthService? authService,
  }) async {
    await Hive.box('app_preferences').put('app_theme', theme);
    await Hive.box('app_preferences').put(
      'coach_data_sharing_allowed',
      false,
    );
    final authProvider = AuthProvider(authService ?? _NoTokenAuthService());
    await authProvider.checkAuthStatus();
    await tester.binding.setSurfaceSize(const Size(390, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('une case unique persiste le consentement Coach', (tester) async {
    await pumpSettings(tester, theme: 'classique');

    expect(find.byType(CheckboxListTile), findsOneWidget);
    expect(
      find.text('Partager les données avec les Coachs'),
      findsOneWidget,
    );
    expect(find.byTooltip('Pourquoi partager les données ?'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    expect(
      Hive.box('app_preferences').get('coach_data_sharing_allowed'),
      isTrue,
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );

    await tester.tap(find.byTooltip('Pourquoi partager les données ?'));
    await tester.pumpAndSettle();

    expect(find.text('Partage des données'), findsOneWidget);
    expect(
      find.text(
        'Pour être utilisés, les Coachs ont besoin d’analyser les données de vos sessions. Si vous ne souhaitez pas partager vos données, les Coachs ne peuvent pas être utilisés.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('supprim'), findsNothing);
    expect(find.textContaining('transmis'), findsNothing);
  });

  for (final theme in ['classique', 'bleuBlancRouge']) {
    testWidgets('ordre complet des paramètres en thème $theme', (tester) async {
      await pumpSettings(tester, theme: theme);

      double top(String text) => tester.getTopLeft(find.text(text).first).dy;

      expect(
        top('Préférences Tir'),
        lessThan(top('Sauvegardes & Portabilité')),
      );
      expect(top('Sauvegardes & Portabilité'), lessThan(top('Coach IA')));
      expect(top('Coach IA'), lessThan(top('Thème')));
      expect(top('Thème'), lessThan(top('Aide')));

      expect(
        top('Prise par défaut (pistolet)'),
        lessThan(top("Râtelier d'armes")),
      );
      expect(top("Râtelier d'armes"), lessThan(top('Calibre par défaut')));
      expect(find.byType(Divider), findsNWidgets(2));
      final dividerTops = [
        tester.getTopLeft(find.byType(Divider).at(0)).dy,
        tester.getTopLeft(find.byType(Divider).at(1)).dy,
      ];
      expect(
        top('Prise par défaut (pistolet)'),
        lessThan(dividerTops.first),
      );
      expect(dividerTops.first, lessThan(top("Râtelier d'armes")));
      expect(top("Râtelier d'armes"), lessThan(dividerTops.last));
      expect(dividerTops.last, lessThan(top('Calibre par défaut')));

      expect(
        top('Exporter toutes les sessions'),
        lessThan(top('Importer des sessions')),
      );
      expect(
        top('Importer des sessions'),
        lessThan(
          top(
            'Les exports ne chiffrent pas les données. Ne partage pas le fichier si tu ne fais pas confiance au destinataire.',
          ),
        ),
      );
      expect(
        top(
          'Les exports ne chiffrent pas les données. Ne partage pas le fichier si tu ne fais pas confiance au destinataire.',
        ),
        lessThan(top('Coach IA')),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('le login Paramètres masque le détail et propose Réessayer', (
    tester,
  ) async {
    final service = _FailingSettingsAuthService();
    await pumpSettings(tester, theme: 'classique', authService: service);

    await tester.tap(find.byTooltip('Se connecter'));
    await tester.pump();

    expect(
      find.text('Le service met trop de temps à répondre.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('technique'), findsNothing);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();
    expect(service.calls, 2);
  });
}
