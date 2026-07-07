import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/server_coach_analysis_service.dart';

ShootingSession _session() => ShootingSession(
      weapon: 'Glock 17',
      caliber: '9mm',
      series: [
        Series(shotCount: 5, distance: 25, points: 45, groupSize: 8.5, comment: 'stable'),
      ],
      synthese: 'RAS',
    );

void main() {
  // Note: ServerCoachAnalysisService(client: ...) ignore l'AuthenticatedHttpClient
  // par défaut quand un client de test est injecté (mêmes conventions que
  // CoachAnalysisService), donc AuthService peut rester un stub minimal ici.
  final dummyAuthService = AuthService(authBaseUrl: 'http://unused');

  test('analyzeSession success returns analysis text', () async {
    final client = MockClient((req) async {
      expect(req.url.path, '/coach/analyze-session');
      return http.Response('{"analysis":"OK","model":"m","generated_at":"2026-07-07T10:00:00Z"}', 200);
    });
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    final out = await svc.analyzeSession(_session());
    expect(out, 'OK');
  });

  test('analyzeSession 401 throws session expirée', () async {
    final client = MockClient((req) async => http.Response('{}', 401));
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()), throwsA(predicate((e) => e.toString().contains('Session expirée'))));
  });

  test('analyzeSession 429 throws trop de requêtes', () async {
    final client = MockClient((req) async => http.Response('{}', 429));
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()), throwsA(predicate((e) => e.toString().contains('Trop de requêtes'))));
  });

  test('analyzeSession 5xx throws erreur serveur', () async {
    final client = MockClient((req) async => http.Response('{}', 503));
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()), throwsA(predicate((e) => e.toString().contains('Erreur serveur'))));
  });

  test('analyzeSession malformed content throws réponse vide', () async {
    final client = MockClient((req) async => http.Response('{"analysis":""}', 200));
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()), throwsA(predicate((e) => e.toString().contains('Réponse vide'))));
  });

  test('analyzeSession SocketException produces user-friendly message', () async {
    final client = MockClient((req) async => throw SocketException('Failed host lookup'));
    final svc = ServerCoachAnalysisService(baseUrl: 'http://x', authService: dummyAuthService, client: client);
    expect(() => svc.analyzeSession(_session()), throwsA(predicate((e) => e.toString().contains('Connexion impossible'))));
  });
}
