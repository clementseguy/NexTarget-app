import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/interfaces/session_photo_service_interface.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/widgets/session_form.dart';
import 'package:tir_sportif/widgets/session_form/session_form_components.dart';
import 'package:tir_sportif/widgets/simple_session_form.dart';

class _PhotoService implements ISessionPhotoService {
  String? nextPath;
  final deleted = <String>[];

  @override
  Future<void> deleteIfExists(String? path) async {
    if (path != null) deleted.add(path);
  }

  @override
  Future<String?> pickAndStore(ImageSource source) async => nextPath;
}

void main() {
  setUpAll(() async {
    await AppConfig.load();
    final directory = await Directory.systemTemp.createTemp('nt_forms133_');
    Hive.init(directory.path);
    for (final name in [
      'sessions',
      'exercises',
      'weapons',
      'app_preferences'
    ]) {
      await Hive.openBox(name, bytes: Uint8List(0));
    }
  });

  tearDownAll(() async {
    for (final name in [
      'sessions',
      'exercises',
      'weapons',
      'app_preferences'
    ]) {
      if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    }
  });

  testWidgets('construit une session libre valide avec photo et saisie libre',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<SimpleSessionFormState>();
    final photoService = _PhotoService()..nextPath = '/nouvelle-cible.jpg';
    SimpleShootingSession? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleSessionForm(
            key: key,
            photoService: photoService,
            onSave: (session) => saved = session,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Arme').first,
      'Arme libre',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calibre').first,
      'Calibre personnel',
    );
    await tester.enterText(find.byKey(const Key('simpleShotCount')), '35');
    await tester.enterText(find.byKey(const Key('simpleDistance')), '25');
    await tester.tap(find.text('Galerie'));
    await tester.pump();

    expect(key.currentState!.validateAndBuild(), isTrue);
    expect(saved, isNotNull);
    expect(saved!.weapon, 'Arme libre');
    expect(saved!.caliber, 'Calibre personnel');
    expect(saved!.shotCount, 35);
    expect(saved!.distance, 25);
    expect(saved!.photoPath, '/nouvelle-cible.jpg');
  });

  testWidgets('reprend la date et la ligne arme-calibre du formulaire détaillé',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleSessionForm(onSave: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FormSummaryHeader), findsOneWidget);
    expect(find.byType(MiniStat), findsNothing);
    final weapon = find.widgetWithText(TextFormField, 'Arme').first;
    final caliber = find.widgetWithText(TextFormField, 'Calibre').first;
    expect(tester.getTopLeft(weapon).dy, tester.getTopLeft(caliber).dy);
  });

  testWidgets('refuse zéro et les champs obligatoires vides', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<SimpleSessionFormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SimpleSessionForm(key: key, onSave: (_) {}),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('simpleShotCount')), '0');
    await tester.enterText(find.byKey(const Key('simpleDistance')), '0');

    expect(key.currentState!.validateAndBuild(), isFalse);
    await tester.pump();
    expect(find.text('Entier positif requis'), findsNWidgets(2));
  });

  testWidgets(
      'une distance historique décimale détaillée n’est pas réécrite et bloque la modification',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey<SessionFormState>();
    ShootingSession? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionForm(
            key: key,
            isEdit: true,
            initialSessionData: {
              'session': {
                'id': 1,
                'date': '2026-09-01T00:00:00.000',
                'weapon': 'P',
                'caliber': '9mm',
                'status': 'réalisée',
              },
              'series': [
                {
                  'shot_count': 5,
                  'distance': 12.5,
                  'points': 40,
                  'group_size': 5,
                  'comment': '',
                },
              ],
            },
            onSave: (session) => saved = session,
          ),
        ),
      ),
    );
    await tester.pump();

    final distance = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Distance').first,
    );
    expect(distance.controller!.text, '12.5');
    expect(key.currentState!.validateAndBuild(), isFalse);
    await tester.pump();
    expect(saved, isNull);
    expect(find.text('Entier requis'), findsOneWidget);
  });
}
