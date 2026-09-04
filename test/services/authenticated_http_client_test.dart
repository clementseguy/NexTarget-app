import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';
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

    http.StreamedResponse streamed(int status, {String body = ''}) {
      return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
    }

    test('ajoute le header Authorization avec le token valide', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'access_1');
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(200));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));
      await authenticatedClient.send(request);

      final sent = verify(mockInnerClient.send(captureAny)).captured.single
          as http.Request;
      expect(sent.headers['Authorization'], 'Bearer access_1');
      // La requête envoyée n'est jamais l'objet original (déjà finalisé).
      expect(identical(sent, request), isFalse);
    });

    test('conserve le corps JSON de la requête d\'origine', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'access_1');
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(200));

      final request =
          http.Request('POST', Uri.parse('https://api.test.com/data'))
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({'foo': 'bar'});
      await authenticatedClient.send(request);

      final sent = verify(mockInnerClient.send(captureAny)).captured.single
          as http.Request;
      expect(sent.body, jsonEncode({'foo': 'bar'}));
      expect(sent.headers['Content-Type'], contains('application/json'));
    });

    test('requête GET sans corps fonctionne (bodyBytes vide)', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'access_1');
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(200));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));
      final response = await authenticatedClient.send(request);

      expect(response.statusCode, 200);
      final sent = verify(mockInnerClient.send(captureAny)).captured.single
          as http.Request;
      expect(sent.bodyBytes, isEmpty);
    });

    test('rejoue une seule fois après un 401 avec le nouveau token', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'stale');
      when(mockAuthService.forceRefreshAfterUnauthorized())
          .thenAnswer((_) async => 'fresh');

      var callCount = 0;
      when(mockInnerClient.send(any)).thenAnswer((_) async {
        callCount++;
        return callCount == 1 ? streamed(401) : streamed(200, body: 'ok');
      });

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));
      final response = await authenticatedClient.send(request);

      expect(response.statusCode, 200);
      expect(callCount, 2);
      verify(mockAuthService.forceRefreshAfterUnauthorized()).called(1);

      final captured = verify(mockInnerClient.send(captureAny)).captured;
      expect((captured[0] as http.Request).headers['Authorization'],
          'Bearer stale');
      expect((captured[1] as http.Request).headers['Authorization'],
          'Bearer fresh');
    });

    test('ne boucle pas si la requête rejouée est encore 401', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'stale');
      when(mockAuthService.forceRefreshAfterUnauthorized())
          .thenAnswer((_) async => 'fresh-but-still-rejected');
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(401));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));
      final response = await authenticatedClient.send(request);

      expect(response.statusCode, 401);
      // Exactement une tentative initiale + un rejeu, jamais plus.
      verify(mockInnerClient.send(any)).called(2);
      verify(mockAuthService.forceRefreshAfterUnauthorized()).called(1);
    });

    test(
        'panne réseau pendant le renouvellement réactif : propage l\'exception sans requalifier en 401',
        () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'stale');
      when(mockAuthService.forceRefreshAfterUnauthorized())
          .thenThrow(NetworkUnavailableException('offline'));
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(401));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));

      await expectLater(
        authenticatedClient.send(request),
        throwsA(isA<NetworkUnavailableException>()),
      );
      // Aucun rejeu : un seul envoi réseau, jamais de boucle.
      verify(mockInnerClient.send(any)).called(1);
    });

    test(
        'session expirée dès le renouvellement proactif : aucune requête envoyée',
        () async {
      when(mockAuthService.getValidAccessToken())
          .thenThrow(SessionExpiredException('reconnexion requise'));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));

      await expectLater(
        authenticatedClient.send(request),
        throwsA(isA<SessionExpiredException>()),
      );
      verifyNever(mockInnerClient.send(any));
    });

    test(
        'panne réseau dès le renouvellement proactif : propage sans envoyer la requête',
        () async {
      when(mockAuthService.getValidAccessToken())
          .thenThrow(NetworkUnavailableException('offline'));

      final request =
          http.Request('GET', Uri.parse('https://api.test.com/data'));

      await expectLater(
        authenticatedClient.send(request),
        throwsA(isA<NetworkUnavailableException>()),
      );
      verifyNever(mockInnerClient.send(any));
    });

    test('rejoue correctement un corps initialement streamé', () async {
      when(mockAuthService.getValidAccessToken())
          .thenAnswer((_) async => 'access_1');
      when(mockInnerClient.send(any)).thenAnswer((_) async => streamed(200));

      final request =
          http.StreamedRequest('POST', Uri.parse('https://api.test.com/data'));
      request.headers['Content-Type'] = 'application/json';
      request.sink.add(utf8.encode('{"streamed":true}'));
      request.sink.close();

      final response = await authenticatedClient.send(request);

      expect(response.statusCode, 200);
      final sent = verify(mockInnerClient.send(captureAny)).captured.single
          as http.Request;
      expect(sent.body, '{"streamed":true}');
      expect(identical(sent, request), isFalse);
    });
  });
}
