import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'config/app_config.dart';
import 'models/goal.dart';
import 'migrations/migration.dart';
import 'migrations/migration_2_add_exercises_field.dart';
import 'migrations/migration_3_create_exercises_box.dart';
import 'constants/session_constants.dart';
import 'providers/navigation_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/logger.dart';
import 'app/my_app.dart';

// Global key pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Instance AppLinks pour gérer les deep links
late AppLinks _appLinks;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR');
  await AppConfig.load();
  await Hive.initFlutter();
  
  // Run schema migrations (Hive structural adjustments) before opening boxes / using data.
  final schemaStore = SchemaVersionStore();
  final runner = MigrationRunner([
    Migration2AddExercisesField(), // v2
    Migration3CreateExercisesBox(), // v3
  ], schemaStore);
  await runner.run();
  
  // Register adapters for goals
  if (!Hive.isAdapterRegistered(40)) Hive.registerAdapter(GoalMetricAdapter());
  if (!Hive.isAdapterRegistered(41)) Hive.registerAdapter(GoalComparatorAdapter());
  if (!Hive.isAdapterRegistered(42)) Hive.registerAdapter(GoalStatusAdapter());
  if (!Hive.isAdapterRegistered(43)) Hive.registerAdapter(GoalPeriodAdapter());
  if (!Hive.isAdapterRegistered(44)) Hive.registerAdapter(GoalAdapter());

  await Hive.openBox(SessionConstants.hiveBoxSessions);
  if (!Hive.isBoxOpen('app_preferences')) {
    await Hive.openBox('app_preferences');
  }

  // Initialiser AuthService
  final authService = AuthService(
    authBaseUrl: AppConfig.I.authBaseUrl,
    callbackScheme: AppConfig.I.authCallbackScheme,
  );

  // Lancer l'application avec les providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );

  // Initialiser le deep link handler après le démarrage de l'app
  _initDeepLinks();
}

/// Initialise l'écoute des deep links OAuth
void _initDeepLinks() {
  _appLinks = AppLinks();

  // Écouter les nouveaux deep links pendant que l'app tourne
  _appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  }, onError: (err) {
    AppLogger.I.error('AUTH: erreur deep link', err);
  });

  // Note: On ne vérifie PAS le deep link initial pour éviter de rejouer
  // d'anciens callbacks au redémarrage de l'app.
  // Les deep links OAuth ne sont traités que quand ils arrivent pendant
  // que l'app est en cours d'exécution.
}

/// Traite un deep link OAuth
/// Supporte :
/// - nextarget://callback?token=XYZ (scheme custom)
/// - https://nextarget-server.onrender.com/?token=XYZ (URL web)
void _handleDeepLink(Uri uri) {
  bool isOAuthCallback = false;
  
  // Vérifier si c'est un callback OAuth (scheme custom)
  if (uri.scheme == AppConfig.I.authCallbackScheme && uri.host == 'callback') {
    isOAuthCallback = true;
  }
  // Vérifier si c'est un callback OAuth (URL web du backend avec token)
  else if (uri.scheme == 'https' && 
           uri.host == 'nextarget-server.onrender.com' && 
           uri.queryParameters.containsKey('token')) {
    isOAuthCallback = true;
  }

  if (isOAuthCallback) {
    // Récupérer l'AuthProvider depuis le contexte
    final context = navigatorKey.currentContext;
    if (context != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Ne traiter le callback que si on est en train de se connecter
      // (évite de rejouer un ancien deep link au démarrage)
      if (authProvider.isLoading || !authProvider.isAuthenticated) {
        // Traiter le callback
        authProvider.handleAuthCallback(uri).then((_) {
          // Navigation forcée vers l'écran d'accueil après authentification
          if (authProvider.isAuthenticated) {
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
          }
        }).catchError((e) {
          AppLogger.I.error('AUTH: erreur lors du traitement du callback OAuth', e);
        });
      }
    } else {
      AppLogger.I.error('AUTH: contexte de navigation non disponible pour OAuth');
    }
  }
}
