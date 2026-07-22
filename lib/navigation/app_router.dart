import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/coach_screen.dart';
import '../screens/exercices_screen.dart';
import '../screens/home_screen.dart';
import '../screens/sessions_history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/create_session_screen.dart';
import '../screens/goal_edit_screen.dart';
import '../screens/exercises_list_screen.dart';
import '../screens/login_screen.dart';
import '../providers/navigation_provider.dart';
import '../constants/session_constants.dart';
import '../data/local_db_hive.dart';
import '../models/goal.dart';
import '../models/session_setup_template.dart';
import '../services/session_template_service.dart';
import '../widgets/help_button.dart';

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
                icon: Icon(Icons.bar_chart), label: 'Tableau de bord'),
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
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes, color: Colors.amber),
          SizedBox(width: 10),
          Text('Mes sessions'),
        ],
      ),
      actions: [
        const HelpButton(
          title: 'Mes sessions',
          points: [
            'Le bouton + crée une session du même type que l\'onglet affiché : réalisée ou prévue.',
            'Chaque session contient vos séries : coups, distance, points, groupement, prise.',
            'Ouvrez une session réalisée pour la synthèse, les exercices travaillés et l\'analyse du coach IA.',
            'Un appui long sur une carte permet de la supprimer.',
          ],
        ),
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
          'caliber': _lastCaliberForPlannedTemplate(),
          'status': SessionConstants.statusPrevue,
          'category': SessionConstants.categoryEntrainement,
          'series': [],
          'exercises': [],
        },
        'series': [],
      };

  static String _lastCaliberForPlannedTemplate() {
    try {
      final service = SessionTemplateService();
      final emptyData = service.emptyInitialData(planned: true);
      final session = emptyData['session'] as Map<String, dynamic>;
      return service.getLastSetup()?.caliber ?? session['caliber'] as String;
    } catch (_) {
      return '.22 LR';
    }
  }

  Future<void> _openCreateSession(
    BuildContext context, {
    required bool planned,
    required _SessionCreateChoice choice,
  }) async {
    final status = planned
        ? SessionConstants.statusPrevue
        : SessionConstants.statusRealisee;
    final initialData = choice.setup?.toInitialSessionData(status: status) ??
        (planned
            ? SessionTemplateService().emptyInitialData(planned: true)
            : null);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CreateSessionScreen(initialSessionData: initialData),
      ),
    );
    _historyKey.currentState?.refreshSessions();
  }

  Future<void> _showQuickCreateSheet(BuildContext context) async {
    final planned = _historyKey.currentState?.currentFilter == 'planned';
    final templateService = SessionTemplateService();
    final lastSetup = templateService.getLastSetup();
    final favorites = templateService.getFavorites();
    final choice = await showModalBottomSheet<_SessionCreateChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (lastSetup != null)
                _SetupChoiceTile(
                  icon: Icons.history,
                  title: 'Dernier setup',
                  setup: lastSetup,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _SessionCreateChoice(setup: lastSetup),
                  ),
                ),
              for (final favorite in favorites)
                _SetupChoiceTile(
                  icon: Icons.star,
                  title: favorite.name,
                  setup: favorite,
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _SessionCreateChoice(setup: favorite),
                  ),
                ),
              if (lastSetup != null || favorites.isNotEmpty) const Divider(),
              ListTile(
                leading: const Icon(Icons.note_add_outlined),
                title: const Text('Vide'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  const _SessionCreateChoice.empty(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;
    await _openCreateSession(context, planned: planned, choice: choice);
  }

  Widget _buildSessionsPage(BuildContext context) {
    return Stack(
      children: [
        SessionsHistoryScreen(key: _historyKey),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            heroTag: 'fab_create_session',
            onPressed: () => _showQuickCreateSheet(context),
            tooltip: 'Créer une session',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _SessionCreateChoice {
  final SessionSetupTemplate? setup;

  const _SessionCreateChoice({required this.setup});
  const _SessionCreateChoice.empty() : setup = null;
}

class _SetupChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final SessionSetupTemplate setup;
  final VoidCallback onTap;

  const _SetupChoiceTile({
    required this.icon,
    required this.title,
    required this.setup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: setup.summary.isEmpty ? null : Text(setup.summary),
      onTap: onTap,
    );
  }
}
