import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/models/coach_session_analysis.dart';
import 'package:tir_sportif/models/exercise.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/providers/navigation_provider.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/screens/session_detail/session_detail_components.dart';
import 'package:tir_sportif/services/auth_service.dart';
import 'package:tir_sportif/services/auth_session_exceptions.dart';
import 'package:tir_sportif/services/network_error.dart';
import 'package:tir_sportif/services/server_coach_analysis_service.dart';

/// NT-061 — coach « connecté uniquement » : la section Débrief du Coach doit
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

class _CapturingAnalysisService extends ServerCoachAnalysisService {
  String? capturedExperienceLevel;

  _CapturingAnalysisService()
      : super(
          baseUrl: 'http://unused',
          authService: AuthService(authBaseUrl: 'http://unused'),
        );

  @override
  Future<CoachSessionAnalysis> analyzeSession(
    DetailedShootingSession session, {
    required bool coachDataSharingAllowed,
    Exercise? exercise,
    String? experienceLevel,
    String promptVariant = 'coach_neutre',
  }) async {
    capturedExperienceLevel = experienceLevel;
    throw StateError('Arrêt après capture');
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

CoachSessionAnalysis _analysis() => CoachSessionAnalysis(
      analysisId: 'analysis-1',
      sessionId: 'session-1',
      debrief: 'Débrief existant',
      successes: const ['Réussite'],
      attentionPoint: 'Attention',
      limitations: const [],
      exerciseEvaluation: null,
      nextAction: null,
      model: 'test',
      generatedAt: DateTime(2026, 9, 12),
    );

class _NavigationHarness extends StatelessWidget {
  const _NavigationHarness();

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigation, _) => Scaffold(
        body: Center(
          child: Text(
            navigation.currentIndex == 4 ? 'Paramètres racine' : 'Autre onglet',
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: navigation.currentIndex,
          onTap: navigation.changeIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Coach'),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Exercices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Synthèse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.track_changes),
              label: 'Sessions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Paramètres',
            ),
          ],
        ),
      ),
    );
  }
}

Widget _wrap(
  Widget child, {
  required bool authenticated,
  _FakeAuthProvider? authProvider,
  NavigationProvider? navigationProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<NavigationProvider>.value(
        value: navigationProvider ?? NavigationProvider(),
      ),
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
    await Hive.box('app_preferences').put(
      'coach_data_sharing_allowed',
      true,
    );
  });

  testWidgets(
      'consentement refusé : message de partage et aucune action d’analyse',
      (tester) async {
    await Hive.box('app_preferences').put(
      'coach_data_sharing_allowed',
      false,
    );
    var calls = 0;
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        onAnalyseUpdated: () {},
        analysisLoader: () async {
          calls++;
          throw StateError('Analyse interdite');
        },
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Le partage de vos données est requis pour que le Coach puisse les analyser.',
      ),
      findsOneWidget,
    );
    expect(find.text('Paramètres Coach'), findsOneWidget);
    expect(find.text('Lancer analyse'), findsNothing);
    expect(calls, 0);
  });

  testWidgets(
      'Paramètres Coach sélectionne l’onglet principal avec sa navigation',
      (tester) async {
    await Hive.box('app_preferences').put(
      'coach_data_sharing_allowed',
      false,
    );
    final navigationProvider = NavigationProvider()..goToSessions();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NavigationProvider>.value(
            value: navigationProvider,
          ),
          ChangeNotifierProvider<AuthProvider>.value(
            value: _FakeAuthProvider(true),
          ),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(
              preferencesBox: Hive.box('app_preferences'),
            ),
          ),
        ],
        child: const MaterialApp(home: _NavigationHarness()),
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SessionCoachAnalysisSection(
            session: _session(),
            onAnalyseUpdated: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paramètres Coach'));
    await tester.pumpAndSettle();

    expect(navigationProvider.currentIndex, 4);
    expect(find.text('Paramètres racine'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets(
      'non authentifié : message clair + bouton Se connecter, pas de bouton analyse',
      (tester) async {
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        onAnalyseUpdated: () {},
      ),
      authenticated: false,
    ));

    // La section est repliée par défaut (pas d'analyse) : on l'ouvre.
    await tester.tap(find.text('Débrief du Coach'));
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
        onAnalyseUpdated: () {},
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Lancer analyse'), findsOneWidget);
    expect(
        find.textContaining('Le coach IA nécessite un compte'), findsNothing);
    expect(find.text('Se connecter'), findsNothing);
  });

  testWidgets('une analyse existante peut être régénérée', (tester) async {
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analysis: _analysis(),
        onAnalyseUpdated: () {},
      ),
      authenticated: true,
    ));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Re-générer'),
        matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('vérification active : aucun bouton de connexion ou d’analyse',
      (tester) async {
    final authProvider = _FakeAuthProvider.verifying();
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        onAnalyseUpdated: () {},
      ),
      authenticated: false,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Débrief du Coach'));
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
    // la section Débrief du Coach ne doit exposer aucun chip Neutre/Cool.
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        onAnalyseUpdated: () {},
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Lancer analyse'), findsOneWidget);
    expect(find.text('Neutre'), findsNothing);
    expect(find.text('Cool'), findsNothing);
  });

  testWidgets('transmet à l’analyse le niveau de la préférence locale',
      (tester) async {
    await Hive.box('app_preferences').put(
      'coach_experience_level',
      'advanced',
    );
    final service = _CapturingAnalysisService();
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        onAnalyseUpdated: () {},
        analysisService: service,
      ),
      authenticated: true,
    ));

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer analyse'));
    await tester.pump();

    expect(service.capturedExperienceLevel, 'advanced');
  });

  testWidgets('erreur transitoire : Réessayer relance uniquement l’analyse',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
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

    await tester.tap(find.text('Débrief du Coach'));
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
        onAnalyseUpdated: () {},
        analysisLoader: () async =>
            throw SessionExpiredException('refresh révoqué'),
      ),
      authenticated: true,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Débrief du Coach'));
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
        onAnalyseUpdated: () {},
        analysisLoader: () async {
          authProvider.markUnauthenticated();
          throw SessionExpiredException('déjà invalidée');
        },
      ),
      authenticated: true,
      authProvider: authProvider,
    ));

    await tester.tap(find.text('Débrief du Coach'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lancer analyse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authProvider.invalidationCalls, 0);
    expect(find.text('Se reconnecter'), findsOneWidget);
  });
}
