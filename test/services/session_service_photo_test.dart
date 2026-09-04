import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/services/session_service.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/repositories/session_repository.dart';
import 'package:tir_sportif/interfaces/session_photo_service_interface.dart';
import 'package:tir_sportif/constants/session_constants.dart';

/// Fake in-memory du repository de sessions (pas de dépendance Hive).
///
/// Stocke des instantanés (via toMap/fromMap, comme le fait réellement
/// [HiveSessionRepository] en sérialisant vers Hive) plutôt que la référence
/// de l'objet [ShootingSession] : une mutation ultérieure de l'objet appelant
/// ne doit pas modifier silencieusement la valeur déjà persistée.
class _FakeSessionRepository implements SessionRepository {
  final List<ShootingSession> sessions = [];
  int _nextId = 1;

  ShootingSession _snapshot(ShootingSession session) => ShootingSession.fromMap(session.toMap());

  @override
  Future<List<ShootingSession>> getAll() async => sessions.map(_snapshot).toList();

  @override
  Future<int> insert(ShootingSession session) async {
    final id = _nextId++;
    session.id = id;
    sessions.add(_snapshot(session));
    return id;
  }

  @override
  Future<bool> update(ShootingSession session, {bool preserveExistingSeriesIfEmpty = true}) async {
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) sessions[idx] = _snapshot(session);
    return false;
  }

  @override
  Future<void> delete(int id) async {
    sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearAll() async {
    sessions.clear();
  }
}

/// Fake du service de photo : ne fait qu'enregistrer les chemins supprimés,
/// sans jamais toucher au disque ni au plugin image_picker.
class _FakeSessionPhotoService implements ISessionPhotoService {
  final List<String?> deletedPaths = [];

  @override
  Future<void> deleteIfExists(String? path) async {
    deletedPaths.add(path);
  }

  @override
  Future<String?> pickAndStore(ImageSource source) async => null;
}

void main() {
  group('SessionService - nettoyage des photos (NT-005)', () {
    late _FakeSessionRepository repo;
    late _FakeSessionPhotoService photoService;
    late SessionService service;

    setUp(() {
      repo = _FakeSessionRepository();
      photoService = _FakeSessionPhotoService();
      service = SessionService(repository: repo, photoService: photoService);
    });

    test('updateSession supprime l\'ancienne photo si elle est remplacée', () async {
      final session = ShootingSession(
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: const [], photoPath: '/docs/old.jpg',
      );
      await service.addSession(session);

      session.photoPath = '/docs/new.jpg';
      await service.updateSession(session);

      expect(photoService.deletedPaths, contains('/docs/old.jpg'));
      expect(photoService.deletedPaths, isNot(contains('/docs/new.jpg')));
    });

    test('updateSession ne supprime rien si la photo est inchangée', () async {
      final session = ShootingSession(
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: const [], photoPath: '/docs/same.jpg',
      );
      await service.addSession(session);

      await service.updateSession(session);

      expect(photoService.deletedPaths, isEmpty);
    });

    test('updateSession supprime l\'ancienne photo si elle est retirée', () async {
      final session = ShootingSession(
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: const [], photoPath: '/docs/old.jpg',
      );
      await service.addSession(session);

      session.photoPath = null;
      await service.updateSession(session);

      expect(photoService.deletedPaths, contains('/docs/old.jpg'));
    });

    test('deleteSession supprime la photo associée', () async {
      final session = ShootingSession(
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: const [], photoPath: '/docs/to_delete.jpg',
      );
      await service.addSession(session);

      await service.deleteSession(session.id!);

      expect(photoService.deletedPaths, contains('/docs/to_delete.jpg'));
    });

    test('deleteSession ne tente pas de supprimer si aucune photo n\'est associée', () async {
      final session = ShootingSession(
        weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee,
        series: const [],
      );
      await service.addSession(session);

      await service.deleteSession(session.id!);

      expect(photoService.deletedPaths, isEmpty);
    });

    test('clearAllSessions supprime toutes les photos existantes avant la purge', () async {
      final s1 = ShootingSession(weapon: 'P', caliber: '22LR', status: SessionConstants.statusRealisee, series: const [], photoPath: '/docs/a.jpg');
      final s2 = ShootingSession(weapon: 'C', caliber: '9mm', status: SessionConstants.statusRealisee, series: const [], photoPath: '/docs/b.jpg');
      final s3 = ShootingSession(weapon: 'R', caliber: '.38', status: SessionConstants.statusRealisee, series: const []);
      await service.addSession(s1);
      await service.addSession(s2);
      await service.addSession(s3);

      await service.clearAllSessions();

      expect(photoService.deletedPaths, containsAll(['/docs/a.jpg', '/docs/b.jpg']));
      final remaining = await repo.getAll();
      expect(remaining, isEmpty);
    });
  });
}
