import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/widgets/caliber_autocomplete_field.dart';
import 'package:tir_sportif/widgets/session_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    await AppConfig.load();
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt073_form_');
    Hive.init(directory.path);
    await Hive.openBox('app_preferences');
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Map<String, dynamic> data(String caliber) => {
        'session': {
          'weapon': '',
          'caliber': caliber,
          'status': SessionConstants.statusPrevue,
          'category': SessionConstants.categoryEntrainement,
          'synthese': '',
          'exercises': <String>[],
        },
        'series': <dynamic>[],
      };

  Future<String> pumpForm(
    WidgetTester tester, {
    Map<String, dynamic>? initialData,
    bool isEdit = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionForm(
            initialSessionData: initialData,
            isEdit: isEdit,
            onSave: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.widget<CaliberAutocompleteField>(
      find.byType(CaliberAutocompleteField),
    ).controller.text;
  }

  testWidgets('la préférence vide ne préremplit pas une création', (tester) async {
    expect(await pumpForm(tester), '');
  });

  testWidgets('la préférence préremplit les créations réalisée et prévue',
      (tester) async {
    await Hive.box('app_preferences').put('default_caliber', '.45 ACP');
    expect(await pumpForm(tester), '.45 ACP');
    await tester.pumpWidget(const SizedBox());
    expect(await pumpForm(tester, initialData: data('')), '.45 ACP');
  });

  testWidgets('une édition conserve exactement la valeur enregistrée',
      (tester) async {
    await Hive.box('app_preferences').put('default_caliber', '.45 ACP');
    expect(
      await pumpForm(tester, initialData: data('9 mm perso'), isEdit: true),
      '9 mm perso',
    );
  });
}
