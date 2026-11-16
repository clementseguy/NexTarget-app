import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_13_add_coach_session_contract.dart';

void main() {
  group('Migration13AddCoachSessionContract', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_migration13_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('ajoute un UUID distinct et le débrief structuré nullable', () async {
      final box = await Hive.openBox('sessions');
      await box.putAll({
        1: {
          'session': {'id': 1, 'weapon': 'A'},
          'series': [],
        },
        2: {
          'session': {'id': 2, 'weapon': 'B'},
          'series': [],
        },
      });
      final migration = Migration13AddCoachSessionContract();
      expect(migration.toVersion, 13);
      await migration.apply();
      final first = Map<String, dynamic>.from(box.get(1)['session'] as Map);
      final second = Map<String, dynamic>.from(box.get(2)['session'] as Map);
      expect(first['sessionUuid'], isNotEmpty);
      expect(second['sessionUuid'], isNot(first['sessionUuid']));
      expect(first.containsKey('coachAnalysis'), isTrue);
      expect(first['coachAnalysis'], isNull);
    });

    test('préserve un UUID et un débrief existants', () async {
      final box = await Hive.openBox('sessions');
      final analysis = {'debrief': 'existant'};
      await box.put(1, {
        'session': {
          'sessionUuid': 'uuid-existant',
          'coachAnalysis': analysis,
        },
        'series': [],
      });
      await Migration13AddCoachSessionContract().apply();
      final session = Map<String, dynamic>.from(box.get(1)['session'] as Map);
      expect(session['sessionUuid'], 'uuid-existant');
      expect(session['coachAnalysis'], analysis);
    });
  });
}
