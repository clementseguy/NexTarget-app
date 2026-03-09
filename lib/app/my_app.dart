import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../navigation/app_router.dart';
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
        print('[MYAPP] onGenerateRoute appelé avec route: ${settings.name}');
        print('[MYAPP] Arguments: ${settings.arguments}');
        
        // Intercepter les deep links OAuth qui sont transformés en routes web par Flutter
        // Le token est déjà géré par le deep link handler dans main.dart
        if (settings.name != null && settings.name!.contains('token=')) {
          print('[MYAPP] Route OAuth détectée, ignorée (déjà gérée par deep link handler)');
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
    print('[AUTH_GATE] 🚪 Vérification de l\'authentification au démarrage...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthStatus();
    print('[AUTH_GATE] État final: isAuthenticated=${authProvider.isAuthenticated}');
  }

  @override
  Widget build(BuildContext context) {
    print('[AUTH_GATE] ========================================');
    print('[AUTH_GATE] 🔄 Rebuild du Consumer<AuthProvider>');
    print('[AUTH_GATE] ========================================');
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        print('[AUTH_GATE] Consumer.builder appelé');
        print('[AUTH_GATE] isLoading=${authProvider.isLoading}, isAuthenticated=${authProvider.isAuthenticated}');
        
        if (authProvider.isLoading) {
          print('[AUTH_GATE] ⏳ Chargement en cours...');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        print('[AUTH_GATE] ✅ Navigation vers l\'application (authentification optionnelle)');
        return AppNavigator();
      },
    );
  }
}