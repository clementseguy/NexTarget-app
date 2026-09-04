import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/interfaces/session_photo_service_interface.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/session_service.dart';

import '../support/async_test_helpers.dart';
import '../support/fake_session_repository.dart';

class _PhotoService implements ISessionPhotoService {
  final deleted = <String?>[];

  @override
  Future<void> deleteIfExists(String? path) async => deleted.add(path);

  @override
  Future<String?> pickAndStore(ImageSource source) async => null;
}

void main() {
  group('SessionService séance guidée', () {
    late FakeSessionRepository repository;
    late SessionService service;

    setUp(() {
      repository = FakeSessionRepository();
      service = SessionService(repository: repository);
    });

    Future<DetailedShootingSession> create({
      int seriesCount = 10,
      int shots = 5,
      List<String> exercises = const [],
    }) =>
        service.createGuidedDraft(
          date: DateTime(2026, 9, 4, 14, 30),
          weapon: 'CZ 75',
          caliber: '9 mm libre',
          category: SessionConstants.categoryEntrainement,
          exercises: exercises,
          seriesCount: seriesCount,
          shotsPerSeries: shots,
          initialDistance: 25,
          initialHandMethod: HandMethod.oneHand,
        );

    test('crée immédiatement un brouillon détaillé persistant', () async {
      final draft = await create(shots: 8, exercises: const ['e1', 'e2']);

      expect(draft.status, SessionConstants.statusDraft);
      expect(draft.series, hasLength(10));
      expect(draft.series.every((item) => !item.isCompleted), isTrue);
      expect(draft.series.every((item) => item.shotCount == 8), isTrue);
      expect(draft.series.first.handMethod, HandMethod.oneHand);
      expect(draft.exercises, ['e1', 'e2']);

      final afterRestart = SessionService(repository: repository);
      final restored = (await afterRestart.getGuidedDrafts()).single;
      expect(restored.id, draft.id);
      expect(restored.caliber, '9 mm libre');
    });

    test('n’impose aucune borne maximale à cinq coups', () async {
      final draft = await create(shots: 12);
      expect(draft.series.first.shotCount, 12);
    });

    test('autorise plusieurs brouillons coexistants', () async {
      final first = await create();
      final second = await create(seriesCount: 3);

      final drafts = await service.getGuidedDrafts();

      expect(drafts, hasLength(2));
      expect(drafts.map((item) => item.id), containsAll([first.id, second.id]));
    });

    test('rejette les volumes non strictement positifs', () async {
      expect(await captureError(() => create(seriesCount: 0)),
          isA<ArgumentError>());
      expect(await captureError(() => create(shots: 0)), isA<ArgumentError>());
    });

    test('sauvegarde une série partielle puis une série validée', () async {
      final draft = await create(seriesCount: 2);
      draft.series[0] = Series(
        shotCount: 5,
        distance: 15,
        points: 0,
        groupSize: 0,
        handMethod: HandMethod.twoHands,
        isCompleted: false,
        isDraftStarted: true,
      );
      await service.saveGuidedDraft(draft);

      var restored = (await service.getGuidedDrafts()).single;
      expect(restored.series.first.isDraftStarted, isTrue);
      expect(restored.series.first.distance, 15);

      restored.series[0] = Series(
        shotCount: 5,
        distance: 15,
        points: 0,
        groupSize: 9.5,
        handMethod: HandMethod.twoHands,
        isCompleted: true,
      );
      await service.saveGuidedDraft(restored);
      restored = (await service.getGuidedDrafts()).single;
      expect(restored.completedSeriesCount, 1);
      expect(restored.completedShotCount, 5);
    });

    test('clôture atomiquement avec les seules séries enregistrées', () async {
      final draft = await create(seriesCount: 3);
      draft.series[0] = Series(
        shotCount: 6,
        distance: 25,
        points: 51,
        groupSize: 7,
        handMethod: HandMethod.oneHand,
        isCompleted: true,
      );
      await service.saveGuidedDraft(draft);

      final realized = await service.completeGuidedDraft(draft);

      expect(realized.status, SessionConstants.statusRealisee);
      expect(realized.series, hasLength(1));
      expect(await service.getGuidedDrafts(), isEmpty);
      final stored = (await service.getAllSessions()).single;
      expect(stored.status, SessionConstants.statusRealisee);
      expect(stored.series, hasLength(1));
    });

    test('un échec de clôture conserve intégralement le brouillon', () async {
      final draft = await create(seriesCount: 2);
      draft.series[0] = Series(
        shotCount: 5,
        distance: 25,
        points: 45,
        groupSize: 8,
        isCompleted: true,
      );
      await service.saveGuidedDraft(draft);
      repository.failOnUpdateCallNumber = repository.updateCallCount + 1;

      final error =
          await captureError(() => service.completeGuidedDraft(draft));

      expect(error, isA<StateError>());
      expect(draft.status, SessionConstants.statusDraft);
      final restored = (await service.getGuidedDrafts()).single;
      expect(restored.status, SessionConstants.statusDraft);
      expect(restored.series, hasLength(2));
      expect(restored.series.first.points, 45);
    });

    test('abandonne uniquement un brouillon', () async {
      final draft = await create();
      await service.abandonGuidedDraft(draft);
      expect(await service.getAllSessions(), isEmpty);

      final realized = DetailedShootingSession(
        id: 99,
        weapon: 'P',
        caliber: '9 mm',
        series: const [],
      );
      expect(
        await captureError(() => service.abandonGuidedDraft(realized)),
        isA<StateError>(),
      );
    });

    test('l’abandon nettoie la photo persistée du brouillon', () async {
      final photos = _PhotoService();
      final serviceWithPhotos = SessionService(
        repository: repository,
        photoService: photos,
      );
      final draft = await create();
      draft.photoPath = '/photos/brouillon.jpg';
      await service.saveGuidedDraft(draft);

      await serviceWithPhotos.abandonGuidedDraft(draft);

      expect(photos.deleted, ['/photos/brouillon.jpg']);
    });
  });
}
