enum ExerciseResult { succeeded, failed, notEvaluable }

enum CoachNextAction { repeatExercise, requestProgressionCoach }

class ExerciseEvaluation {
  final ExerciseResult result;
  final String debrief;

  const ExerciseEvaluation({required this.result, required this.debrief});

  Map<String, dynamic> toMap() => {
        'result': switch (result) {
          ExerciseResult.succeeded => 'succeeded',
          ExerciseResult.failed => 'failed',
          ExerciseResult.notEvaluable => 'not_evaluable',
        },
        'debrief': debrief,
      };

  factory ExerciseEvaluation.fromMap(Map<String, dynamic> map) =>
      ExerciseEvaluation(
        result: switch (map['result']) {
          'succeeded' => ExerciseResult.succeeded,
          'failed' => ExerciseResult.failed,
          'not_evaluable' => ExerciseResult.notEvaluable,
          _ => throw const FormatException('Résultat d’exercice inconnu.'),
        },
        debrief: _requiredText(map['debrief'], 'débrief de l’exercice'),
      );
}

class CoachSessionAnalysis {
  final String analysisId;
  final String sessionId;
  final String debrief;
  final List<String> successes;
  final String attentionPoint;
  final List<String> limitations;
  final ExerciseEvaluation? exerciseEvaluation;
  final CoachNextAction? nextAction;
  final String model;
  final DateTime generatedAt;
  final bool reused;

  const CoachSessionAnalysis({
    required this.analysisId,
    required this.sessionId,
    required this.debrief,
    required this.successes,
    required this.attentionPoint,
    required this.limitations,
    required this.exerciseEvaluation,
    required this.nextAction,
    required this.model,
    required this.generatedAt,
    this.reused = false,
  });

  Map<String, dynamic> toMap() => {
        'analysis_id': analysisId,
        'session_id': sessionId,
        'debrief': debrief,
        'successes': successes,
        'attention_point': attentionPoint,
        'limitations': limitations,
        'exercise_evaluation': exerciseEvaluation?.toMap(),
        'next_action': switch (nextAction) {
          CoachNextAction.repeatExercise => 'repeat_exercise',
          CoachNextAction.requestProgressionCoach =>
            'request_progression_coach',
          null => null,
        },
        'model': model,
        'generated_at': generatedAt.toUtc().toIso8601String(),
        'reused': reused,
      };

  factory CoachSessionAnalysis.fromMap(Map<String, dynamic> map) {
    final successes = _stringList(map['successes'], 'réussites');
    if (successes.isEmpty || successes.length > 3) {
      throw const FormatException('Nombre de réussites invalide.');
    }
    final rawEvaluation = map['exercise_evaluation'];
    final rawGeneratedAt = map['generated_at'];
    final generatedAt = rawGeneratedAt is String
        ? DateTime.tryParse(rawGeneratedAt)
        : rawGeneratedAt is DateTime
            ? rawGeneratedAt
            : null;
    if (generatedAt == null) {
      throw const FormatException('Date d’analyse invalide.');
    }
    return CoachSessionAnalysis(
      analysisId: _requiredText(map['analysis_id'], 'identifiant d’analyse'),
      sessionId: _requiredText(map['session_id'], 'identifiant de session'),
      debrief: _requiredText(map['debrief'], 'débrief'),
      successes: successes,
      attentionPoint:
          _requiredText(map['attention_point'], 'point d’attention'),
      limitations: _stringList(map['limitations'], 'limites'),
      exerciseEvaluation: rawEvaluation is Map
          ? ExerciseEvaluation.fromMap(
              Map<String, dynamic>.from(rawEvaluation),
            )
          : null,
      nextAction: switch (map['next_action']) {
        'repeat_exercise' => CoachNextAction.repeatExercise,
        'request_progression_coach' => CoachNextAction.requestProgressionCoach,
        null => null,
        _ => throw const FormatException('Prochaine action inconnue.'),
      },
      model: _requiredText(map['model'], 'modèle'),
      generatedAt: generatedAt,
      reused: map['reused'] == true,
    );
  }
}

String _requiredText(dynamic value, String label) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$label invalide.');
  }
  return value.trim();
}

List<String> _stringList(dynamic value, String label) {
  if (value is! List) throw FormatException('$label invalides.');
  final values = value.whereType<String>().map((item) => item.trim()).toList();
  if (values.length != value.length || values.any((item) => item.isEmpty)) {
    throw FormatException('$label invalides.');
  }
  return values;
}
