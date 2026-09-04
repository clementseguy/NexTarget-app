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
  }) async {
    await Hive.box('app_preferences').put('app_theme', theme);
    await tester.binding.setSurfaceSize(const Size(390, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              AuthService(authBaseUrl: 'https://example.invalid'),
            ),
          ),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final theme in ['classique', 'bleuBlancRouge']) {
    testWidgets('ordre complet des paramètres en thème $theme', (tester) async {
      await pumpSettings(tester, theme: theme);

      double top(String text) => tester.getTopLeft(find.text(text).first).dy;

      expect(
          top('Préférences Tir'), lessThan(top('Sauvegardes & Portabilité')));
      expect(top('Sauvegardes & Portabilité'), lessThan(top('Coach IA')));
      expect(top('Coach IA'), lessThan(top('Thème')));
      expect(top('Thème'), lessThan(top('Aide')));

      expect(
        top('Prise par défaut (pistolet)'),
        lessThan(top("Râtelier d'armes")),
      );
      expect(top("Râtelier d'armes"), lessThan(top('Calibre par défaut')));

      expect(
        top('Exporter toutes les sessions'),
        lessThan(top('Importer des sessions')),
      );
      expect(
        top('Importer des sessions'),
        lessThan(top(
          'Les exports ne chiffrent pas les données. Ne partage pas le fichier si tu ne fais pas confiance au destinataire.',
        )),
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
}
