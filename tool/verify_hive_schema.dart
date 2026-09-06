import 'dart:convert';
import 'dart:io';

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
          for (final field in ((entry.value as Map<String, dynamic>)['fields']
                  as Map<String, dynamic>)
              .entries)
            int.parse(field.key): field.value as String,
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
  final types = <DeclaredHiveType>[];
  final typePattern = RegExp(
    r'@HiveType\(typeId: (\d+)\)\s+(?:enum|class)\s+(\w+)\s*\{(.*?)(?=@HiveType|\z)',
    dotAll: true,
  );
  final fieldPattern =
      RegExp(r'@HiveField\((\d+)\)\s+(?:final\s+)?[\w<>?, ]+\s+(\w+)[;,(]');
  for (final file in Directory('lib/models').listSync().whereType<File>()) {
    final source = file.readAsStringSync();
    for (final match in typePattern.allMatches(source)) {
      final fields = <int, String>{};
      for (final field in fieldPattern.allMatches(match.group(3)!)) {
        final index = int.parse(field.group(1)!);
        if (fields.containsKey(index)) {
          fields[index] = '${fields[index]}|${field.group(2)!}';
        } else {
          fields[index] = field.group(2)!;
        }
      }
      types.add(DeclaredHiveType(
        name: match.group(2)!,
        typeId: int.parse(match.group(1)!),
        fields: fields,
      ));
    }
  }
  return types;
}
