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
import 'package:tir_sportif/widgets/group_size_help.dart';

void main() {
  late Directory directory;

  setUpAll(AppConfig.load);
  setUp(() async {
    directory = Directory.systemTemp.createTempSync('wizard_group_help_');
    Hive.init(directory.path);
    await Hive.openBox('weapons', bytes: Uint8List(0));
    await Hive.openBox('app_preferences', bytes: Uint8List(0));
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('l’aide groupement du wizard conserve le champ', (tester) async {
    final session = DetailedShootingSession(
      id: 12,
      date: DateTime(2026, 9, 4),
      weapon: 'Pistolet',
      caliber: '9 mm',
      status: SessionConstants.statusPrevue,
      series: [Series(distance: 25, points: 0, groupSize: 0)],
    );
    await tester.pumpWidget(
      MaterialApp(home: PlannedSessionWizard(session: session)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    final groupField = find.widgetWithText(TextFormField, 'Groupement');
    await tester.enterText(groupField, '9');
    expect(find.byType(GroupSizeHelpButton), findsOneWidget);
    await tester.tap(find.byType(GroupSizeHelpButton));
    await tester.pumpAndSettle();
    expect(find.textContaining('moins de 10 cm'), findsOneWidget);
    expect(find.textContaining('environ 15 cm'), findsOneWidget);
    expect(find.textContaining('environ 20 cm'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<EditableText>(
            find.descendant(
                of: groupField, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      '9',
    );
  });
}
