import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/session_detail_screen.dart';

void main() {
  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('nt_detail133_');
    Hive.init(directory.path);
    await Hive.openBox('sessions', bytes: Uint8List(0));
    await Hive.openBox('exercises', bytes: Uint8List(0));
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('sessions')) await Hive.box('sessions').close();
    if (Hive.isBoxOpen('exercises')) await Hive.box('exercises').close();
  });

  testWidgets('le détail libre affiche ses données sans séries ni Coach',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = SimpleShootingSession(
      id: 1,
      date: DateTime(2026, 9, 3),
      weapon: 'Pistolet libre',
      caliber: 'calibre libre',
      shotCount: 18,
      distance: 12,
      synthese: 'Synthèse libre',
      exercises: const ['ex-libre'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SessionDetailScreen(
          sessionData: {'session': session.toMap(), 'series': const []},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Session libre'), findsWidgets);
    expect(find.text('18 tirs'), findsOneWidget);
    expect(find.text('12 m'), findsOneWidget);
    expect(find.text('Synthèse libre'), findsOneWidget);
    expect(find.text('ex-libre'), findsOneWidget);
    expect(find.text('Analyse Coach'), findsNothing);
    expect(find.text('Séries'), findsNothing);
    expect(find.byTooltip('Modifier'), findsOneWidget);
    expect(find.byTooltip('Supprimer'), findsOneWidget);
  });
}
