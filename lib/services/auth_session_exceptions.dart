/// Exceptions dédiées au cycle de vie de la session connectée (NT-048).
///
/// Permettent de distinguer une session réellement terminée (reconnexion
/// Google requise) d'une simple panne réseau (fonctionnalités connectées
/// temporairement indisponibles, sans perte des tokens ni déconnexion).
library;

/// Le refresh token est invalide, expiré, révoqué ou a été rejoué (ou
/// l'installation est historique, sans refresh token) : la session
/// connectée est terminée et une reconnexion Google est nécessaire.
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);
  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Le serveur d'authentification est injoignable (réseau, timeout, DNS...).
/// Les tokens locaux ne sont pas modifiés ; seules les fonctionnalités
/// connectées sont temporairement indisponibles.
class NetworkUnavailableException implements Exception {
  final String message;
  NetworkUnavailableException(this.message);
  @override
  String toString() => 'NetworkUnavailableException: $message';
}
