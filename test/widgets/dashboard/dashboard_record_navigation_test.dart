import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/session_detail_screen.dart';
import 'package:tir_sportif/widgets/dashboard/dashboard_tab_view.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
    Hive.init(Directory.systemTemp.createTempSync('records_navigation_').path);
    await Hive.openBox('weapons', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
  });

  tearDownAll(Hive.close);

  testWidgets('les cartes ouvrent directement la source puis rafraîchissent',
      (tester) async {
    var refreshes = 0;
    final session = DetailedShootingSession(
      id: 7,
      date: DateTime(2026, 8, 1),
      weapon: 'Pistolet',
      caliber: '9 mm',
      series: [Series(distance: 25, points: 48, groupSize: 7)],
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardTabView(
          sessions: [session],
          onRecordsChanged: () async => refreshes++,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meilleur Score'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect(find.text('Pistolet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(refreshes, 1);

    await tester.tap(find.text('Meilleur Groupement'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(refreshes, 2);
  });
}
