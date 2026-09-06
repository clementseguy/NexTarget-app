class DeclaredHiveType {
  final String name;
  final int typeId;
  final Map<int, String> fields;

  const DeclaredHiveType({
    required this.name,
    required this.typeId,
    required this.fields,
  });
}

class HiveSchemaSnapshot {
  final int currentVersion;
  final List<int> availableMigrations;
  final List<int> registeredMigrations;
  final List<DeclaredHiveType> declaredTypes;
  final Map<int, Map<int, String>> reservedFieldsByTypeId;
  final Map<int, String> reservedTypeIds;
  final Set<int> activeTypeIds;
  final Map<int, Set<int>> activeFieldIdsByTypeId;

  const HiveSchemaSnapshot({
    required this.currentVersion,
    required this.availableMigrations,
    required this.registeredMigrations,
    required this.declaredTypes,
    required this.reservedFieldsByTypeId,
    required this.reservedTypeIds,
    required this.activeTypeIds,
    required this.activeFieldIdsByTypeId,
  });
}

List<String> verifyHiveSchema(HiveSchemaSnapshot schema) {
  final errors = <String>[];
  _verifyMigrations(schema, errors);
  _verifyTypes(schema, errors);
  return errors;
}

void _verifyMigrations(HiveSchemaSnapshot schema, List<String> errors) {
  final expected = [
    for (var version = 2; version <= schema.currentVersion; version++) version
  ];
  if (schema.registeredMigrations.toSet().length !=
      schema.registeredMigrations.length) {
    errors.add('Migrations enregistrées : version dupliquée.');
  }
  if (!_same(schema.registeredMigrations, expected)) {
    errors.add(
      'Migrations enregistrées : attendu ${expected.join(', ')}, trouvé '
      '${schema.registeredMigrations.join(', ')}. Enregistrer chaque version '
      'une seule fois et dans l’ordre.',
    );
  }
  final available = [...schema.availableMigrations]..sort();
  if (available.toSet().length != available.length) {
    errors.add('Migrations disponibles : version dupliquée dans les classes.');
  }
  if (!_same(available, expected)) {
    errors.add(
      'Migrations disponibles : attendu ${expected.join(', ')}, trouvé '
      '${available.join(', ')}. Ajouter ou corriger la migration manquante.',
    );
  }
}

void _verifyTypes(HiveSchemaSnapshot schema, List<String> errors) {
  final seenTypeIds = <int, String>{};
  for (final type in schema.declaredTypes) {
    final previous = seenTypeIds[type.typeId];
    if (previous != null) {
      errors.add(
        'typeId ${type.typeId} dupliqué entre $previous et ${type.name}. '
        'Attribuer un identifiant inédit et le réserver dans le registre.',
      );
    }
    seenTypeIds[type.typeId] = type.name;
    final reservedName = schema.reservedTypeIds[type.typeId];
    if (reservedName == null) {
      errors.add(
        'typeId ${type.typeId} de ${type.name} absent du registre historique.',
      );
    } else {
      if (!schema.activeTypeIds.contains(type.typeId)) {
        errors.add(
          'typeId ${type.typeId} de ${type.name} est déclaré dans le code mais '
          'marqué retiré dans le registre.',
        );
      }
      if (reservedName != type.name) {
        errors.add(
          'typeId ${type.typeId} réservé à $reservedName, réutilisé par '
          '${type.name}. Choisir un identifiant inédit.',
        );
      }
    }
    final reservedFields =
        schema.reservedFieldsByTypeId[type.typeId] ?? const {};
    final activeFields = schema.activeFieldIdsByTypeId[type.typeId] ?? const {};
    for (final entry in type.fields.entries) {
      final reservedField = reservedFields[entry.key];
      if (reservedField == null) {
        errors.add(
          'HiveField ${entry.key} de ${type.name}.${entry.value} absent du '
          'registre historique.',
        );
      } else if (reservedField != entry.value) {
        errors.add(
          'HiveField ${entry.key} de ${type.name} réservé à $reservedField, '
          'réutilisé par ${entry.value}. Choisir un index inédit.',
        );
      } else if (!activeFields.contains(entry.key)) {
        errors.add(
          'HiveField ${entry.key} de ${type.name}.${entry.value} est déclaré '
          'dans le code mais marqué retiré dans le registre.',
        );
      }
    }
    for (final fieldId in activeFields) {
      if (!type.fields.containsKey(fieldId)) {
        errors.add(
          'HiveField $fieldId de ${type.name} est actif dans le registre mais '
          'absent du code. Restaurer le champ ou le déplacer explicitement '
          'dans retiredFields après migration compatible.',
        );
      }
    }
  }
  for (final typeId in schema.activeTypeIds) {
    if (!seenTypeIds.containsKey(typeId)) {
      errors.add(
        'typeId $typeId (${schema.reservedTypeIds[typeId]}) est actif dans le '
        'registre mais absent du code. Restaurer le type ou le marquer '
        'explicitement retiré.',
      );
    }
  }
}

bool _same(List<int> actual, List<int> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index++) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}
