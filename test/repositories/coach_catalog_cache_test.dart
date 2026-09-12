import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/services/coach_catalog_service.dart';

void main() {
  group('cache Hive du catalogue Coach', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('nt160_catalog_');
      Hive.init(directory.path);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test('la copie téléchargée reste lisible après réouverture hors ligne',
        () async {
      final service = CoachCatalogService(
        baseUrl: 'https://server.test',
        repository: HiveExerciseRepository(),
        client: MockClient(
          (_) async => http.Response(
            '''
{
  "id": "coach-offline",
  "name": "Copie hors ligne",
  "category": "precision",
  "type": "stand",
  "difficulty": null,
  "origin": "coach_catalog",
  "description": null,
  "durationMinutes": null,
  "equipment": null,
  "createdAt": "2026-09-11T00:00:00.000Z",
  "priority": 9999,
  "goalIds": [],
  "consignes": []
}
''',
            200,
          ),
        ),
      );

      await service.downloadById('coach-offline');
      await Hive.close();

      final cached = await HiveExerciseRepository().getAll();
      expect(cached, hasLength(1));
      expect(cached.single.id, 'coach-offline');
      expect(cached.single.origin, ExerciseOrigin.coachCatalog);
    });
  });
}
