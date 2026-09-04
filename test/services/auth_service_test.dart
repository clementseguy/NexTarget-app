import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tir_sportif/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([http.Client, FlutterSecureStorage])
void main() {
  group('AuthService', () {
    late MockFlutterSecureStorage mockStorage;
    late AuthService authService;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      authService = AuthService(
        authBaseUrl: 'https://test-api.com',
        callbackScheme: 'testapp',
        storage: mockStorage,
      );
    });

    group('getToken', () {
      test('retourne le token stocke', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => 'test_jwt_token');

        final token = await authService.getToken();

        expect(token, 'test_jwt_token');
        verify(mockStorage.read(key: 'jwt_token')).called(1);
      });

      test('retourne null si aucun token', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => null);

        final token = await authService.getToken();

        expect(token, null);
      });
    });

    group('hasToken', () {
      test('retourne true si token existe', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => 'test_token');

        final result = await authService.hasToken();

        expect(result, true);
      });

      test('retourne false si token est null', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => null);

        final result = await authService.hasToken();

        expect(result, false);
      });

      test('retourne false si token est vide', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => '');

        final result = await authService.hasToken();

        expect(result, false);
      });
    });

    group('logout', () {
      test('supprime le token et l\'email', () async {
        when(mockStorage.delete(key: 'jwt_token'))
            .thenAnswer((_) async => {});
        when(mockStorage.delete(key: 'user_email'))
            .thenAnswer((_) async => {});

        await authService.logout();

        verify(mockStorage.delete(key: 'jwt_token')).called(1);
        verify(mockStorage.delete(key: 'user_email')).called(1);
      });
    });

    group('updateProfile', () {
      test('lève une exception si non authentifié (pas de token)', () async {
        when(mockStorage.read(key: 'jwt_token'))
            .thenAnswer((_) async => null);

        expect(
          () => authService.updateProfile(experienceLevel: 'beginner'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Non authentifié'),
          )),
        );
      });
    });
  });
}
