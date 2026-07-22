import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/goal.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/screens/wizard/wizard_steps.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'WizardIntroStep affiche exercice, objectifs et sauvegarde les champs',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final caliberController = TextEditingController(text: '.22 LR');
    final focusNode = FocusNode();
    String? weapon;
    String? caliber;
    String? category;
    var validateCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardIntroStep(
            formKey: formKey,
            loadingExercise: false,
            linkedExercise: Exercise(
              id: 'ex1',
              name: 'Précision debout',
              categoryEnum: ExerciseCategory.precision,
              type: ExerciseType.stand,
              description: 'Tenue du guidon',
              createdAt: DateTime(2026, 1, 1),
            ),
            goals: [
              Goal(
                title: '95 points',
                metric: GoalMetric.totalPoints,
                comparator: GoalComparator.greaterOrEqual,
                targetValue: 95,
              ),
            ],
            weaponDraft: 'Walther',
            caliberController: caliberController,
            caliberFocusNode: focusNode,
            categoryDraft: 'match',
            onCaliberChanged: (value) => caliber = value,
            onWeaponSaved: (value) => weapon = value,
            onCaliberSaved: (value) => caliber = value,
            onCategorySaved: (value) => category = value,
            onValidate: () {
              formKey.currentState!.save();
              validateCount++;
            },
          ),
        ),
      ),
    );

    expect(find.text('Précision debout'), findsOneWidget);
    expect(find.text('Tenue du guidon'), findsOneWidget);
    expect(find.text('95 points'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Arme'), 'P210');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Calibre'), '.45 ACP');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Catégorie'), 'test matériel');
    await tester.tap(find.text('Commencer'));
    await tester.pump();

    expect(validateCount, 1);
    expect(weapon, 'P210');
    expect(caliber, '.45 ACP');
    expect(category, 'test matériel');

    caliberController.dispose();
    focusNode.dispose();
  });

  testWidgets('WizardIntroStep affiche les états sans exercice et chargement',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final caliberController = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardIntroStep(
            formKey: formKey,
            loadingExercise: false,
            linkedExercise: null,
            goals: const [],
            weaponDraft: null,
            caliberController: caliberController,
            caliberFocusNode: focusNode,
            categoryDraft: null,
            onCaliberChanged: (_) {},
            onWeaponSaved: (_) {},
            onCaliberSaved: (_) {},
            onCategorySaved: (_) {},
            onValidate: () {},
          ),
        ),
      ),
    );
    expect(find.text('Pas d\'exercice associé'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardIntroStep(
            formKey: GlobalKey<FormState>(),
            loadingExercise: true,
            linkedExercise: null,
            goals: const [],
            weaponDraft: null,
            caliberController: TextEditingController(),
            caliberFocusNode: FocusNode(),
            categoryDraft: null,
            onCaliberChanged: (_) {},
            onWeaponSaved: (_) {},
            onCaliberSaved: (_) {},
            onCategorySaved: (_) {},
            onValidate: () {},
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    caliberController.dispose();
    focusNode.dispose();
  });

  testWidgets(
      'WizardSeriesStep met à jour son contrôleur et construit une série',
      (tester) async {
    final controller = SeriesStepController(
      points: 0,
      groupSize: 0,
      comment: '',
      shotCount: 5,
      distance: 25,
      handMethod: HandMethod.twoHands,
      consigne: '',
    );
    var validated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardSeriesStep(
            seriesIndex: 0,
            controller: controller,
            isLastSeries: false,
            onValidate: () => validated = true,
          ),
        ),
      ),
    );

    expect(find.text('Pas de consigne'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Points'), '48');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Groupement'), '16.5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Coups'), '6');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Distance (m)'), '50');
    await tester.tap(find.byIcon(Icons.front_hand).first);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Commentaire série'),
      'Stable',
    );
    await tester.tap(find.text('Suivant'));
    await tester.pump();

    final series = controller.build();
    expect(validated, isTrue);
    expect(series.points, 48);
    expect(series.groupSize, 16.5);
    expect(series.shotCount, 6);
    expect(series.distance, 50);
    expect(series.handMethod, HandMethod.oneHand);
    expect(series.comment, 'Stable');
  });

  testWidgets('WizardSyntheseStep désactive la fin pendant la sauvegarde',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    String? saved;
    var finishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardSyntheseStep(
            formKey: formKey,
            initialSynthese: 'Bilan initial',
            saving: false,
            onSaved: (value) => saved = value,
            onFinish: () {
              formKey.currentState!.save();
              finishCount++;
            },
          ),
        ),
      ),
    );

    expect(find.text('Bilan initial'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Synthèse de la session'),
        'Bilan final');
    await tester.tap(find.text('Terminer'));
    await tester.pump();
    expect(saved, 'Bilan final');
    expect(finishCount, 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardSyntheseStep(
            formKey: GlobalKey<FormState>(),
            initialSynthese: '',
            saving: true,
            onSaved: (_) {},
            onFinish: () => finishCount++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
