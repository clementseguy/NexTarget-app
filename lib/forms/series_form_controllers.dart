import 'package:flutter/material.dart';

import '../models/series.dart';

class SeriesFormControllers {
  final TextEditingController shotCountController;
  final TextEditingController distanceController;
  final TextEditingController pointsController;
  final TextEditingController gongsHitController;
  final TextEditingController groupSizeController;
  final TextEditingController commentController;
  String handMethod; // 'one' ou 'two'
  TarSequenceType? sequenceType;
  SeriesScoringMode scoringMode;
  String? targetType;
  String? timeLimitLabel;
  int? timeLimitSeconds;
  int? gongsHit;
  int gongPointValue;
  // FocusNodes pour gestion précise du focus
  final FocusNode shotCountFocus;
  final FocusNode distanceFocus;
  final FocusNode pointsFocus;
  final FocusNode gongsHitFocus;
  final FocusNode groupSizeFocus;
  final FocusNode commentFocus;

  SeriesFormControllers({
    required int shotCount,
    required double distance,
    required int points,
    required double groupSize,
    required String comment,
    required this.handMethod,
    this.sequenceType,
    this.scoringMode = SeriesScoringMode.pointsZone,
    this.targetType,
    this.timeLimitLabel,
    this.timeLimitSeconds,
    this.gongsHit,
    this.gongPointValue = 5,
  })  : shotCountController = TextEditingController(text: shotCount.toString()),
        distanceController = TextEditingController(text: distance.toString()),
        pointsController = TextEditingController(text: points.toString()),
        gongsHitController =
            TextEditingController(text: (gongsHit ?? 0).toString()),
        groupSizeController = TextEditingController(
            text: groupSize == 0 ? '0' : groupSize.toString()),
        commentController = TextEditingController(text: comment),
        shotCountFocus = FocusNode(),
        distanceFocus = FocusNode(),
        pointsFocus = FocusNode(),
        gongsHitFocus = FocusNode(),
        groupSizeFocus = FocusNode(),
        commentFocus = FocusNode();

  bool get isGongScoring => scoringMode == SeriesScoringMode.gongsTombes;

  void syncGongPoints() {
    if (!isGongScoring) return;
    final parsed = int.tryParse(gongsHitController.text.trim()) ?? 0;
    gongsHit = parsed;
    final points = parsed * gongPointValue;
    if (pointsController.text != points.toString()) {
      pointsController.text = points.toString();
    }
  }

  void dispose() {
    shotCountController.dispose();
    distanceController.dispose();
    pointsController.dispose();
    gongsHitController.dispose();
    groupSizeController.dispose();
    commentController.dispose();
    shotCountFocus.dispose();
    distanceFocus.dispose();
    pointsFocus.dispose();
    gongsHitFocus.dispose();
    groupSizeFocus.dispose();
    commentFocus.dispose();
  }
}
