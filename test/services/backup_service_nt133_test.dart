import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/services/backup_service.dart';
import 'package:tir_sportif/services/session_service.dart';

void main() {
  group('BackupService NT-133', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt_backup133_');
      Hive.init(directory.path);
      await Hive.openBox('sessions');
      await Hive.openBox('exercises');
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Map<String, dynamic> payload(List<Map<String, dynamic>> sessions) => {
          'format': 'mycoach-data',
          'version': 3,
          'sessions': sessions,
        };

    test('importe une sauvegarde mixte et conserve les sous-types', () async {
      final historical = {
        'date': '2026-08-01T00:00:00.000',
        'weapon': 'P',
        'caliber': '9mm',
        'series': [],
      };
      final simple = SimpleShootingSession(
        date: DateTime(2026, 8, 2),
        weapon: 'C',
        caliber: '.22 LR',
        shotCount: 30,
        distance: 50,
        synthese: 'RAS',
        photoPath: '/photo.jpg',
        exercises: const ['e1'],
      ).toMap();

      final count = await BackupService().importSessionsFromJson(
        jsonEncode(payload([historical, simple])),
      );
      final sessions = await SessionService().getAllSessions();

      expect(count, 2);
      expect(sessions.whereType<DetailedShootingSession>(), hasLength(1));
      final importedSimple = sessions.whereType<SimpleShootingSession>().single;
      expect(importedSimple.shotCount, 30);
      expect(importedSimple.photoPath, '/photo.jpg');
      expect(importedSimple.exercises, ['e1']);
    });

    test('un type inconnu ne modifie aucune donnée locale', () async {
      await SessionService().addSession(
        SimpleShootingSession(
          date: DateTime(2026, 8, 1),
          weapon: 'Existant',
          caliber: '9mm',
          shotCount: 10,
          distance: 25,
        ),
      );
      final before = await SessionService().getAllSessions();
      final invalid = payload([
        SimpleShootingSession(
          date: DateTime(2026, 8, 2),
          weapon: 'Valide',
          caliber: '9mm',
          shotCount: 5,
          distance: 10,
        ).toMap(),
        {'sessionType': 'inconnu'},
      ]);

      await expectLater(
        BackupService().importSessionsFromJson(jsonEncode(invalid)),
        throwsA(isA<FormatException>()),
      );
      final after = await SessionService().getAllSessions();

      expect(after, hasLength(before.length));
      expect(after.single.weapon, 'Existant');
    });

    test('un brouillon conserve son état et ses séries à l’import', () async {
      final draft = DetailedShootingSession(
        date: DateTime(2026, 9, 4, 18),
        weapon: 'CZ 75',
        caliber: '9 mm',
        status: 'brouillon',
        series: [
          Series(
            shotCount: 7,
            distance: 25,
            points: 0,
            groupSize: 0,
            isCompleted: false,
            isDraftStarted: true,
          ),
        ],
      );

      await BackupService().importSessionsFromJson(
        jsonEncode(payload([draft.toMap()])),
      );

      final restored = (await SessionService().getGuidedDrafts()).single;
      expect(restored.series.single.shotCount, 7);
      expect(restored.series.single.isDraftStarted, isTrue);
      expect(restored.series.single.isCompleted, isFalse);
    });
  });
}
