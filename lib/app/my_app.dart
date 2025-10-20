import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../navigation/app_router.dart';
import '../widgets/fade_in_wrapper.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexTarget',
      theme: AppTheme.darkTheme,
      home: FadeInWrapper(
        duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
        child: const _AuthGate(),
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.home,
    );
  }
}

/// Widget qui verifie l'authentification au demarrage
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Appeler checkAuth après le build pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final authEnabled = AppConfig.I.authEnabled;
        
        if (authEnabled && !authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        return AppNavigator();
      },
    );
  }
}