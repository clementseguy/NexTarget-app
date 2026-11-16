import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_router.dart';
import '../screens/onboarding_screen.dart';
import '../services/logger.dart';
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
      home: const _AuthGate(),
      onGenerateRoute: (settings) {
        // Intercepter les deep links OAuth qui sont transformés en routes web par Flutter
        // Le token est déjà géré par le deep link handler dans main.dart
        if (settings.name != null && settings.name!.contains('token=')) {
          AppLogger.I.debug(
              'Route OAuth détectée, ignorée (déjà gérée par deep link handler)');
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
    AppLogger.I
        .debug('AuthGate: isAuthenticated=${authProvider.isAuthenticated}');
  }

  @override
  Widget build(BuildContext context) {
    // La vérification d'authentification est facultative pour le carnet local :
    // elle ne remplace jamais l'interface hors ligne par un second chargement.
    return OnboardingGate(child: AppNavigator());
  }
}
