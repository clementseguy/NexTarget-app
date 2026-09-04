import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/shooting_session.dart';
import 'auth_service.dart';
import 'authenticated_http_client.dart';
import 'coach_analysis_exception.dart';

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
  final String baseUrl;
  final http.Client _client;

  ServerCoachAnalysisService({
    required this.baseUrl,
    required AuthService authService,
    http.Client? client,
  }) : _client = client ?? AuthenticatedHttpClient(authService);

  Map<String, dynamic> _seriesToJson(dynamic s) {
    return {
      'shot_count': s.shotCount,
      'distance': s.distance,
      'points': s.points,
      'group_size_cm': s.groupSize,
      'comment': s.comment,
    };
  }

  /// Envoie la session au serveur et retourne le texte d'analyse.
  /// [promptVariant] permet la future sélection de persona coach
  /// (neutre / cool), défaut = 'coach_neutre'.
  Future<String> analyzeSession(
    ShootingSession session, {
    String promptVariant = 'coach_neutre',
  }) async {
    final body = jsonEncode({
      'session': {
        'weapon': session.weapon,
        'caliber': session.caliber,
        'date': session.date?.toIso8601String(),
        'series': session.series.map(_seriesToJson).toList(),
        'synthese': session.synthese,
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
    } on TimeoutException {
      throw CoachAnalysisException('Le serveur ne répond pas (timeout).');
    } on SocketException catch (e) {
      throw CoachAnalysisException('Connexion impossible (réseau ou DNS): ${e.message}');
    } catch (e) {
      throw CoachAnalysisException('Erreur réseau inattendue: $e');
    }

    if (response.statusCode == 401) {
      throw CoachAnalysisException('Session expirée, reconnectez-vous.');
    }
    if (response.statusCode == 422) {
      throw CoachAnalysisException('Données de session invalides.');
    }
    if (response.statusCode == 429) {
      throw CoachAnalysisException('Trop de requêtes (429), réessayez plus tard.');
    }
    if (response.statusCode >= 500) {
      throw CoachAnalysisException('Erreur serveur (${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CoachAnalysisException('Erreur HTTP ${response.statusCode}.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = data['analysis']?.toString();
    if (analysis == null || analysis.trim().isEmpty) {
      throw CoachAnalysisException('Réponse vide du modèle.');
    }
    return analysis;
  }
}
