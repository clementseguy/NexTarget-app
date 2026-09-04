import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';

void main() {
  group('NT-133 polymorphisme des sessions', () {
    test('sérialise un brouillon détaillé et rejette un état inconnu', () {
      final draft = DetailedShootingSession(
        date: DateTime(2026, 9, 4),
        weapon: 'P',
        caliber: '9 mm',
        status: SessionConstants.statusDraft,
        series: [
          Series(
            shotCount: 5,
            distance: 25,
            points: 0,
            groupSize: 0,
            isCompleted: false,
            isDraftStarted: true,
            isScoreEntered: false,
          ),
        ],
      );

      final restored = ShootingSession.fromMap(draft.toMap());
      expect(restored, isA<DetailedShootingSession>());
      expect(restored.status, SessionConstants.statusDraft);
      expect(restored.series.single.isCompleted, isFalse);
      expect(restored.series.single.isScoreEntered, isFalse);
      expect(
        () => ShootingSession.fromMap({...draft.toMap(), 'status': 'inconnu'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ShootingSession.fromMap({...draft.toMap(), 'series': []}),
        throwsA(isA<FormatException>()),
      );
    });

    test('sérialise et relit les deux sous-types sans perte', () {
      final detailed = DetailedShootingSession(
        id: 1,
        date: DateTime(2026, 9, 1),
        weapon: 'Pistolet',
        caliber: '9 mm',
        series: [
          Series(
            shotCount: 5,
            distance: 25,
            points: 45,
            groupSize: 8,
          ),
        ],
        analyse: 'Analyse',
      );
      final simple = SimpleShootingSession(
        id: 2,
        date: DateTime(2026, 9, 2),
        weapon: 'Carabine',
        caliber: '.22 libre',
        shotCount: 42,
        distance: 50,
        category: SessionConstants.categoryTest,
        synthese: 'Bonne séance',
        exercises: const ['ex-1', 'ex-2'],
        photoPath: '/photos/cible.jpg',
      );

      final detailedCopy = ShootingSession.fromMap(detailed.toMap());
      final simpleCopy = ShootingSession.fromMap(simple.toMap());

      expect(detailedCopy, isA<DetailedShootingSession>());
      expect(detailedCopy.toMap(), detailed.toMap());
      expect(simpleCopy, isA<SimpleShootingSession>());
      expect(simpleCopy.toMap(), simple.toMap());
      expect(simpleCopy.series, isEmpty);
      expect(simpleCopy.hasAnalysis, isFalse);
      expect(simpleCopy.hasPhoto, isTrue);
      expect(simpleCopy.hasSynthese, isTrue);
    });

    test('une donnée historique sans discriminant reste détaillée', () {
      final session = ShootingSession.fromMap({
        'id': 7,
        'date': '2026-08-30T00:00:00.000',
        'weapon': 'Historique',
        'caliber': '9mm',
        'series': [
          {
            'shot_count': 5,
            'distance': 12.5,
            'points': 40,
            'group_size': 5,
          },
        ],
      });

      expect(session, isA<DetailedShootingSession>());
      expect(session.series.single.distance, 12.5);
    });

    test('un discriminant inconnu produit une erreur explicite', () {
      expect(
        () => ShootingSession.fromMap({'sessionType': 'future'}),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('future'),
          ),
        ),
      );
    });

    for (final category in SessionConstants.categories) {
      test('accepte la catégorie $category', () {
        final session = SimpleShootingSession(
          date: DateTime(2026, 9, 1),
          weapon: 'P',
          caliber: '9mm',
          shotCount: 1,
          distance: 1,
          category: category,
        );
        expect(session.category, category);
      });
    }

    test('refuse les champs obligatoires invalides', () {
      SimpleShootingSession build({
        String weapon = 'P',
        String caliber = '9mm',
        int shots = 1,
        num distance = 25,
        String category = SessionConstants.categoryEntrainement,
      }) =>
          SimpleShootingSession(
            date: DateTime(2026, 9, 1),
            weapon: weapon,
            caliber: caliber,
            shotCount: shots,
            distance: distance,
            category: category,
          );

      expect(() => build(weapon: ' '), throwsArgumentError);
      expect(() => build(caliber: ''), throwsArgumentError);
      expect(() => build(shots: 0), throwsArgumentError);
      expect(() => build(distance: 0), throwsArgumentError);
      expect(() => build(distance: 12.5), throwsArgumentError);
      expect(() => build(category: 'autre'), throwsArgumentError);
    });

    test('refuse une session libre planifiée ou un nombre de tirs décimal', () {
      final base = {
        'sessionType': 'simple',
        'date': '2026-09-01T00:00:00.000',
        'weapon': 'P',
        'caliber': '9mm',
        'shotCount': 5,
        'distance': 25,
        'category': SessionConstants.categoryMatch,
      };
      expect(
        () => ShootingSession.fromMap({...base, 'status': 'prévue'}),
        throwsFormatException,
      );
      expect(
        () => ShootingSession.fromMap({...base, 'shotCount': 5.5}),
        throwsFormatException,
      );
    });
  });
}
