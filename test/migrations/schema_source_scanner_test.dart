import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/migrations/schema_source_scanner.dart';

void main() {
  test('analyse une classe Hive avec extends, with et implements', () {
    const source = '''
@HiveType(typeId: 44)
class Goal extends HiveObject with Diagnosticable implements Comparable<Goal> {
  @HiveField(0)
  String id;

  @HiveField(15)
  double? improvementDelta;
}
''';

    final types = parseDeclaredHiveTypes([source]);

    expect(types, hasLength(1));
    expect(types.single.name, 'Goal');
    expect(types.single.typeId, 44);
    expect(types.single.fields, {0: 'id', 15: 'improvementDelta'});
  });

  test('analyse le modèle Goal réel du dépôt', () {
    final source = File('lib/models/goal.dart').readAsStringSync();

    final goal = parseDeclaredHiveTypes(
      [source],
    ).singleWhere((type) => type.name == 'Goal');

    expect(goal.typeId, 44);
    expect(goal.fields[0], 'id');
    expect(goal.fields[15], 'improvementDelta');
  });
}
