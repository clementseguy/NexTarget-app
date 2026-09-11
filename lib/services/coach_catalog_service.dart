import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'network_error.dart';

/// Télécharge un unique exercice attribué depuis le catalogue Coach.
class CoachCatalogService {
  final String baseUrl;
  final ExerciseRepository _repository;
  final http.Client _client;

  CoachCatalogService({
    required this.baseUrl,
    ExerciseRepository? repository,
    http.Client? client,
  })  : _repository = repository ?? HiveExerciseRepository(),
        _client = client ?? http.Client();

  Future<Exercise> downloadById(String requestedId) async {
    final id = requestedId.trim();
    if (id.isEmpty) {
      throw const InvalidCatalogExerciseException(
        'L’identifiant de l’exercice est vide.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$baseUrl/exercises/${Uri.encodeComponent(id)}'))
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (error) {
      throw NetworkOperationException(NetworkErrorFamily.timeout, '$error');
    } on SocketException catch (error) {
      throw NetworkOperationException(
          NetworkErrorFamily.offline, error.message);
    } on http.ClientException catch (error) {
      throw NetworkOperationException(NetworkErrorFamily.offline, '$error');
    }

    if (response.statusCode == 404) {
      throw CatalogExerciseNotFoundException(id);
    }
    if (response.statusCode >= 500) {
      throw NetworkOperationException(
        NetworkErrorFamily.serviceUnavailable,
        'Réponse HTTP ${response.statusCode} du catalogue.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InvalidCatalogExerciseException(
        'Réponse HTTP ${response.statusCode} du catalogue.',
      );
    }

    final Exercise exercise;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Objet JSON attendu.');
      }
      _validatePayload(decoded, requestedId: id);
      exercise = Exercise.fromMap(decoded);
    } on FormatException catch (error) {
      throw InvalidCatalogExerciseException('$error');
    } on TypeError catch (error) {
      throw InvalidCatalogExerciseException('$error');
    }

    final existing = (await _repository.getAll())
        .where((item) => item.id == exercise.id)
        .firstOrNull;
    if (existing?.origin == ExerciseOrigin.personal) {
      throw CatalogExerciseConflictException(exercise.id);
    }
    await _repository.put(exercise);
    return exercise;
  }

  static void _validatePayload(
    Map<String, dynamic> payload, {
    required String requestedId,
  }) {
    const categories = {
      'precision',
      'group',
      'speed',
      'technique',
      'mental',
      'physical',
    };
    const types = {'stand', 'home'};
    const difficulties = {'beginner', 'advanced', 'expert'};

    if (payload['id'] is! String || payload['id'] != requestedId) {
      throw const FormatException('Identifiant de catalogue incohérent.');
    }
    if (payload['name'] is! String ||
        (payload['name'] as String).trim().isEmpty) {
      throw const FormatException('Nom de catalogue invalide.');
    }
    if (!categories.contains(payload['category']) ||
        !types.contains(payload['type']) ||
        payload['origin'] != 'coach_catalog') {
      throw const FormatException('Valeur contrôlée invalide.');
    }
    final difficulty = payload['difficulty'];
    if (difficulty != null && !difficulties.contains(difficulty)) {
      throw const FormatException('Difficulté invalide.');
    }
    if (payload['createdAt'] is! String ||
        DateTime.tryParse(payload['createdAt'] as String) == null) {
      throw const FormatException('Date de création invalide.');
    }
    if (payload['durationMinutes'] != null &&
        payload['durationMinutes'] is! int) {
      throw const FormatException('Durée invalide.');
    }
    if (payload['priority'] != null && payload['priority'] is! int) {
      throw const FormatException('Priorité invalide.');
    }
    for (final key in const ['goalIds', 'consignes']) {
      final value = payload[key];
      if (value != null &&
          (value is! List || value.any((item) => item is! String))) {
        throw FormatException('$key invalide.');
      }
    }
    for (final key in const ['description', 'equipment']) {
      if (payload[key] != null && payload[key] is! String) {
        throw FormatException('$key invalide.');
      }
    }
  }
}

class CatalogExerciseNotFoundException implements Exception {
  final String id;

  const CatalogExerciseNotFoundException(this.id);
}

class InvalidCatalogExerciseException implements Exception {
  final String technicalMessage;

  const InvalidCatalogExerciseException(this.technicalMessage);
}

class CatalogExerciseConflictException implements Exception {
  final String id;

  const CatalogExerciseConflictException(this.id);
}
