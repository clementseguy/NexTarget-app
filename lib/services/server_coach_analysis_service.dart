import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';
import '../models/exercise_execution.dart';
import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import 'auth_service.dart';
import 'auth_session_exceptions.dart';
import 'authenticated_http_client.dart';
import 'coach_analysis_exception.dart';
import 'logger.dart';
import 'network_error.dart';

/// Service coach IA : appelle NexTarget-server
/// (POST /coach/analyze-session), unique chemin d'analyse depuis NT-061
/// (« coach connecté uniquement », décision produit du 7 juillet 2026).
///
/// Le client n'envoie ni clé API ni prompt complet, seulement les données
/// de la session ; le serveur détient le prompt et la clé Mistral.
///
/// Les cas d'erreur (timeout, réseau, 401/429/5xx) sont exposés via
/// [CoachAnalysisException] avec des messages user-friendly affichés
/// tels quels par l'UI (SessionCoachAnalysisSection).
class ServerCoachAnalysisService {
  static const int personalExerciseIdMaxLength = 128;
  static const int personalExerciseNameMaxLength = 120;
  static const int personalExerciseDescriptionMaxLength = 2000;
  static const int personalExerciseInstructionMaxLength = 500;
  static const int personalExerciseInstructionsMaxCount = 20;
  static const int exerciseExecutionCommentMaxLength = 1000;

  final String baseUrl;
  final AuthService _authService;
  final http.Client _client;

  ServerCoachAnalysisService({
    required this.baseUrl,
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? AuthenticatedHttpClient(authService);

  Map<String, dynamic> _seriesToJson(dynamic s) {
    return {
      'shot_count': s.shotCount,
      'distance': s.distance,
      'points': s.points,
      'group_size_cm': s.groupSize,
      'comment': s.comment,
    };
  }

  Map<String, dynamic>? _personalExerciseToJson(Exercise? exercise) {
    if (exercise == null || exercise.origin != ExerciseOrigin.personal) {
      return null;
    }
    _checkTextLength(
      exercise.id,
      personalExerciseIdMaxLength,
      'identifiant de l’exercice personnel',
    );
    _checkTextLength(
      exercise.name,
      personalExerciseNameMaxLength,
      'nom de l’exercice personnel',
    );
    if (exercise.description != null) {
      _checkTextLength(
        exercise.description!,
        personalExerciseDescriptionMaxLength,
        'description de l’exercice personnel',
      );
    }
    if (exercise.consignes.length > personalExerciseInstructionsMaxCount) {
      throw InvalidNetworkRequestException(
        'L’exercice personnel contient trop de consignes.',
      );
    }
    for (final instruction in exercise.consignes) {
      _checkTextLength(
        instruction,
        personalExerciseInstructionMaxLength,
        'consigne de l’exercice personnel',
      );
    }
    return {
      'id': exercise.id,
      'name': exercise.name,
      'origin': exercise.origin.serializedName,
      'description': exercise.description,
      'consignes': exercise.consignes,
    };
  }

  Map<String, dynamic>? _exerciseExecutionToJson(
    ExerciseExecution? execution,
  ) {
    if (execution == null) return null;
    if (execution.comment != null) {
      _checkTextLength(
        execution.comment!,
        exerciseExecutionCommentMaxLength,
        'commentaire d’exécution',
      );
    }
    return {
      'performed': execution.performed,
      'protocol_followed': execution.protocolFollowed?.name,
      'comment': execution.comment,
    };
  }

  void _checkTextLength(String value, int maximum, String fieldLabel) {
    if (value.isEmpty || value.runes.length > maximum) {
      throw InvalidNetworkRequestException(
        'Le $fieldLabel est vide ou dépasse la taille autorisée.',
      );
    }
  }

  /// Envoie la session au serveur et retourne le texte d'analyse.
  /// [promptVariant] permet la future sélection de persona coach
  /// (neutre / cool), défaut = 'coach_neutre'.
  Future<String> analyzeSession(
    DetailedShootingSession session, {
    required bool coachDataSharingAllowed,
    Exercise? exercise,
    String promptVariant = 'coach_neutre',
  }) async {
    if (!coachDataSharingAllowed) {
      throw CoachConsentRequiredException();
    }
    if (session.status != SessionConstants.statusRealisee) {
      throw CoachAnalysisException(
        'Seule une session réalisée peut être analysée par le Coach.',
      );
    }
    final personalExercise = exercise?.id == session.exerciseId
        ? _personalExerciseToJson(exercise)
        : null;
    final exerciseExecution = personalExercise == null
        ? null
        : _exerciseExecutionToJson(session.exerciseExecution);
    final body = jsonEncode({
      'session': {
        'weapon': session.weapon,
        'caliber': session.caliber,
        'date': session.date?.toIso8601String(),
        'exerciseId': session.exerciseId,
        'series': session.series.map(_seriesToJson).toList(),
        'synthese': session.synthese,
        'personal_exercise': personalExercise,
        'exercise_execution': exerciseExecution,
      },
      'prompt_variant': promptVariant,
    });

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/coach/analyze-session'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } on SessionExpiredException {
      rethrow;
    } on NetworkUnavailableException catch (error, stackTrace) {
      AppLogger.I.error('COACH: réseau indisponible', error, stackTrace);
      if (error is NetworkOperationException) rethrow;
      throw NetworkOperationException(
          NetworkErrorFamily.offline, error.message);
    } on TimeoutException catch (error, stackTrace) {
      AppLogger.I.error('COACH: délai dépassé', error, stackTrace);
      throw NetworkOperationException(NetworkErrorFamily.timeout, '$error');
    } on SocketException catch (e) {
      AppLogger.I.error('COACH: connexion impossible', e);
      throw NetworkOperationException(NetworkErrorFamily.offline, e.message);
    } catch (error, stackTrace) {
      AppLogger.I.error('COACH: erreur inattendue', error, stackTrace);
      rethrow;
    }

    if (response.statusCode == 401) {
      await _authService.invalidateSession();
      throw SessionExpiredException('Réponse HTTP 401 du Coach.');
    }
    if (response.statusCode == 422) {
      throw InvalidNetworkRequestException('Réponse HTTP 422 du Coach.');
    }
    if (response.statusCode == 429) {
      throw NetworkOperationException(
        NetworkErrorFamily.rateLimited,
        'Réponse HTTP 429 du Coach.',
      );
    }
    if (response.statusCode >= 500) {
      throw NetworkOperationException(
        NetworkErrorFamily.serviceUnavailable,
        'Réponse HTTP ${response.statusCode} du Coach.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InvalidNetworkRequestException(
        'Réponse HTTP ${response.statusCode} du Coach.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = data['analysis']?.toString();
    if (analysis == null || analysis.trim().isEmpty) {
      throw CoachAnalysisException('Réponse vide du modèle.');
    }
    return analysis;
  }
}
