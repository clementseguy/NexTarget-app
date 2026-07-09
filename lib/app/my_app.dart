import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../navigation/app_router.dart';
import '../screens/onboarding_screen.dart';
import '../services/logger.dart';
import '../widgets/fade_in_wrapper.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'NexTarget',
      theme: AppTheme.forType(settingsProvider.themeType),
      home: FadeInWrapper(
        duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
        child: const _AuthGate(),
      ),
      onGenerateRoute: (settings) {
        // Intercepter les deep links OAuth qui sont transformés en routes web par Flutter
        // Le token est déjà géré par le deep link handler dans main.dart
        if (settings.name != null && settings.name!.contains('token=')) {
          AppLogger.I.debug('Route OAuth détectée, ignorée (déjà gérée par deep link handler)');
          // Retourner null pour ignorer cette tentative de navigation
          // L'AuthGate gérera la navigation après authentification réussie
          return null;
        }
        
        return AppRouter.generateRoute(settings);
      },
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
    AppLogger.I.debug('AuthGate: isAuthenticated=${authProvider.isAuthenticated}');
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

        // Onboarding au premier lancement (NT-075), puis navigation normale.
        return OnboardingGate(child: AppNavigator());
      },
    );
  }
}