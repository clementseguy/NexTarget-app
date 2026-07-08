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

/// NT-061 — coach « connecté uniquement » : la section Analyse Coach doit
/// exiger un utilisateur authentifié (message clair + CTA login sinon).
/// NT-032 — le ton du coach (neutre/cool) est sélectionnable via chips.
class _FakeAuthProvider extends AuthProvider {
  final bool _authenticated;
  _FakeAuthProvider(this._authenticated)
      : super(AuthService(authBaseUrl: 'http://unused'));

  @override
  bool get isAuthenticated => _authenticated;
}

ShootingSession _session() => ShootingSession(
      weapon: 'Glock 17',
      caliber: '9mm',
      series: [
        Series(shotCount: 5, distance: 25, points: 45, groupSize: 8.5, comment: 'stable'),
      ],
    );

Widget _wrap(Widget child, {required bool authenticated}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: _FakeAuthProvider(authenticated)),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(preferencesBox: Hive.box('app_preferences')),
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
  testWidgets('non authentifié : message clair + bouton Se connecter, pas de bouton analyse', (tester) async {
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

  testWidgets('authentifié : bouton Lancer analyse visible, pas de message login', (tester) async {
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
    expect(find.textContaining('Le coach IA nécessite un compte'), findsNothing);
    expect(find.text('Se connecter'), findsNothing);
  });

  testWidgets('authentifié : chips de persona visibles, sélection persistée (NT-032)', (tester) async {
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

    expect(find.text('Neutre'), findsOneWidget);
    expect(find.text('Cool'), findsOneWidget);

    await tester.tap(find.text('Cool'));
    await tester.pumpAndSettle();

    expect(Hive.box('app_preferences').get('coach_persona'), 'coach_cool');
  });

  testWidgets('non authentifié : pas de chips de persona', (tester) async {
    await tester.pumpWidget(_wrap(
      SessionCoachAnalysisSection(
        session: _session(),
        analyse: null,
        onAnalyseUpdated: () {},
      ),
      authenticated: false,
    ));

    await tester.tap(find.text('Analyse Coach'));
    await tester.pumpAndSettle();

    expect(find.text('Neutre'), findsNothing);
    expect(find.text('Cool'), findsNothing);
  });
}
