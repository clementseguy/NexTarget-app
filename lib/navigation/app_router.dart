import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/coach_screen.dart';
import '../screens/exercices_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sessions_history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_session_screen.dart';
import '../screens/create_simple_session_screen.dart';
import '../screens/goal_edit_screen.dart';
import '../screens/exercises_list_screen.dart';
import '../screens/login_screen.dart';
import '../providers/navigation_provider.dart';
import '../constants/session_constants.dart';
import '../data/local_db_hive.dart';
import '../models/goal.dart';
import '../widgets/help_button.dart';
import '../widgets/app_bar_title.dart';

/// Classe responsable de la gestion des routes nommées de l'application
class AppRouter {
  static const String home = '/';
  static const String coach = '/coach';
  static const String exercises = '/exercises';
  static const String sessions = '/sessions';
  static const String settings = '/settings';
  static const String createSession = '/sessions/create';
  static const String editGoal = '/goals/edit';
  static const String exercisesList = '/exercises/list';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  /// Retourne la route correspondant au nom spécifié
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final name = settings.name;

    // Gestion spéciale pour le callback OAuth (contient #access_token=...)
    // Flutter intercepte parfois cette URL après le retour de flutter_web_auth_2
    if (name != null && name.startsWith('/#access_token')) {
      // Redirige vers le dashboard (l'auth est déjà traitée par flutter_web_auth_2)
      return MaterialPageRoute(builder: (_) => AppNavigator());
    }

    if (name == home || name == dashboard) {
      return MaterialPageRoute(builder: (_) => AppNavigator());
    } else if (name == login) {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    } else if (name == coach) {
      return MaterialPageRoute(builder: (_) => CoachScreen());
    } else if (name == exercises) {
      return MaterialPageRoute(builder: (_) => ExercicesScreen());
    } else if (name == sessions) {
      return MaterialPageRoute(builder: (_) => SessionsHistoryScreen());
    } else if (name == AppRouter.settings) {
      // NB: le paramètre `RouteSettings settings` masque la constante de
      // route ; sans le préfixe, la comparaison String == RouteSettings
      // était toujours fausse et la route /settings ne résolvait jamais.
      return MaterialPageRoute(builder: (_) => SettingsScreen());
    } else if (name == createSession) {
      final args = settings.arguments as Map<String, dynamic>?;
      return MaterialPageRoute(
        builder: (_) => CreateSessionScreen(
          initialSessionData: args,
        ),
      );
    } else if (name == editGoal) {
      final args = settings.arguments as Map<String, dynamic>?;
      Goal? goalToEdit;
      if (args != null && args.containsKey('goal')) {
        goalToEdit = args['goal'] as Goal?;
      }
      return MaterialPageRoute(
        builder: (_) => GoalEditScreen(
          existing: goalToEdit,
        ),
      );
    } else if (name == exercisesList) {
      return MaterialPageRoute(builder: (_) => ExercisesListScreen());
    } else {
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route inconnue: ${name ?? "non définie"}'),
          ),
        ),
      );
    }
  }
}

/// Widget principal de navigation qui utilise un BottomNavigationBar
/// et un NavigationProvider pour gérer l'état de navigation
class AppNavigator extends StatelessWidget {
  AppNavigator({super.key});

  final GlobalKey<SessionsHistoryScreenState> _historyKey =
      GlobalKey<SessionsHistoryScreenState>();
  final ValueNotifier<String> _sessionsTab = ValueNotifier('realized');

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
        builder: (context, navigationProvider, _) {
      final currentIndex = navigationProvider.currentIndex;
      final Widget body;

      // Page spéciale pour les sessions avec FAB
      if (currentIndex == 3) {
        body = _buildSessionsPage(context);
      } else {
        body = _getPageForIndex(currentIndex);
      }

      return Scaffold(
        appBar: currentIndex == 3 ? _buildSessionsAppBar(context) : null,
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor:
              Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
                  Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context)
                  .bottomNavigationBarTheme
                  .unselectedItemColor ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          currentIndex: currentIndex,
          onTap: (index) => navigationProvider.changeIndex(index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Coach'),
            BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center), label: 'Exercices'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Synthèse'),
            BottomNavigationBarItem(
                icon: Icon(Icons.track_changes), label: 'Sessions'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Paramètres'),
          ],
        ),
      );
    });
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return CoachScreen();
      case 1:
        return ExercicesScreen();
      case 2:
        return HomeScreen();
      case 4:
        return SettingsScreen();
      default:
        return HomeScreen();
    }
  }

  AppBar _buildSessionsAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: const AppBarTitle(
        icon: Icons.track_changes,
        label: 'Sessions',
      ),
      actions: [
        const HelpButton(
          title: 'Mes sessions',
          points: [
            'Le bouton + crée une session du même type que l\'onglet affiché : réalisée ou prévue.',
            'Dans Réalisées, le bouton avec l’icône de saisie rapide crée une session libre sans séries, score ni groupement.',
            'Chaque session contient vos séries : coups, distance, points, groupement, prise.',
            'Ouvrez une session réalisée pour la synthèse, les exercices travaillés et l\'analyse du coach IA.',
            'Un appui long sur une carte permet de la supprimer.',
          ],
        ),
        if (kDebugMode)
          IconButton(
            icon: Icon(Icons.bolt, color: Colors.amber),
            tooltip: 'Ajouter 3 sessions aléatoires',
            onPressed: () async {
              await LocalDatabaseHive()
                  .insertRandomSessions(count: 3, status: 'réalisée');
              _historyKey.currentState?.refreshSessions();
            },
          ),
        IconButton(
          icon: Icon(Icons.refresh),
          tooltip: 'Recharger',
          onPressed: () => _historyKey.currentState?.refreshSessions(),
        ),
      ],
    );
  }

  /// Données initiales pour la création d'une session prévue depuis le +.
  static Map<String, dynamic> plannedSessionTemplate() => {
        'session': {
          'weapon': '',
          'caliber': '',
          'status': SessionConstants.statusPrevue,
          'category': SessionConstants.categoryEntrainement,
          'series': [],
          'exercises': [],
        },
        'series': [],
      };

  Widget _buildSessionsPage(BuildContext context) {
    return Stack(
      children: [
        SessionsHistoryScreen(
          key: _historyKey,
          onTabChanged: (tab) => _sessionsTab.value = tab,
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: Semantics(
            button: true,
            label: 'Créer une session détaillée',
            child: FloatingActionButton(
              heroTag: 'fab_create_session',
              onPressed: () {
                // Le + crée une session du même type que l'onglet affiché :
                // onglet "Prévues" → session prévue, sinon session réalisée
                // (retour de recette S2 ; l'ancien appui long est supprimé).
                final planned =
                    _historyKey.currentState?.currentFilter == 'planned';
                Navigator.of(context)
                    .push(MaterialPageRoute(
                      builder: (ctx) => CreateSessionScreen(
                        initialSessionData:
                            planned ? plannedSessionTemplate() : null,
                      ),
                    ))
                    .then((_) => _historyKey.currentState?.refreshSessions());
              },
              tooltip: 'Créer une session détaillée',
              child: const Icon(Icons.add),
            ),
          ),
        ),
        Positioned(
          bottom: 92,
          right: 24,
          child: ValueListenableBuilder<String>(
            valueListenable: _sessionsTab,
            builder: (context, tab, _) {
              if (tab != 'realized') return const SizedBox.shrink();
              final colors = Theme.of(context).colorScheme;
              return Semantics(
                button: true,
                label: 'Créer une session libre',
                child: FloatingActionButton(
                  heroTag: 'fab_create_simple_session',
                  tooltip: 'Créer une session libre',
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) => const CreateSimpleSessionScreen(),
                      ))
                      .then((_) => _historyKey.currentState?.refreshSessions()),
                  child: const Icon(Icons.playlist_add),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
