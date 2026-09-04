import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/widgets/dashboard/dashboard_tab_view.dart';
import 'package:tir_sportif/widgets/dashboard/weapon_shot_counts_card.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('dashboard_nt142_');
    Hive.init(directory.path);
    await Hive.openBox('weapons', bytes: Uint8List(0));
  });

  tearDownAll(() async => Hive.close());

  testWidgets('Tirs par arme est la dernière carte de Synthèse uniquement',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DashboardTabView(sessions: [])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WeaponShotCountsCard), findsOneWidget);
    final summaryScroll = find.byType(SingleChildScrollView).first;
    await tester.drag(summaryScroll, const Offset(0, -4000));
    await tester.pumpAndSettle();
    expect(find.text('Tirs par arme'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Répartition Calibres')).dy,
      lessThan(tester.getTopLeft(find.text('Tirs par arme')).dy),
    );

    await tester.tap(find.text('Avancé'));
    await tester.pumpAndSettle();
    expect(find.text('Tirs par arme'), findsNothing);
    expect(find.byType(WeaponShotCountsCard), findsNothing);
  });
}
