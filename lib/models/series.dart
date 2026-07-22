enum HandMethod { oneHand, twoHands }

enum TarSequenceType { essai, precision, vitesse }

enum SeriesScoringMode { pointsZone, gongsTombes }

class Series {
  int? id;
  int shotCount;
  double distance;
  int points;
  double groupSize;
  String comment;
  HandMethod handMethod; // prise (1 main / 2 mains)
  TarSequenceType? sequenceType; // essai / precision / vitesse (TAR)
  SeriesScoringMode scoringMode; // points/zone ou gongs tombes
  String? targetType; // C50 / cible_vitesse_25m / gong
  String? timeLimitLabel; // libelle reglementaire: "7 min", "2 x 20 s", ...
  int? timeLimitSeconds;
  int? gongsHit;
  int gongPointValue;

  Series({
    this.id,
    this.shotCount = 5,
    required this.distance,
    required this.points,
    required this.groupSize,
    this.comment = '',
    this.handMethod = HandMethod.twoHands,
    this.sequenceType,
    this.scoringMode = SeriesScoringMode.pointsZone,
    this.targetType,
    this.timeLimitLabel,
    this.timeLimitSeconds,
    this.gongsHit,
    this.gongPointValue = 5,
  });

  bool get isTrial => sequenceType == TarSequenceType.essai;
  bool get isScoreCounted => !isTrial;

  int get scoredPoints {
    if (scoringMode == SeriesScoringMode.gongsTombes && gongsHit != null) {
      return gongsHit! * gongPointValue;
    }
    return points;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shot_count': shotCount,
      'distance': distance,
      'points': points,
      'group_size': groupSize,
      'comment': comment,
      'hand_method': handMethod == HandMethod.oneHand ? 'one' : 'two',
      'sequence_type': _sequenceTypeToMap(sequenceType),
      'scoring_mode': _scoringModeToMap(scoringMode),
      'target_type': targetType,
      'time_limit_label': timeLimitLabel,
      'time_limit_seconds': timeLimitSeconds,
      'gongs_hit': gongsHit,
      'gong_point_value': gongPointValue,
    };
  }

  static Series fromMap(Map<String, dynamic> map) {
    final rawMethod = map['hand_method'];
    HandMethod method;
    if (rawMethod == 'one') {
      method = HandMethod.oneHand;
    } else if (rawMethod == 'two') {
      method = HandMethod.twoHands;
    } else {
      method = HandMethod.twoHands; // fallback, migration implicite
    }
    return Series(
      id: map['id'] as int?,
      shotCount: map['shot_count'] as int? ?? 5,
      distance: (map['distance'] as num?)?.toDouble() ?? 0,
      points: map['points'] as int? ?? 0,
      groupSize: (map['group_size'] as num?)?.toDouble() ?? 0,
      comment: map['comment'] as String? ?? '',
      handMethod: method,
      sequenceType: _sequenceTypeFromMap(map['sequence_type']),
      scoringMode: _scoringModeFromMap(map['scoring_mode']),
      targetType: map['target_type'] as String?,
      timeLimitLabel: map['time_limit_label'] as String?,
      timeLimitSeconds: _intFromMap(map['time_limit_seconds']),
      gongsHit: _intFromMap(map['gongs_hit']),
      gongPointValue: _intFromMap(map['gong_point_value']) ?? 5,
    );
  }

  static String? _sequenceTypeToMap(TarSequenceType? type) {
    switch (type) {
      case TarSequenceType.essai:
        return 'essai';
      case TarSequenceType.precision:
        return 'precision';
      case TarSequenceType.vitesse:
        return 'vitesse';
      case null:
        return null;
    }
  }

  static TarSequenceType? _sequenceTypeFromMap(dynamic value) {
    switch (value) {
      case 'essai':
        return TarSequenceType.essai;
      case 'precision':
        return TarSequenceType.precision;
      case 'vitesse':
        return TarSequenceType.vitesse;
      default:
        return null;
    }
  }

  static String _scoringModeToMap(SeriesScoringMode mode) {
    switch (mode) {
      case SeriesScoringMode.pointsZone:
        return 'points_zone';
      case SeriesScoringMode.gongsTombes:
        return 'gongs_tombes';
    }
  }

  static SeriesScoringMode _scoringModeFromMap(dynamic value) {
    switch (value) {
      case 'gongs_tombes':
        return SeriesScoringMode.gongsTombes;
      case 'points_zone':
      default:
        return SeriesScoringMode.pointsZone;
    }
  }

  static int? _intFromMap(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
