import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/series.dart';

void main() {
  group('Series model mapping & defaults', () {
    test('toMap/fromMap roundtrip preserves fields and hand_method encoding',
        () {
      final s = Series(
        id: 7,
        shotCount: 6,
        distance: 25,
        points: 55,
        groupSize: 18.5,
        comment: 'ok',
        handMethod: HandMethod.oneHand,
        sequenceType: TarSequenceType.vitesse,
        scoringMode: SeriesScoringMode.gongsTombes,
        targetType: 'gong',
        timeLimitLabel: '2 x 10 s',
        timeLimitSeconds: 10,
        gongsHit: 4,
      );
      final map = s.toMap();
      expect(map['hand_method'], 'one');
      expect(map['sequence_type'], 'vitesse');
      expect(map['scoring_mode'], 'gongs_tombes');
      expect(map['gong_point_value'], 5);
      final s2 = Series.fromMap(Map<String, dynamic>.from(map));
      expect(s2.id, 7);
      expect(s2.shotCount, 6);
      expect(s2.distance, 25);
      expect(s2.points, 55);
      expect(s2.groupSize, 18.5);
      expect(s2.comment, 'ok');
      expect(s2.handMethod, HandMethod.oneHand);
      expect(s2.sequenceType, TarSequenceType.vitesse);
      expect(s2.scoringMode, SeriesScoringMode.gongsTombes);
      expect(s2.targetType, 'gong');
      expect(s2.timeLimitLabel, '2 x 10 s');
      expect(s2.timeLimitSeconds, 10);
      expect(s2.gongsHit, 4);
      expect(s2.scoredPoints, 20);
    });

    test(
        'fromMap handles unknown hand_method and missing fields with safe defaults',
        () {
      final s = Series.fromMap({
        'id': 1,
        'distance': 10.0,
        'hand_method': 'unknown',
        // shot_count, points, group_size, comment missing
      });
      expect(s.shotCount, 5);
      expect(s.points, 0);
      expect(s.groupSize, 0);
      expect(s.comment, '');
      expect(s.handMethod, HandMethod.twoHands);
      expect(s.sequenceType, isNull);
      expect(s.scoringMode, SeriesScoringMode.pointsZone);
      expect(s.targetType, isNull);
      expect(s.gongsHit, isNull);
      expect(s.gongPointValue, 5);
      expect(s.isScoreCounted, isTrue);
      expect(s.scoredPoints, 0);
    });

    test('trial series are not score-counted', () {
      final s = Series(
        distance: 25,
        points: 42,
        groupSize: 12,
        sequenceType: TarSequenceType.essai,
      );
      expect(s.isTrial, isTrue);
      expect(s.isScoreCounted, isFalse);
    });
  });
}
