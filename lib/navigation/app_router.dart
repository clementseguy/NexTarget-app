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
import '../screens/guided_session_preparation_screen.dart';
import '../screens/guided_session_screen.dart';
import '../screens/goal_edit_screen.dart';
import '../screens/exercises_list_screen.dart';
import '../screens/login_screen.dart';
import '../providers/navigation_provider.dart';
import '../constants/session_constants.dart';
import '../data/local_db_hive.dart';
import '../models/goal.dart';
import '../widgets/help_button.dart';
import '../widgets/app_bar_title.dart';
import '../models/shooting_session.dart';
import '../services/session_service.dart';

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
            'Au stand démarre une séance détaillée guidée ou reprend un brouillon existant.',
            'Autres créations donne accès aux sessions planifiées, réalisées détaillées et libres.',
            'Une séance en cours reste enregistrée hors statistiques et Coach jusqu’à sa clôture.',
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
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: _SessionCreationActions(
            historyKey: _historyKey,
          ),
        ),
      ],
    );
  }
}

class _SessionCreationActions extends StatefulWidget {
  final GlobalKey<SessionsHistoryScreenState> historyKey;

  const _SessionCreationActions({required this.historyKey});

  @override
  State<_SessionCreationActions> createState() =>
      _SessionCreationActionsState();
}

class _SessionCreationActionsState extends State<_SessionCreationActions> {
  final SessionService _sessionService = SessionService();
  late Future<List<DetailedShootingSession>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _draftsFuture = _sessionService.getGuidedDrafts();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    if (!mounted) return;
    setState(_reload);
    widget.historyKey.currentState?.refreshSessions();
  }

  Future<void> _primaryAction() async {
    final drafts = await _sessionService.getGuidedDrafts();
    if (!mounted) return;
    if (drafts.isEmpty) {
      await _open(
        GuidedSessionPreparationScreen(sessionService: _sessionService),
      );
      return;
    }
    DetailedShootingSession? selected;
    if (drafts.length == 1) {
      selected = drafts.single;
    } else {
      selected = await showModalBottomSheet<DetailedShootingSession>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Reprendre une séance')),
              ...drafts.map(
                (draft) => ListTile(
                  leading: const Icon(Icons.sports_score),
                  title: Text('${draft.weapon} · ${draft.caliber}'),
                  subtitle: Text(
                    '${draft.completedSeriesCount} / ${draft.series.length} séries',
                  ),
                  onTap: () => Navigator.pop(sheetContext, draft),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (selected != null) {
      await _open(
        GuidedSessionScreen(
          draft: selected,
          sessionService: _sessionService,
        ),
      );
    }
  }

  Future<void> _showOtherCreations(bool hasDraft) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(title: Text('Autres créations')),
            if (hasDraft)
              ListTile(
                leading: const Icon(Icons.sports_score),
                title: const Text('Nouvelle séance au stand'),
                onTap: () => Navigator.pop(sheetContext, 'guided'),
              ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Session planifiée'),
              onTap: () => Navigator.pop(sheetContext, 'planned'),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Session réalisée détaillée'),
              onTap: () => Navigator.pop(sheetContext, 'detailed'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Session libre'),
              onTap: () => Navigator.pop(sheetContext, 'simple'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'guided':
        await _open(
          GuidedSessionPreparationScreen(sessionService: _sessionService),
        );
        return;
      case 'planned':
        await _open(
          CreateSessionScreen(
              initialSessionData: AppNavigator.plannedSessionTemplate()),
        );
        return;
      case 'detailed':
        await _open(const CreateSessionScreen());
        return;
      case 'simple':
        await _open(const CreateSimpleSessionScreen());
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DetailedShootingSession>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        final drafts = snapshot.data ?? const <DetailedShootingSession>[];
        final hasDraft = drafts.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: 'Autres créations de session',
              child: FloatingActionButton.small(
                heroTag: 'fab_other_session_creations',
                tooltip: 'Autres créations',
                onPressed: () => _showOtherCreations(hasDraft),
                child: const Icon(Icons.add),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: hasDraft
                  ? 'Reprendre une séance au stand'
                  : 'Commencer une séance au stand',
              child: FloatingActionButton.extended(
                heroTag: 'fab_guided_session',
                tooltip: hasDraft ? 'Reprendre la séance' : 'Au stand',
                onPressed: snapshot.connectionState == ConnectionState.waiting
                    ? null
                    : _primaryAction,
                icon: Icon(hasDraft ? Icons.play_arrow : Icons.sports_score),
                label: Text(hasDraft ? 'Reprendre' : 'Au stand'),
              ),
            ),
          ],
        );
      },
    );
  }
}
