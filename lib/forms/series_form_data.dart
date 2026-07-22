import '../models/series.dart';

class SeriesFormData {
  int shotCount;
  double distance;
  int points;
  double groupSize;
  String comment;
  HandMethod handMethod;
  TarSequenceType? sequenceType;
  SeriesScoringMode scoringMode;
  String? targetType;
  String? timeLimitLabel;
  int? timeLimitSeconds;
  int? gongsHit;
  int gongPointValue;

  SeriesFormData({
    this.shotCount = 5,
    this.distance = 0,
    this.points = 0,
    this.groupSize = 0,
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
}
