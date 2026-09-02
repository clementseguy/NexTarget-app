import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/widgets/settings/default_caliber_setting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    await AppConfig.load();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt073_setting_');
    Hive.init(directory.path);
    await Hive.openBox('app_preferences');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('seule une suggestion sélectionnée est persistée', (tester) async {
    final provider = SettingsProvider(
      preferencesBox: Hive.box('app_preferences'),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          home: Scaffold(body: DefaultCaliberSetting()),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'calibre maison');
    await tester.pump();
    expect(provider.defaultCaliber, isNull);

    await tester.enterText(find.byType(TextFormField), '45');
    await tester.pump();
    await tester.tap(find.text('.45 ACP'));
    await tester.pump();
    expect(provider.defaultCaliber, '.45 ACP');

    await tester.tap(find.byTooltip('Aucun calibre par défaut'));
    await tester.pump();
    expect(provider.defaultCaliber, isNull);
  });
}
