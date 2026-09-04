import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/interfaces/session_photo_service_interface.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/services/session_service.dart';

class _SessionRepository implements SessionRepository {
  final sessions = <ShootingSession>[];
  bool failInsert = false;
  int nextId = 100;

  @override
  Future<void> clearAll() async => sessions.clear();

  @override
  Future<void> delete(int id) async {
    sessions.removeWhere((session) => session.id == id);
  }

  @override
  Future<List<ShootingSession>> getAll() async => sessions
      .map((session) => ShootingSession.fromMap(session.toMap()))
      .toList();

  @override
  Future<int> insert(ShootingSession session) async {
    if (failInsert) throw StateError('Échec simulé');
    final id = nextId++;
    final snapshot = ShootingSession.fromMap(session.toMap())..id = id;
    sessions.add(snapshot);
    return id;
  }

  @override
  Future<bool> update(
    ShootingSession session, {
    bool preserveExistingSeriesIfEmpty = true,
  }) async =>
      false;
}

class _PhotoService implements ISessionPhotoService {
  final duplicated = <String>[];
  final deleted = <String>[];
  bool failCopy = false;

  @override
  Future<void> deleteIfExists(String? path) async {
    if (path != null) deleted.add(path);
  }

  @override
  Future<String> duplicateStoredPhoto(String sourcePath) async {
    duplicated.add(sourcePath);
    if (failCopy) throw StateError('Copie impossible');
    return '$sourcePath.independent';
  }

  @override
  Future<String?> pickAndStore(ImageSource source) async => null;
}

DetailedShootingSession _detailed({
  String status = SessionConstants.statusRealisee,
  String? photoPath,
}) =>
    DetailedShootingSession(
      id: 7,
      date: DateTime(2026, 8, 15),
      weapon: 'Pistolet',
      caliber: '9 mm',
      status: status,
      category: SessionConstants.categoryMatch,
      synthese: 'Synthèse',
      analyse: 'Analyse',
      exercises: ['ex-1', 'ex-2'],
      photoPath: photoPath,
      series: [
        Series(
          id: 3,
          shotCount: 5,
          distance: 25,
          points: 47,
          groupSize: 6,
          comment: 'Série source',
          handMethod: HandMethod.oneHand,
        ),
      ],
    );

void main() {
  group('SessionService duplication NT-143', () {
    late _SessionRepository repository;
    late _PhotoService photoService;
    late SessionService service;

    setUp(() {
      repository = _SessionRepository();
      photoService = _PhotoService();
      service = SessionService(
        repository: repository,
        photoService: photoService,
      );
    });

    test('prépare une copie détaillée complète sans identifiant ni date', () {
      final source = _detailed();
      final draft = service.prepareDuplication(source);
      final map = draft.initialSessionData['session'] as Map<String, dynamic>;
      final series = draft.initialSessionData['series'] as List;

      expect(draft.isSimple, isFalse);
      expect(map['id'], isNull);
      expect(map['date'], isNull);
      expect(map['weapon'], source.weapon);
      expect(map['caliber'], source.caliber);
      expect(map['category'], source.category);
      expect(map['status'], source.status);
      expect(map['synthese'], source.synthese);
      expect(map['analyse'], source.analyse);
      expect(map['photoPath'], source.photoPath);
      expect(map['exercises'], source.exercises);
      expect(series.single['comment'], 'Série source');

      (map['exercises'] as List<String>).removeAt(0);
      series.single['comment'] = 'Copie modifiée';
      expect(source.exercises, ['ex-1', 'ex-2']);
      expect(source.series.single.comment, 'Série source');
    });

    test('prépare une session libre avec date vide et champs conservés', () {
      final source = SimpleShootingSession(
        id: 9,
        date: DateTime(2026, 8, 20),
        weapon: 'Carabine',
        caliber: '.22 LR',
        shotCount: 40,
        distance: 50,
        synthese: 'Libre',
        exercises: ['ex-libre'],
      );

      final draft = service.prepareDuplication(source);
      final map = draft.initialSessionData['session'] as Map<String, dynamic>;

      expect(draft.isSimple, isTrue);
      expect(map['id'], isNull);
      expect(map['date'], isNull);
      expect(map['shotCount'], 40);
      expect(map['distance'], 50);
      (map['exercises'] as List<String>).clear();
      expect(source.exercises, ['ex-libre']);
    });

    test('enregistre une copie profonde avec nouvel identifiant', () async {
      final source = _detailed();
      final draft = service.prepareDuplication(source);
      final edited = DetailedShootingSession(
        date: DateTime(2026, 9, 4),
        weapon: source.weapon,
        caliber: source.caliber,
        series:
            source.series.map((item) => Series.fromMap(item.toMap())).toList(),
        category: source.category,
        status: source.status,
        synthese: source.synthese,
        analyse: source.analyse,
        exercises: List<String>.from(source.exercises),
      );

      final saved = await service.saveDuplication(
        draft: draft,
        editedCopy: edited,
      );

      expect(saved.id, 100);
      expect(saved.id, isNot(source.id));
      expect(saved.date, DateTime(2026, 9, 4));
      final detailed = saved as DetailedShootingSession;
      detailed.series.single.comment = 'Changé';
      detailed.exercises.clear();
      expect(source.series.single.comment, 'Série source');
      expect(source.exercises, ['ex-1', 'ex-2']);
    });

    test('refuse une session réalisée sans nouvelle date', () async {
      final source = _detailed();
      final draft = service.prepareDuplication(source);
      final edited = DetailedShootingSession(
        weapon: source.weapon,
        caliber: source.caliber,
        series: [Series(distance: 25, points: 45, groupSize: 5)],
      );

      await expectLater(
        service.saveDuplication(draft: draft, editedCopy: edited),
        throwsArgumentError,
      );
      expect(repository.sessions, isEmpty);
    });

    test('duplique physiquement la photo uniquement à l’enregistrement',
        () async {
      final source = _detailed(photoPath: '/photos/source.jpg');
      final draft = service.prepareDuplication(source);
      expect(photoService.duplicated, isEmpty);
      final edited = DetailedShootingSession(
        date: DateTime(2026, 9, 4),
        weapon: source.weapon,
        caliber: source.caliber,
        series: [Series(distance: 25, points: 45, groupSize: 5)],
        photoPath: source.photoPath,
      );

      final saved = await service.saveDuplication(
        draft: draft,
        editedCopy: edited,
      );

      expect(photoService.duplicated, ['/photos/source.jpg']);
      expect(saved.photoPath, '/photos/source.jpg.independent');
      expect(saved.photoPath, isNot(source.photoPath));
      expect(source.photoPath, '/photos/source.jpg');
    });

    test('rollback la photo si l’écriture échoue', () async {
      repository.failInsert = true;
      final source = _detailed(photoPath: '/photos/source.jpg');
      final draft = service.prepareDuplication(source);
      final edited = DetailedShootingSession(
        date: DateTime(2026, 9, 4),
        weapon: source.weapon,
        caliber: source.caliber,
        series: [Series(distance: 25, points: 45, groupSize: 5)],
        photoPath: source.photoPath,
      );

      await expectLater(
        service.saveDuplication(draft: draft, editedCopy: edited),
        throwsStateError,
      );

      expect(repository.sessions, isEmpty);
      expect(photoService.deleted, ['/photos/source.jpg.independent']);
      expect(source.photoPath, '/photos/source.jpg');
    });

    test('un échec de copie photo n’insère aucune session', () async {
      photoService.failCopy = true;
      final source = _detailed(photoPath: '/photos/source.jpg');
      final draft = service.prepareDuplication(source);
      final edited = DetailedShootingSession(
        date: DateTime(2026, 9, 4),
        weapon: source.weapon,
        caliber: source.caliber,
        series: [Series(distance: 25, points: 45, groupSize: 5)],
        photoPath: source.photoPath,
      );

      await expectLater(
        service.saveDuplication(draft: draft, editedCopy: edited),
        throwsStateError,
      );
      expect(repository.sessions, isEmpty);
    });

    test('refuse de préparer un brouillon guidé', () {
      final draft = _detailed(status: SessionConstants.statusDraft);
      expect(() => service.prepareDuplication(draft), throwsStateError);
    });
  });
}
