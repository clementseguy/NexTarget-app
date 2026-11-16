import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/widgets/session_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(AppConfig.load);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt_session_exercise_');
    Hive.init(directory.path);
    await Hive.openBox('app_preferences');
    final exercises = await Hive.openBox('exercises');
    for (final exercise in [
      Exercise(
        id: 'exercise-a',
        name: 'Exercice A',
        categoryEnum: ExerciseCategory.technique,
        type: ExerciseType.stand,
        createdAt: DateTime(2026),
        priority: 1,
      ),
      Exercise(
        id: 'exercise-b',
        name: 'Exercice B',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026),
        priority: 2,
      ),
    ]) {
      await exercises.put(exercise.id, exercise.toMap());
    }
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'changer d’exercice efface sa qualification précédente',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ShootingSession? saved;
      final formKey = GlobalKey<SessionFormState>();
      final initialData = {
        'session': {
          'weapon': 'Pistolet 22',
          'caliber': '.22 LR',
          'status': SessionConstants.statusRealisee,
          'category': SessionConstants.categoryEntrainement,
          'date': '2026-11-16T10:00:00.000Z',
          'synthese': '',
          'exerciseId': 'exercise-a',
          'exerciseExecution': {
            'performed': true,
            'protocolFollowed': 'yes',
            'comment': 'Qualification de l’exercice A',
          },
        },
        'series': [
          {
            'shot_count': 5,
            'distance': 25,
            'points': 45,
            'group_size': 8.0,
            'comment': '',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionForm(
              key: formKey,
              initialSessionData: initialData,
              isEdit: true,
              onSave: (session) => saved = session,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Exercice B'), findsOneWidget);

      expect(formKey.currentState!.validateAndBuild(), isTrue);
      expect(saved!.exerciseId, 'exercise-a');
      expect(saved!.exerciseExecution?.performed, isTrue);

      await tester.tap(find.text('Exercice B'));
      await tester.pump();

      expect(formKey.currentState!.validateAndBuild(), isTrue);
      expect(saved!.exerciseId, 'exercise-b');
      expect(saved!.exerciseExecution, isNull);
    },
  );
}
