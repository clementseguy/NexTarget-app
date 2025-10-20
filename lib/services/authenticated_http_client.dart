import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// HTTP Client wrapper qui injecte automatiquement le JWT dans les requetes.
///
/// Usage:
/// ```dart
/// final client = AuthenticatedHttpClient(authService);
/// final response = await client.get(Uri.parse('https://api.com/data'));
/// // Authorization: Bearer <token> ajoute automatiquement
/// ```
class AuthenticatedHttpClient extends http.BaseClient {
  final AuthService _authService;
  final http.Client _innerClient;

  AuthenticatedHttpClient(this._authService, {http.Client? client})
      : _innerClient = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _authService.getToken();
    
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    return _innerClient.send(request);
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
