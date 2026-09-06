import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/screens/login_screen.dart';
import 'package:tir_sportif/services/auth_service.dart';

class _FailingAuthService extends AuthService {
  _FailingAuthService() : super(authBaseUrl: 'http://unused');

  int calls = 0;

  @override
  Future<void> signInWithGoogle() async {
    calls++;
    throw TimeoutException('détail technique de test');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppConfig.load);

  testWidgets(
    'affiche une erreur sans exception non geree si le lancement OAuth echoue',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = _FailingAuthService();
      final provider = AuthProvider(service);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Se connecter avec Google'));
      await tester.pump();

      expect(find.text('Le service met trop de temps à répondre.'),
          findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.textContaining('technique'), findsNothing);
      expect(provider.isLoading, isFalse);
      expect(tester.takeException(), isNull);

      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      expect(service.calls, 2);
    },
  );
}
