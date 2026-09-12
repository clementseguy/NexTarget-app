import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/repositories/exercise_repository.dart';
import 'package:tir_sportif/services/coach_catalog_service.dart';

class _MemoryExerciseRepository implements ExerciseRepository {
  final Map<String, Exercise> store = {};

  @override
  Future<void> clear() async => store.clear();

  @override
  Future<void> delete(String id) async => store.remove(id);

  @override
  Future<List<Exercise>> getAll() async => store.values
      .map((exercise) => Exercise.fromMap(exercise.toMap()))
      .toList();

  @override
  Future<void> put(Exercise exercise) async {
    store[exercise.id] = Exercise.fromMap(exercise.toMap());
  }
}

String _payload({String name = 'Exercice Coach', String id = 'coach-1'}) => '''
{
  "id": "$id",
  "name": "$name",
  "category": "technique",
  "type": "stand",
  "difficulty": "beginner",
  "origin": "coach_catalog",
  "description": "Fixture",
  "durationMinutes": 15,
  "equipment": "Pistolet",
  "createdAt": "2026-09-11T00:00:00.000Z",
  "priority": 3,
  "goalIds": [],
  "consignes": ["Étape 1"]
}
''';

void main() {
  group('CoachCatalogService', () {
    late _MemoryExerciseRepository repository;

    setUp(() => repository = _MemoryExerciseRepository());

    test('télécharge puis actualise uniquement l’exercice Coach demandé',
        () async {
      var name = 'Version initiale';
      final service = CoachCatalogService(
        baseUrl: 'https://server.test',
        repository: repository,
        client: MockClient((request) async {
          expect(request.url.path, '/exercises/coach-1');
          return http.Response(_payload(name: name), 200);
        }),
      );

      await service.downloadById('coach-1');
      name = 'Version actualisée';
      await service.downloadById('coach-1');

      expect(repository.store, hasLength(1));
      expect(repository.store['coach-1']!.name, 'Version actualisée');
      expect(
        repository.store['coach-1']!.origin,
        ExerciseOrigin.coachCatalog,
      );
    });

    test('une absence serveur conserve la copie Coach en cache', () async {
      repository.store['coach-1'] = Exercise(
        id: 'coach-1',
        name: 'Copie hors ligne',
        categoryEnum: ExerciseCategory.technique,
        type: ExerciseType.stand,
        origin: ExerciseOrigin.coachCatalog,
        createdAt: DateTime(2026, 9, 11),
      );
      final service = CoachCatalogService(
        baseUrl: 'https://server.test',
        repository: repository,
        client: MockClient((_) async => http.Response('{}', 404)),
      );

      await expectLater(
        service.downloadById('coach-1'),
        throwsA(isA<CatalogExerciseNotFoundException>()),
      );

      expect(repository.store['coach-1']!.name, 'Copie hors ligne');
    });

    test('une réponse invalide conserve le cache et les exercices personnels',
        () async {
      repository.store['personal-1'] = Exercise(
        id: 'personal-1',
        name: 'Personnel',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 9, 11),
      );
      final service = CoachCatalogService(
        baseUrl: 'https://server.test',
        repository: repository,
        client: MockClient(
          (_) async => http.Response(_payload(id: 'autre-id'), 200),
        ),
      );

      await expectLater(
        service.downloadById('coach-1'),
        throwsA(isA<InvalidCatalogExerciseException>()),
      );

      expect(repository.store.keys, ['personal-1']);
      expect(repository.store['personal-1']!.name, 'Personnel');
    });

    test('ne remplace jamais un exercice personnel portant le même ID',
        () async {
      repository.store['coach-1'] = Exercise(
        id: 'coach-1',
        name: 'Personnel',
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime(2026, 9, 11),
      );
      final service = CoachCatalogService(
        baseUrl: 'https://server.test',
        repository: repository,
        client: MockClient((_) async => http.Response(_payload(), 200)),
      );

      await expectLater(
        service.downloadById('coach-1'),
        throwsA(isA<CatalogExerciseConflictException>()),
      );

      expect(repository.store['coach-1']!.name, 'Personnel');
      expect(repository.store['coach-1']!.origin, ExerciseOrigin.personal);
    });
  });
}
