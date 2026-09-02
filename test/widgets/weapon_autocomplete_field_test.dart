import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/weapon_repository.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/services/weapon_service.dart';
import 'package:tir_sportif/widgets/weapon_autocomplete_field.dart';

class _MemWeaponRepo implements WeaponRepository {
  final List<Weapon> list = [];
  @override
  Future<void> clear() async => list.clear();
  @override
  Future<void> delete(String id) async => list.removeWhere((w) => w.id == id);
  @override
  Future<List<Weapon>> getAll() async => List.of(list);
  @override
  Future<void> put(Weapon weapon) async {
    list.removeWhere((w) => w.id == weapon.id);
    list.add(weapon);
  }
}

class _MemSessionRepo implements SessionRepository {
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<ShootingSession>> getAll() async => const [];
  @override
  Future<int> insert(ShootingSession session) async => 1;
  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async => false;
}

Future<WeaponService> _serviceWithRack(List<String> names) async {
  final repo = _MemWeaponRepo();
  final service = WeaponService(weaponRepository: repo, sessionRepository: _MemSessionRepo());
  for (final n in names) {
    await service.addWeapon(n);
  }
  return service;
}

void main() {
  group('WeaponAutocompleteField (NT-009)', () {
    testWidgets('propose les armes du râtelier correspondant à la saisie', (tester) async {
      final service = await _serviceWithRack(['CZ 75 SP-01 Shadow', 'Glock 17']);
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeaponAutocompleteField(controller: controller, weaponService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'cz');
      await tester.pumpAndSettle();

      expect(find.text('CZ 75 SP-01 Shadow'), findsOneWidget);
      expect(find.text('Glock 17'), findsNothing);
    });

    testWidgets('sélectionner une suggestion remplit le champ avec le nom complet', (tester) async {
      final service = await _serviceWithRack(['CZ 75 SP-01 Shadow']);
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeaponAutocompleteField(controller: controller, weaponService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'cz');
      await tester.pumpAndSettle();
      await tester.tap(find.text('CZ 75 SP-01 Shadow'));
      await tester.pumpAndSettle();

      expect(controller.text, 'CZ 75 SP-01 Shadow');
    });

    testWidgets("poursuivre la saisie d'une valeur non présente garde le texte libre de l'utilisateur", (tester) async {
      final service = await _serviceWithRack(['CZ 75 SP-01 Shadow']);
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeaponAutocompleteField(controller: controller, weaponService: service),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'CZ 09');
      await tester.pumpAndSettle();

      expect(controller.text, 'CZ 09'); // jamais écrasé par la suggestion
    });

    testWidgets('le validateur fourni est appliqué au champ', (tester) async {
      final service = await _serviceWithRack([]);
      final controller = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: WeaponAutocompleteField(
                controller: controller,
                weaponService: service,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Requis'), findsOneWidget);
    });
  });
}
