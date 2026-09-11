import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/exercise_execution.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  group('Planned session conversion', () {
    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('hive_test');
      Hive.init(dir.path);
      await Hive.openBox('sessions');
    });
    tearDown(() async {
      await Hive.box('sessions').close();
    });
    test('convert planned to realized updates status and date', () async {
      final service = SessionService();
      final session = DetailedShootingSession(
        weapon: 'Pistol',
        caliber: '22LR',
        series: [
          Series(
              distance: 1, points: 0, groupSize: 0, shotCount: 1, comment: '')
        ],
        status: 'prévue',
        category: 'entraînement',
      );
      await service.addSession(session);
      expect(session.status, 'prévue');
      expect(session.date, isNull);
      final converted = await service.convertPlannedToRealized(
        session: session,
        synthese: 'Test',
      );
      expect(converted.status, 'réalisée');
      expect(converted.date, isNotNull);
      expect(converted.synthese, 'Test');
    });

    test('persists optional exercise execution on conversion', () async {
      final service = SessionService();
      final session = DetailedShootingSession(
        weapon: 'Pistol',
        caliber: '22LR',
        series: const [],
        status: 'prévue',
        category: 'entraînement',
        exerciseId: 'exercise-1',
      );
      await service.addSession(session);

      await service.convertPlannedToRealized(
        session: session,
        exerciseExecution: const ExerciseExecution(
          performed: true,
          protocolFollowed: ProtocolFollowed.partially,
          comment: '  Protocole adapté à mi-parcours.  ',
        ),
      );

      final stored =
          (await service.getAllSessions()).single as DetailedShootingSession;
      expect(stored.exerciseExecution?.performed, isTrue);
      expect(
        stored.exerciseExecution?.protocolFollowed,
        ProtocolFollowed.partially,
      );
      expect(
        stored.exerciseExecution?.comment,
        'Protocole adapté à mi-parcours.',
      );
    });

    test('ignores exercise execution when no exercise is associated', () async {
      final service = SessionService();
      final session = DetailedShootingSession(
        weapon: 'Pistol',
        caliber: '22LR',
        series: const [],
        status: 'prévue',
        category: 'entraînement',
      );
      await service.addSession(session);

      await service.convertPlannedToRealized(
        session: session,
        exerciseExecution: const ExerciseExecution(performed: true),
      );

      final stored =
          (await service.getAllSessions()).single as DetailedShootingSession;
      expect(stored.exerciseExecution, isNull);
    });
  });
}
