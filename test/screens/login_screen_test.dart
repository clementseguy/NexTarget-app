import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/providers/auth_provider.dart';
import 'package:tir_sportif/screens/login_screen.dart';
import 'package:tir_sportif/services/auth_service.dart';

class _FailingAuthService extends AuthService {
  _FailingAuthService() : super(authBaseUrl: 'http://unused');

  @override
  Future<void> signInWithGoogle() async {
    throw Exception('timeout de test');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppConfig.load);

  testWidgets(
    'affiche une erreur sans exception non geree si le lancement OAuth echoue',
    (tester) async {
      final provider = AuthProvider(_FailingAuthService());

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: provider,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Se connecter avec Google'));
      await tester.pump();

      expect(find.textContaining('timeout de test'), findsOneWidget);
      expect(provider.isLoading, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
