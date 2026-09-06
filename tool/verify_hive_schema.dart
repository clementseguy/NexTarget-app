import 'dart:convert';
import 'dart:io';

import 'package:tir_sportif/migrations/schema_source_scanner.dart';
import 'package:tir_sportif/migrations/schema_verifier.dart';

void main() {
  final registry = jsonDecode(
    File('tool/hive_schema_registry.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final reservedTypes = registry['reservedTypes'] as Map<String, dynamic>;
  final snapshot = HiveSchemaSnapshot(
    currentVersion: registry['currentSchemaVersion'] as int,
    availableMigrations: _availableMigrationVersions(),
    registeredMigrations: _registeredMigrationVersions(),
    declaredTypes: _declaredHiveTypes(),
    reservedTypeIds: {
      for (final entry in reservedTypes.entries)
        int.parse(entry.key):
            (entry.value as Map<String, dynamic>)['name'] as String,
    },
    reservedFieldsByTypeId: {
      for (final entry in reservedTypes.entries)
        int.parse(entry.key): {
          for (final field in _reservedFields(entry.value).entries)
            int.parse(field.key): field.value as String,
        },
    },
    activeTypeIds: {
      for (final entry in reservedTypes.entries)
        if ((entry.value as Map<String, dynamic>)['status'] == 'active')
          int.parse(entry.key),
    },
    activeFieldIdsByTypeId: {
      for (final entry in reservedTypes.entries)
        int.parse(entry.key): {
          for (final field in _activeFields(entry.value).keys) int.parse(field),
        },
    },
  );
  final errors = verifyHiveSchema(snapshot);
  if (errors.isEmpty) {
    stdout.writeln('Schéma Hive cohérent.');
    return;
  }
  stderr.writeln('Schéma Hive incohérent :');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exitCode = 1;
}

List<int> _availableMigrationVersions() {
  final versions = <int>[];
  final pattern = RegExp(r'int get toVersion => (\d+);');
  for (final file in Directory('lib/migrations').listSync().whereType<File>()) {
    if (!file.uri.pathSegments.last.startsWith('migration_')) continue;
    versions.addAll(
      pattern
          .allMatches(file.readAsStringSync())
          .map((match) => int.parse(match.group(1)!)),
    );
  }
  return versions;
}

List<int> _registeredMigrationVersions() {
  final source = File('lib/main.dart').readAsStringSync();
  final block = RegExp(
    r'final runner = MigrationRunner\(\[(.*?)\], schemaStore\);',
    dotAll: true,
  ).firstMatch(source)?.group(1);
  if (block == null) return const [];
  return RegExp(r'Migration(\d+)')
      .allMatches(block)
      .map((match) => int.parse(match.group(1)!))
      .toList();
}

List<DeclaredHiveType> _declaredHiveTypes() {
  return parseDeclaredHiveTypes(
    Directory('lib/models')
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync()),
  );
}

Map<String, dynamic> _activeFields(Object? value) =>
    ((value as Map<String, dynamic>)['fields'] as Map<String, dynamic>);

Map<String, dynamic> _reservedFields(Object? value) {
  final type = value as Map<String, dynamic>;
  return {
    ...type['fields'] as Map<String, dynamic>,
    ...type['retiredFields'] as Map<String, dynamic>,
  };
}
