/// Exception dédiée pour distinguer les erreurs d'analyse coach.
///
/// Historiquement définie dans `coach_analysis_service.dart` (appel Mistral
/// direct, supprimé par NT-061) ; conservée ici car elle porte les messages
/// d'erreur user-friendly affichés par l'UI (SessionCoachAnalysisSection).
class CoachAnalysisException implements Exception {
  final String message;
  CoachAnalysisException(this.message);
  @override
  String toString() => 'CoachAnalysisException: $message';
}

/// Refus local d'une transmission de données sans consentement explicite.
class CoachConsentRequiredException extends CoachAnalysisException {
  CoachConsentRequiredException()
      : super(
          'Le partage de vos données est requis pour que le Coach puisse les analyser.',
        );
}
