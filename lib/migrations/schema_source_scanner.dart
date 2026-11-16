import 'schema_verifier.dart';

/// Extrait les types et champs Hive déclarés dans des sources Dart.
///
/// Le parseur accepte les clauses `extends`, `with` et `implements` placées
/// entre le nom du type et son corps.
List<DeclaredHiveType> parseDeclaredHiveTypes(Iterable<String> sources) {
  final types = <DeclaredHiveType>[];
  final typePattern = RegExp(
    r'@HiveType\(typeId: (\d+)\)\s+(?:enum|class)\s+(\w+)[^{]*\{(.*?)(?=@HiveType|$)',
    dotAll: true,
  );
  final fieldPattern = RegExp(
    r'@HiveField\((\d+)\)\s*'
    r'(?:(?://[^\r\n]*(?:\r?\n|$)|/\*[\s\S]*?\*/)\s*)*'
    r'(?:final\s+)?(?:[\w<>?, ]+\s+)?(\w+)\s*[;,(=]',
  );

  for (final source in sources) {
    for (final match in typePattern.allMatches(source)) {
      final fields = <int, String>{};
      for (final field in fieldPattern.allMatches(match.group(3)!)) {
        final index = int.parse(field.group(1)!);
        final name = field.group(2)!;
        fields[index] =
            fields.containsKey(index) ? '${fields[index]}|$name' : name;
      }
      types.add(
        DeclaredHiveType(
          name: match.group(2)!,
          typeId: int.parse(match.group(1)!),
          fields: fields,
        ),
      );
    }
  }
  return types;
}
