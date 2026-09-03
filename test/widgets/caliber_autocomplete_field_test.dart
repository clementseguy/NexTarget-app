import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/widgets/caliber_autocomplete_field.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  testWidgets('la saisie libre n\'est jamais autoremplacée', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaliberAutocompleteField(controller: controller),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '45');
    await tester.pump();
    expect(controller.text, '45');
    expect(find.text('.45 ACP'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'calibre maison');
    await tester.pump();
    expect(controller.text, 'calibre maison');
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('plusieurs suggestions restent sélectionnables explicitement',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaliberAutocompleteField(controller: controller),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '38');
    await tester.pump();
    expect(find.text('.38 Special'), findsOneWidget);
    expect(find.text('.380 ACP'), findsOneWidget);
    await tester.tap(find.text('.380 ACP'));
    await tester.pump();
    expect(controller.text, '.380 ACP');
  });

  testWidgets('la soumission clavier sélectionne la suggestion surlignée',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CaliberAutocompleteField(
            controller: controller,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), '45');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.text, '.45 ACP');
    expect(selected, '.45 ACP');
  });
}
