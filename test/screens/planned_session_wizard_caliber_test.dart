import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/wizard/planned_session_wizard.dart';
import 'package:tir_sportif/widgets/caliber_autocomplete_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    await AppConfig.load();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt073_wizard_');
    Hive.init(directory.path);
    await Hive.openBox('app_preferences');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('le wizard conserve le calibre prévu et laisse la saisie libre',
      (tester) async {
    await Hive.box('app_preferences').put('default_caliber', '.45 ACP');
    final session = ShootingSession(
      date: DateTime(2026, 9, 3),
      weapon: 'Pistolet',
      caliber: '9 mm perso',
      status: SessionConstants.statusPrevue,
      category: SessionConstants.categoryEntrainement,
      series: const [],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlannedSessionWizard(session: session)),
    );
    await tester.pump();
    final field = tester.widget<CaliberAutocompleteField>(
      find.byType(CaliberAutocompleteField),
    );
    expect(field.controller.text, '9 mm perso');

    await tester.enterText(find.byType(TextFormField).at(1), 'calibre maison');
    await tester.pump();
    expect(field.controller.text, 'calibre maison');
  }, timeout: const Timeout(Duration(seconds: 2)));
}
