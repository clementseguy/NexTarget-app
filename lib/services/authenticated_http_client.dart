import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'auth_session_exceptions.dart';

/// HTTP Client wrapper qui injecte un access token valide (NT-048).
///
/// - Renouvellement proactif juste avant expiration (délégué à
///   `AuthService.getValidAccessToken()`, single-flight).
/// - Si un `401` survient malgré tout, un unique renouvellement réactif
///   (`AuthService.forceRefreshAfterUnauthorized()`) suivi d'un unique
///   rejeu de la requête : jamais de boucle.
/// - Le corps de la requête d'origine est lu une seule fois en mémoire
///   (`request.finalize().toBytes()`) puis rejoué depuis une requête neuve
///   à chaque tentative : `request` (potentiellement un corps streamé)
///   n'est donc jamais renvoyé tel quel ni finalisé deux fois.
///
/// Utilisé par tous les appels authentifiés : Coach (`ServerCoachAnalysisService`)
/// et profil (`AuthService.getUserInfo`/`AuthService.updateProfile`).
class AuthenticatedHttpClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _innerClient;

  AuthenticatedHttpClient(this._authService, {http.Client? client})
      : _innerClient = client ?? http.Client();

  http.BaseRequest _cloneWithToken(
    http.BaseRequest original,
    List<int> bodyBytes,
    String token,
  ) {
    final clone = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..bodyBytes = bodyBytes;
    clone.headers['Authorization'] = 'Bearer $token';
    return clone;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Lu une seule fois : `request` ne sera jamais renvoyé ni finalisé à nouveau.
    final bodyBytes = await request.finalize().toBytes();

    final token = await _authService.getValidAccessToken();
    final response =
        await _innerClient.send(_cloneWithToken(request, bodyBytes, token));

    if (response.statusCode != 401) {
      return response;
    }

    final String newToken;
    try {
      newToken = await _authService.forceRefreshAfterUnauthorized();
    } on NetworkUnavailableException {
      // Pas de renouvellement possible pour l'instant : on garde la réponse
      // d'origine, sans nouvelle tentative ni boucle.
      return response;
    }

    return _innerClient.send(_cloneWithToken(request, bodyBytes, newToken));
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
