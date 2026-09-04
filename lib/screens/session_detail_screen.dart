import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../constants/session_constants.dart';
import 'create_session_screen.dart';
import 'create_simple_session_screen.dart';
import '../models/shooting_session.dart';
import '../models/series.dart';
import '../widgets/series_list.dart';
import '../services/exercise_service.dart';
import '../models/exercise.dart';
import 'wizard/planned_session_wizard.dart';
import 'session_detail/session_detail_components.dart';

class SessionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  const SessionDetailScreen({super.key, required this.sessionData});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final SessionService _sessionService = SessionService();
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _allExercises = [];

  Map<String, dynamic>? _currentSessionData;

  @override
  void initState() {
    super.initState();
    _currentSessionData = widget.sessionData;
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await _exerciseService.listAll();
      if (mounted) setState(() => _allExercises = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSessionData == null ||
        _currentSessionData!['session'] == null ||
        _currentSessionData!['series'] == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Détail de la session')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final session = ShootingSession.fromMap(_currentSessionData!['session']);
    final series = (_currentSessionData!['series'] as List<dynamic>)
        .map((s) => Series.fromMap(Map<String, dynamic>.from(s)))
        .toList();
    final isRealisee = session.status == SessionConstants.statusRealisee;
    final bool isPlanned = session.status == SessionConstants.statusPrevue;
    String? analyse = _currentSessionData!['session']['analyse'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
            session is SimpleShootingSession ? 'Session libre' : 'Session'),
        actions: [
          if (isPlanned && session is DetailedShootingSession)
            IconButton(
              icon: const Icon(Icons.play_circle_outline),
              tooltip: 'Démarrer',
              onPressed: () async {
                final bool? converted = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlannedSessionWizard(session: session),
                  ),
                );
                if (converted == true) {
                  // Recharger session depuis service
                  final all = await _sessionService.getAllSessions();
                  final updated = all.firstWhere((s) => s.id == session.id,
                      orElse: () => session);
                  setState(() {
                    _currentSessionData!['session'] = updated.toMap();
                    _currentSessionData!['series'] =
                        updated.series.map((s) => s.toMap()).toList();
                  });
                }
              },
            ),
          if (session is! DetailedShootingSession || !session.isDraft)
            IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Dupliquer la session',
              onPressed: () async {
                final draft = _sessionService.prepareDuplication(session);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => draft.isSimple
                        ? CreateSimpleSessionScreen(
                            sessionService: _sessionService,
                            duplicationDraft: draft,
                          )
                        : CreateSessionScreen(
                            initialSessionData: draft.initialSessionData,
                            sessionService: _sessionService,
                            duplicationDraft: draft,
                          ),
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => session is SimpleShootingSession
                      ? CreateSimpleSessionScreen(initialSession: session)
                      : CreateSessionScreen(
                          initialSessionData: widget.sessionData,
                          isEdit: true,
                        ),
                ),
              );
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Supprimer la session ?'),
                  content: Text('Cette action est irréversible.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Supprimer',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true && session.id != null) {
                await _sessionService.deleteSession(session.id!);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          SessionHeaderCard(
              session: session, series: series, planned: isPlanned),
          if (session.hasPhoto) ...[
            SizedBox(height: 16),
            SessionPhotoSection(photoPath: session.photoPath!),
          ],
          if (session.exercises.isNotEmpty) ...[
            SizedBox(height: 16),
            SessionExercisesSection(
              exerciseIds: session.exercises,
              allExercises: _allExercises,
            ),
          ],
          if (isRealisee && session is DetailedShootingSession) ...[
            SizedBox(height: 16),
            SessionCoachAnalysisSection(
              session: session,
              analyse: analyse,
              onAnalyseUpdated: () async {
                final all = await _sessionService.getAllSessions();
                final updated = all.firstWhere((s) => s.id == session.id,
                    orElse: () => session);
                setState(() {
                  _currentSessionData!['session'] = updated.toMap();
                  _currentSessionData!['series'] =
                      updated.series.map((s) => s.toMap()).toList();
                });
              },
            ),
          ],
          if (session is DetailedShootingSession) ...[
            SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.list_alt, size: 18, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Séries',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Spacer(),
                Text('${series.length} au total',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            SizedBox(height: 8),
            SeriesList(series: series),
          ],
          if (session.synthese != null && session.synthese!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: SessionSyntheseSection(synthese: session.synthese!),
            ),
        ],
      ),
    );
  }
}
