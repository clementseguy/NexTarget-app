import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/authenticated_http_client.dart';

import 'authenticated_http_client_test.mocks.dart';

@GenerateMocks([AuthService, http.Client])
void main() {
  group('AuthenticatedHttpClient', () {
    late MockAuthService mockAuthService;
    late MockClient mockInnerClient;
    late AuthenticatedHttpClient authenticatedClient;

    setUp(() {
      mockAuthService = MockAuthService();
      mockInnerClient = MockClient();
      authenticatedClient = AuthenticatedHttpClient(
        mockAuthService,
        client: mockInnerClient,
      );
    });

    test('ajoute le header Authorization si token existe', () async {
      when(mockAuthService.getToken())
          .thenAnswer((_) async => 'test_jwt_token');
      
      final request = http.Request('GET', Uri.parse('https://api.test.com/data'));
      
      when(mockInnerClient.send(any))
          .thenAnswer((_) async => http.StreamedResponse(
                Stream.value([]),
                200,
              ));

      await authenticatedClient.send(request);

      expect(request.headers['Authorization'], 'Bearer test_jwt_token');
      verify(mockAuthService.getToken()).called(1);
      verify(mockInnerClient.send(request)).called(1);
    });

    test('n\'ajoute pas le header si aucun token', () async {
      when(mockAuthService.getToken())
          .thenAnswer((_) async => null);
      
      final request = http.Request('GET', Uri.parse('https://api.test.com/data'));
      
      when(mockInnerClient.send(any))
          .thenAnswer((_) async => http.StreamedResponse(
                Stream.value([]),
                200,
              ));

      await authenticatedClient.send(request);

      expect(request.headers.containsKey('Authorization'), false);
      verify(mockAuthService.getToken()).called(1);
    });
  });
}
