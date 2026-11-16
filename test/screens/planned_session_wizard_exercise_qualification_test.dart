import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/exercise_execution.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/wizard/planned_session_wizard.dart';
import 'package:tir_sportif/screens/wizard/wizard_steps.dart';
import 'package:tir_sportif/widgets/caliber_autocomplete_field.dart';
import 'package:tir_sportif/widgets/weapon_autocomplete_field.dart';

void main() {
  late Directory directory;

  setUpAll(AppConfig.load);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt154_wizard_');
    Hive.init(directory.path);
    await Hive.openBox('weapons');
    await Hive.openBox('exercises');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('qualification proposes every optional answer and help',
      (tester) async {
    bool? performed;
    ProtocolFollowed? protocolFollowed;
    String? comment;
    String? synthese;
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardExerciseQualificationStep(
            formKey: formKey,
            initialSynthese: 'Synthèse initiale',
            initialPerformed: null,
            initialProtocolFollowed: null,
            initialComment: null,
            saving: false,
            onSyntheseSaved: (value) => synthese = value,
            onPerformedChanged: (value) => performed = value,
            onProtocolFollowedChanged: (value) => protocolFollowed = value,
            onCommentSaved: (value) => comment = value,
            onFinish: () => formKey.currentState?.save(),
          ),
        ),
      ),
    );

    expect(find.text('Synthèse de la session'), findsOneWidget);
    expect(find.text('Synthèse du tireur'), findsOneWidget);
    expect(find.text('Analyse de l’exercice'), findsOneWidget);
    expect(find.text('Exercice réalisé'), findsOneWidget);
    expect(find.text('Protocole suivi'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Tooltip &&
            (widget.message ?? '').contains('du début à la fin'),
      ),
      findsNWidgets(2),
    );
    await tester.tap(find.byType(Tooltip).first);
    await tester.pump();
    expect(
      find.textContaining('réussi à faire l’exercice du début à la fin'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.tap(find.byType(Tooltip).last);
    await tester.pump();
    expect(
      find.textContaining('réussi à suivre le protocole proposé'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('session_synthese')),
      'Nouvelle synthèse',
    );

    await tester.tap(find.byKey(const ValueKey('exercise_performed')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oui').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('protocol_followed')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partiellement').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('exercise_comment')),
      'Exercice interrompu puis repris',
    );
    await tester.ensureVisible(find.text('Terminer'));
    await tester.pump();
    await tester.tap(find.text('Terminer'));

    expect(performed, isTrue);
    expect(protocolFollowed, ProtocolFollowed.partially);
    expect(comment, 'Exercice interrompu puis repris');
    expect(synthese, 'Nouvelle synthèse');
  });

  testWidgets('qualification can remain entirely unanswered', (tester) async {
    var finished = false;
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardExerciseQualificationStep(
            formKey: formKey,
            initialSynthese: '',
            initialPerformed: null,
            initialProtocolFollowed: null,
            initialComment: null,
            saving: false,
            onSyntheseSaved: (_) {},
            onPerformedChanged: (_) {},
            onProtocolFollowedChanged: (_) {},
            onCommentSaved: (_) {},
            onFinish: () => finished = true,
          ),
        ),
      ),
    );

    expect(find.text('Non renseigné'), findsNWidgets(2));
    await tester.ensureVisible(find.text('Terminer'));
    await tester.pump();
    await tester.tap(find.text('Terminer'));
    expect(finished, isTrue);
  });

  testWidgets('planned wizard enriches synthesis only for an exercise session',
      (tester) async {
    Future<void> openFinalPage(String? exerciseId) async {
      final session = DetailedShootingSession(
        weapon: 'Pistolet',
        caliber: '9 mm',
        series: const [],
        status: SessionConstants.statusPrevue,
        exerciseId: exerciseId,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PlannedSessionWizard(
            key: ValueKey(exerciseId ?? 'without-exercise'),
            session: session,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();
    }

    await openFinalPage('exercise-1');
    expect(find.byType(WizardExerciseQualificationStep), findsOneWidget);
    expect(find.byType(WizardSyntheseStep), findsNothing);
    expect(find.text('Synthèse du tireur'), findsOneWidget);
    expect(find.text('Analyse de l’exercice'), findsOneWidget);

    await openFinalPage(null);
    expect(find.byType(WizardExerciseQualificationStep), findsNothing);
    expect(find.byType(WizardSyntheseStep), findsOneWidget);
  });

  testWidgets('intro uses full-width exercise metadata and separated selects',
      (tester) async {
    final exercise = Exercise(
      id: 'exercise-card',
      name: 'Exercice complet',
      categoryEnum: ExerciseCategory.precision,
      type: ExerciseType.stand,
      durationMinutes: 25,
      equipment: 'Timer et deux cibles',
      createdAt: DateTime(2026, 9, 11),
      consignes: List.generate(10, (index) => 'Consigne ${index + 1}'),
    );
    final weaponController = TextEditingController(text: 'Pistolet');
    final caliberController = TextEditingController(text: '9 mm');
    final caliberFocusNode = FocusNode();
    String? selectedCategory;
    addTearDown(weaponController.dispose);
    addTearDown(caliberController.dispose);
    addTearDown(caliberFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardIntroStep(
            formKey: GlobalKey<FormState>(),
            loadingExercise: false,
            linkedExercise: exercise,
            goals: const [],
            weaponController: weaponController,
            caliberController: caliberController,
            caliberFocusNode: caliberFocusNode,
            categoryDraft: SessionConstants.categoryEntrainement,
            onCaliberChanged: (_) {},
            onCaliberSaved: (_) {},
            onCategorySaved: (value) => selectedCategory = value,
            onValidate: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('10 consigne(s)'), findsOneWidget);
    expect(find.text('Durée : 25 min'), findsOneWidget);
    expect(
      find.text('Matériel requis : Timer et deux cibles'),
      findsOneWidget,
    );
    final introWidth = tester.getSize(find.byType(WizardIntroStep)).width;
    final cardWidth = tester.getSize(find.byType(Card).first).width;
    expect(cardWidth, closeTo(introWidth - 32, 0.1));

    final category = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.decoration.labelText == 'Catégorie',
    );
    expect(category, findsOneWidget);
    final weaponRect = tester.getRect(find.byType(WeaponAutocompleteField));
    final caliberRect = tester.getRect(find.byType(CaliberAutocompleteField));
    final categoryRect = tester.getRect(category);
    expect(weaponRect.bottom, lessThan(caliberRect.top));
    expect(caliberRect.bottom, lessThan(categoryRect.top));

    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Match').last);
    await tester.pumpAndSettle();
    expect(selectedCategory, SessionConstants.categoryMatch);
  });
}
