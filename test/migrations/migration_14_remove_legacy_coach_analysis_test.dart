import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/migrations/migration_14_remove_legacy_coach_analysis.dart';

void main() {
  group('Migration14RemoveLegacyCoachAnalysis', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_hive_v14_');
      Hive.init(directory.path);
      await Hive.openBox('sessions', bytes: Uint8List(0));
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('supprime analyse et préserve le débrief structuré', () async {
      final structured = {
        'analysis_id': 'analysis-1',
        'session_id': 'session-1',
      };
      await Hive.box('sessions').put(1, {
        'session': {
          'weapon': 'Pistolet',
          'analyse': 'Ancien Markdown',
          'coachAnalysis': structured,
        },
        'series': const [],
      });

      await Migration14RemoveLegacyCoachAnalysis().apply();

      final envelope = Map<String, dynamic>.from(Hive.box('sessions').get(1));
      final session = Map<String, dynamic>.from(envelope['session'] as Map);
      expect(session.containsKey('analyse'), isFalse);
      expect(session['coachAnalysis'], structured);
    });

    test('convertit une analyse Markdown sans perdre son contenu', () async {
      await Hive.box('sessions').put(1, {
        'session': {
          'sessionUuid': 'session-legacy',
          'date': '2026-08-14T10:30:00.000Z',
          'weapon': 'Pistolet',
          'analyse': '## Ancien débrief\n\nGroupement en progrès.',
          'coachAnalysis': null,
        },
        'series': const [],
      });

      await Migration14RemoveLegacyCoachAnalysis().apply();

      final envelope = Map<String, dynamic>.from(Hive.box('sessions').get(1));
      final session = Map<String, dynamic>.from(envelope['session'] as Map);
      final analysis =
          Map<String, dynamic>.from(session['coachAnalysis'] as Map);
      expect(session.containsKey('analyse'), isFalse);
      expect(analysis['session_id'], 'session-legacy');
      expect(
          analysis['debrief'], '## Ancien débrief\n\nGroupement en progrès.');
      expect(analysis['model'], 'legacy-markdown');
      expect(analysis['generated_at'], '2026-08-14T10:30:00.000Z');
    });

    test('reste sans effet sur une session déjà migrée', () async {
      await Hive.box('sessions').put(1, {
        'session': {'weapon': 'Pistolet', 'coachAnalysis': null},
        'series': const [],
      });

      await Migration14RemoveLegacyCoachAnalysis().apply();

      final envelope = Map<String, dynamic>.from(Hive.box('sessions').get(1));
      final session = Map<String, dynamic>.from(envelope['session'] as Map);
      expect(session, {'weapon': 'Pistolet', 'coachAnalysis': null});
    });
  });
}
