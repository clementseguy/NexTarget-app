import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/screens/session_detail/session_detail_components.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';
import 'package:tir_sportif/services/network_error.dart';

/// NT-061 — coach « connecté uniquement » : la section Analyse Coach doit
/// exiger un utilisateur authentifié (message clair + CTA login sinon).
/// NT-032 — le ton du coach se choisit dans Paramètres uniquement (retour
/// de recette S2) : aucun sélecteur dans la section.
class _FakeAuthProvider extends AuthProvider {
  bool _authenticated;
  AuthStatus _status;
  bool _loading;
  var invalidationCalls = 0;

  _FakeAuthProvider(this._authenticated)
      : _status = _authenticated
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        _loading = false,
        super(AuthService(authBaseUrl: 'http://unused'));

  _FakeAuthProvider.verifying()
      : _authenticated = false,
        _status = AuthStatus.verifying,
        _loading = true,
        super(AuthService(authBaseUrl: 'http://unused'));

  @override
  bool get isAuthenticated => _authenticated;

  @override
  AuthStatus get status => _status;

  @override
  bool get isVerificationPending => _status == AuthStatus.verifying;

  @override
  bool get isLoading => _loading;

  void markUnauthenticated() {
    _authenticated = false;
    _status = AuthStatus.unauthenticated;
    _loading = false;
  }

  @override
  Future<void> handleConfirmedInvalidation() async {
    invalidationCalls++;
    markUnauthenticated();
  }
}

DetailedShootingSession _session() => DetailedShootingSession(
      weapon: 'Glock 17',
      caliber: '9mm',
      series: [
        Series(
            shotCount: 5,
            distance: 25,
            points: 45,
            groupSize: 8.5,
            comment: 'stable'),
      ],
    );

Widget _wrap(
  Widget child, {
  required bool authenticated,
  _FakeAuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider ?? _FakeAuthProvider(authenticated)),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) =>
            SettingsProvider(preferencesBox: Hive.box('app_preferences')),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() async {
    // Box 100 % en mémoire (bytes:) : aucune écriture disque, donc aucun
    // deadlock entre la zone fake-async de testWidgets et la file
    // d'écriture Hive.
    Hive.init(Directory.systemTemp.createTempSync('nt_hive_test_').path);
    await Hive.openBox('app_preferences', bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box('app_preferences').delete('coach_persona');
  });
  testWidgets(
      'non authentifié : message clair + bouton Se connecter, pas de bouton analyse',
      (tester) async {
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
      ),
      authenticated: false,
    ));

    // La section est repliée par défaut (pas d'analyse) : on l'ouvre.
    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Le coach IA nécessite un compte'),
      findsOneWidget,
    );
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Lancer analyse'), findsNothing);
  });

  testWidgets(
      'authentifié : bouton Lancer analyse visible, pas de message login',
      (tester) async {
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Lancer analyse'), findsOneWidget);
    expect(
        find.textContaining('Le coach IA nécessite un compte'), findsNothing);
    expect(find.text('Se connecter'), findsNothing);
  });

  testWidgets('vérification active : aucun bouton de connexion ou d’analyse',
      (tester) async {
    final authProvider = _FakeAuthProvider.verifying();
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
      ),
      authenticated: false,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Connexion à vérifier'), findsOneWidget);
    expect(find.text('Se connecter'), findsNothing);
    expect(find.text('Lancer analyse'), findsNothing);
    final retryButton = find.ancestor(
      of: find.text('Réessayer'),
      matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
    );
    expect(
      tester.widget<OutlinedButton>(retryButton).onPressed,
      isNull,
    );
  });

  testWidgets(
      'pas de sélecteur de persona dans la session (retour recette NT-032)',
      (tester) async {
    // Le ton du coach se choisit uniquement dans Paramètres > Coach IA ;
    // la section Analyse Coach ne doit exposer aucun chip Neutre/Cool.
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Lancer analyse'), findsOneWidget);
    expect(find.text('Neutre'), findsNothing);
    expect(find.text('Cool'), findsNothing);
  });

  testWidgets('erreur transitoire : Réessayer relance uniquement l’analyse',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
        analysisLoader: () async {
          calls++;
          throw NetworkOperationException(
            NetworkErrorFamily.serviceUnavailable,
            'HTTP 503 interne',
          );
        },
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer analyse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Le service est temporairement indisponible.'),
        findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(find.textContaining('503'), findsNothing);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 2);
  });

  testWidgets('session invalidée : propose uniquement Se reconnecter',
      (tester) async {
    final authProvider = _FakeAuthProvider(true);
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
        analysisLoader: () async =>
            throw SessionExpiredException('refresh révoqué'),
      ),
      authenticated: true,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer analyse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Se reconnecter'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(find.textContaining('refresh'), findsNothing);
    expect(authProvider.invalidationCalls, 1);
  });

  testWidgets('un 401 déjà propagé globalement n’invalide pas deux fois',
      (tester) async {
    final authProvider = _FakeAuthProvider(true);
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
        analysisLoader: () async {
          authProvider.markUnauthenticated();
          throw SessionExpiredException('déjà invalidée');
        },
      ),
      authenticated: true,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer analyse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authProvider.invalidationCalls, 0);
    expect(find.text('Se reconnecter'), findsOneWidget);
  });
}
