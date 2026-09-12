import 'dart:math';

import '../constants/session_constants.dart';
import '../models/exercise.dart';
import '../models/exercise_execution.dart';
import '../models/series.dart';
import '../models/shooting_session.dart';
import 'exercise_service.dart';
import 'session_service.dart';

/// Génère en DEBUG un jeu de sessions variées pour la recette du Coach.
class DebugCoachFixtureService {
  static const _weapon = 'GLOCK 17';
  static const _caliber = '9mm (9x19)';
  static const _positiveSummary =
      'Bonne session, agréable, bonnes sensations, posture semble ok et '
      'lâcher semble plus régulier';

  final ExerciseService _exerciseService;
  final SessionService _sessionService;
  final Random _random;

  DebugCoachFixtureService({
    ExerciseService? exerciseService,
    SessionService? sessionService,
    Random? random,
  })  : _exerciseService = exerciseService ?? ExerciseService(),
        _sessionService = sessionService ?? SessionService(),
        _random = random ?? Random();

  Future<void> createCoachReviewFixtures() async {
    final now = DateTime.now();
    final exercise = Exercise(
      id: _exerciseService.generateId(),
      name: 'Groupement Débutant ${_random.nextInt(101)}',
      categoryEnum: ExerciseCategory.technique,
      type: ExerciseType.stand,
      difficulty: ExerciseDifficulty.beginner,
      description: 'Stabiliser et réduire le groupement.',
      durationMinutes: 45,
      equipment: null,
      createdAt: now,
      consignes: List.filled(
        10,
        'A 2 mains, viser le centre à 25m, rester en position entre les tirs',
      ),
    );
    await _exerciseService.createExercise(exercise);

    final positiveComments = [
      'un peu à droite',
      'bonne sensation de lâcher',
      'visée ok + gainage bras ok',
      'un peu bas',
      '1 tir perdu',
    ];
    final mixedComments = [
      'trop à droite',
      'ai fermé l’œil',
      '1 tir perdu',
      '3 centrés, 2 en bas à droite',
      'mal au bras à la fin, ai tiré trop lentement',
    ];
    final protocolNotFollowedComments = [
      'trop à droite',
      'ai testé le reset',
      'ai testé en ouvrant les 2 yeux',
      '5 tirs rapides dans la même respiration',
    ];

    await _sessionService.addSessionsAtomically([
      _session(
        date: now,
        exerciseId: exercise.id,
        series: _progressingSeries(positiveComments),
        summary: _positiveSummary,
        execution: const ExerciseExecution(
          performed: true,
          protocolFollowed: ProtocolFollowed.yes,
          comment: 'Exercice suivi, me suis concentré sur el groupement et '
              'pas sur le score',
        ),
      ),
      _session(
        date: now.subtract(const Duration(days: 1)),
        exerciseId: exercise.id,
        series: _randomSeries(mixedComments),
        summary: 'Session moyenne, agréable mais pas satisfaisante, '
            'sensations irrégulières, parfois OK parfois nulles, revoir la '
            'posture et le lâcher',
        execution: const ExerciseExecution(
          performed: true,
          protocolFollowed: ProtocolFollowed.yes,
          comment: 'Exercice suivi, résultats pas fou, que faut-il prioriser '
              'entre le lâcher et le gainage des bras ? œil qui se ferme au '
              'moment de la détonation',
        ),
      ),
      _session(
        date: now.subtract(const Duration(days: 2)),
        exerciseId: exercise.id,
        series: _randomSeries(protocolNotFollowedComments),
        summary: 'Session moyenne, agréable mais pas satisfaisante, '
            'sensations irrégulières, mauvaise posture ou mauvais lâcher ?',
        execution: const ExerciseExecution(
          performed: true,
          protocolFollowed: ProtocolFollowed.no,
          comment: 'Esprit de l’exercice suivi, mais j’en ai profité pour '
              'faire quelques tests',
        ),
      ),
      _session(
        date: now.subtract(const Duration(days: 3)),
        series: _progressingSeries(positiveComments),
        summary: _positiveSummary,
      ),
    ]);
  }

  DetailedShootingSession _session({
    required DateTime date,
    required List<Series> series,
    required String summary,
    String? exerciseId,
    ExerciseExecution? execution,
  }) =>
      DetailedShootingSession(
        date: date,
        weapon: _weapon,
        caliber: _caliber,
        series: series,
        status: SessionConstants.statusRealisee,
        synthese: summary,
        category: SessionConstants.categoryEntrainement,
        exerciseId: exerciseId,
        exerciseExecution: execution,
      );

  List<Series> _progressingSeries(List<String> comments) => List.generate(
        10,
        (index) => Series(
          shotCount: 5,
          distance: 25,
          points: (30 + (15 * index / 9)).round(),
          groupSize: 20 - (12 * index / 9),
          comment: _randomComment(comments),
        ),
      );

  List<Series> _randomSeries(List<String> comments) => List.generate(
        10,
        (_) => Series(
          shotCount: 5,
          distance: 25,
          points: 20 + _random.nextInt(21),
          groupSize: 15 + _random.nextInt(11).toDouble(),
          comment: _randomComment(comments),
        ),
      );

  String _randomComment(List<String> values) =>
      values[_random.nextInt(values.length)];
}
