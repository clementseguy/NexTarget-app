import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/migrations/schema_verifier.dart';

void main() {
  HiveSchemaSnapshot nominal({
    List<int> available = const [2, 3],
    List<int> registered = const [2, 3],
    List<DeclaredHiveType>? types,
  }) =>
      HiveSchemaSnapshot(
        currentVersion: 3,
        availableMigrations: available,
        registeredMigrations: registered,
        declaredTypes: types ??
            const [
              DeclaredHiveType(name: 'Goal', typeId: 44, fields: {0: 'id'}),
            ],
        reservedTypeIds: const {44: 'Goal'},
        activeTypeIds: const {44},
        activeFieldIdsByTypeId: const {
          44: {0},
        },
        reservedFieldsByTypeId: const {
          44: {0: 'id', 1: 'retiredField'}
        },
      );

  test('accepte le schéma nominal', () {
    expect(verifyHiveSchema(nominal()), isEmpty);
  });

  test('détecte un typeId dupliqué', () {
    final errors = verifyHiveSchema(nominal(types: const [
      DeclaredHiveType(name: 'Goal', typeId: 44, fields: {0: 'id'}),
      DeclaredHiveType(name: 'Other', typeId: 44, fields: {}),
    ]));
    expect(errors.join('\n'), contains('typeId 44 dupliqué'));
  });

  test('détecte la réutilisation d’un index retiré', () {
    final errors = verifyHiveSchema(nominal(types: const [
      DeclaredHiveType(name: 'Goal', typeId: 44, fields: {1: 'newField'}),
    ]));
    expect(errors.join('\n'), contains('réservé à retiredField'));
  });

  test('détecte la suppression d’un champ encore actif', () {
    final schema = HiveSchemaSnapshot(
      currentVersion: 3,
      availableMigrations: const [2, 3],
      registeredMigrations: const [2, 3],
      declaredTypes: const [
        DeclaredHiveType(name: 'Goal', typeId: 44, fields: {0: 'id'}),
      ],
      reservedTypeIds: const {44: 'Goal'},
      activeTypeIds: const {44},
      activeFieldIdsByTypeId: const {
        44: {0, 15},
      },
      reservedFieldsByTypeId: const {
        44: {0: 'id', 15: 'improvementDelta'},
      },
    );

    final errors = verifyHiveSchema(schema);

    expect(errors.join('\n'), contains('HiveField 15 de Goal est actif'));
  });

  test('accepte un champ explicitement retiré et toujours réservé', () {
    final schema = HiveSchemaSnapshot(
      currentVersion: 3,
      availableMigrations: const [2, 3],
      registeredMigrations: const [2, 3],
      declaredTypes: const [
        DeclaredHiveType(name: 'Goal', typeId: 44, fields: {0: 'id'}),
      ],
      reservedTypeIds: const {44: 'Goal'},
      activeTypeIds: const {44},
      activeFieldIdsByTypeId: const {
        44: {0},
      },
      reservedFieldsByTypeId: const {
        44: {0: 'id', 1: 'retiredField'},
      },
    );

    expect(verifyHiveSchema(schema), isEmpty);
  });

  test('détecte une migration absente', () {
    expect(
      verifyHiveSchema(nominal(available: const [2])).join('\n'),
      contains('Migrations disponibles'),
    );
  });

  test('détecte une rupture ou duplication de version', () {
    final errors = verifyHiveSchema(nominal(registered: const [2, 2, 4]));
    expect(errors.join('\n'), contains('version dupliquée'));
    expect(errors.join('\n'), contains('dans l’ordre'));
  });
}
