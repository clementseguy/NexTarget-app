import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/shooting_session.dart';
import '../../models/series.dart';
import '../../models/exercise.dart';
import '../../config/app_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/coach_analysis_exception.dart';
import '../../services/server_coach_analysis_service.dart';
import '../../services/session_service.dart';
import '../../utils/markdown_sanitizer.dart';
import '../../widgets/coach_analysis_card.dart';

/// Carte header récapitulative de la session
class SessionHeaderCard extends StatelessWidget {
  final ShootingSession session;
  final List<Series> series;
  final bool planned;
  
  const SessionHeaderCard({
    super.key,
    required this.session,
    required this.series,
    this.planned = false,
  });

  int get totalPoints => series.fold(0, (a,b)=> a + b.points);
  double get avgPoints => series.isEmpty ? 0 : totalPoints / series.length;
  double get avgGroup => () {
    final vals = series.where((s)=> s.groupSize > 0).map((e)=> e.groupSize).toList();
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a,b)=> a+b) / vals.length;
  }();

  @override
  Widget build(BuildContext context) {
    final date = session.date;
    final colorScheme = Theme.of(context).colorScheme;
    final Color accent = planned ? colorScheme.primary : colorScheme.secondary;
    final Color chipBase = colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: planned ? colorScheme.primary.withValues(alpha:0.4): colorScheme.onSurface.withValues(alpha: 0.12),
          width: 0.8,
        ),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: accent),
                SizedBox(width: 8),
                Text(
                  date != null ? '${date.day}/${date.month}/${date.year}' : 'Date inconnue',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Spacer(),
                SessionChip(
                  text: session.status,
                  icon: Icons.flag,
                  color: colorScheme.primary,
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                SessionChip(
                  text: session.weapon.isEmpty ? 'Arme ?' : session.weapon,
                  icon: Icons.security,
                  overrideBase: planned,
                ),
                SessionChip(
                  text: session.caliber.isEmpty ? 'Calibre ?' : session.caliber,
                  icon: Icons.bolt,
                  overrideBase: planned,
                ),
                if (session.category.isNotEmpty)
                  SessionChip(
                    text: session.category,
                    icon: Icons.category,
                    color: colorScheme.secondary,
                  ),
                SessionChip(
                  text: '${series.length} séries',
                  icon: Icons.list_alt,
                  color: chipBase,
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                StatBlock(label: 'Total', value: '$totalPoints pts'),
                DividerVert(),
                StatBlock(label: 'Moy. série', value: avgPoints.toStringAsFixed(1)),
                DividerVert(),
                StatBlock(
                  label: 'Group. moy',
                  value: avgGroup>0? '${avgGroup.toStringAsFixed(1)} cm':'-',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section analyse coach avec bouton génération
class SessionCoachAnalysisSection extends StatefulWidget {
  final ShootingSession session;
  final String? analyse;
  final VoidCallback onAnalyseUpdated;

  const SessionCoachAnalysisSection({
    super.key,
    required this.session,
    required this.analyse,
    required this.onAnalyseUpdated,
  });

  @override
  State<SessionCoachAnalysisSection> createState() => _SessionCoachAnalysisSectionState();
}

class _SessionCoachAnalysisSectionState extends State<SessionCoachAnalysisSection> {
  bool _isAnalysing = false;

  /// Coach « connecté uniquement » (NT-061, décision produit du
  /// 7 juillet 2026) : l'analyse passe exclusivement par le serveur
  /// NexTarget — aucune clé Mistral ni prompt côté client. Le reste de
  /// l'app (carnet de tir) fonctionne sans connexion, ce chemin ne le
  /// concerne pas.
  ///
  /// Le ton du coach (NT-032) vient exclusivement de la préférence
  /// `coachPersona` (Paramètres > Coach IA — retour de recette S2 : pas de
  /// sélecteur dans la session) et part au serveur en `prompt_variant`.
  Future<String> _fetchAnalysisText() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final persona =
        Provider.of<SettingsProvider>(context, listen: false).coachPersona;
    final serverService = ServerCoachAnalysisService(
      baseUrl: AppConfig.I.authBaseUrl,
      authService: authProvider.authService,
    );
    return serverService.analyzeSession(widget.session, promptVariant: persona);
  }

  Future<void> _launchAnalysis() async {
    setState(() => _isAnalysing = true);
    try {
      final rawReply = await _fetchAnalysisText();
      final coachReply = sanitizeCoachMarkdown(rawReply);

      if (coachReply.trim().isNotEmpty) {
        // Afficher la popup markdown
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Analyse du coach'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: MarkdownBody(data: coachReply),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
        
        // Enregistrer la réponse dans la session
        final updatedSession = widget.session..analyse = coachReply;
        await SessionService().updateSession(updatedSession);
        widget.onAnalyseUpdated();
      } else {
        // Erreur API
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Une erreur est survenue lors de l\'analyse, veuillez réesayer ultérieurement.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final msg = (e is CoachAnalysisException)
          ? e.message
          : 'Une erreur est survenue lors de l\'analyse, veuillez réessayer ultérieurement.';
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalysing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: widget.analyse != null && widget.analyse!.trim().isNotEmpty,
        leading: Icon(Icons.analytics, color: Theme.of(context).colorScheme.secondary),
        title: Text('Analyse Coach', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          (widget.analyse != null && widget.analyse!.trim().isNotEmpty)
              ? 'Analyse disponible'
              : 'Aucune analyse générée',
          style: TextStyle(fontSize: 12),
        ),
        children: [
          if (_isAnalysing) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Le coach analyse votre session, merci de patienter...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Coach « connecté uniquement » (NT-061) : sans compte, on
            // affiche un message clair + accès direct à l'écran de connexion.
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (!authProvider.isAuthenticated) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Le coach IA nécessite un compte : connectez-vous pour lancer une analyse.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text('Se connecter'),
                            onPressed: () => Navigator.of(context).pushNamed(AppRouter.login),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        (widget.analyse != null && widget.analyse!.trim().isNotEmpty)
                            ? 'Re-générer'
                            : 'Lancer analyse',
                      ),
                      onPressed: (widget.analyse == null || widget.analyse!.trim().isEmpty)
                          ? _launchAnalysis
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
          if (widget.analyse != null && widget.analyse!.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: CoachAnalysisCard(analyse: sanitizeCoachMarkdown(widget.analyse!)),
            ),
            SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Section exercices travaillés
class SessionExercisesSection extends StatelessWidget {
  final List<String> exerciseIds;
  final List<Exercise> allExercises;

  const SessionExercisesSection({
    super.key,
    required this.exerciseIds,
    required this.allExercises,
  });

  @override
  Widget build(BuildContext context) {
    final nameMap = {for (final e in allExercises) e.id: e.name};
    final names = exerciseIds.map((id) => nameMap[id] ?? id).toList();
    if (names.isEmpty) return SizedBox.shrink();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, size: 18, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 8),
                Text('Exercices travaillés', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final n in names)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: Colors.greenAccent),
                        SizedBox(width: 4),
                        Text(n, style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Section synthèse du tireur
class SessionSyntheseSection extends StatelessWidget {
  final String synthese;

  const SessionSyntheseSection({super.key, required this.synthese});

  @override
  Widget build(BuildContext context) {
    if (synthese.trim().isEmpty) return SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synthèse du tireur',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              synthese,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section photo de la cible (NT-005)
class SessionPhotoSection extends StatelessWidget {
  final String photoPath;

  /// Permet d'injecter un [ImageProvider] alternatif (utilisé par les tests
  /// widgets pour éviter le décodage réel de fichier via [FileImage], qui ne
  /// se résout jamais en environnement headless). Par défaut, comportement
  /// inchangé : [FileImage] sur [photoPath].
  final ImageProvider Function(String path)? imageProviderBuilder;

  const SessionPhotoSection({
    super.key,
    required this.photoPath,
    this.imageProviderBuilder,
  });

  ImageProvider _resolveImageProvider() =>
      (imageProviderBuilder ?? (path) => FileImage(File(path)))(photoPath);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_camera_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                const Text('Photo de la cible', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showFullScreen(context),
                child: Image(
                  image: _resolveImageProvider(),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 120,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                    alignment: Alignment.center,
                    child: const Text('Photo introuvable'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image(
            image: _resolveImageProvider(),
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Photo introuvable'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip générique pour affichage session
class SessionChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  final bool overrideBase;
  
  const SessionChip({
    super.key,
    required this.text,
    required this.icon,
    this.color,
    this.overrideBase = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final Color base = color ?? (overrideBase ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base.withValues(alpha: 0.55), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: base),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: base)),
        ],
      ),
    );
  }
}

/// Bloc statistique générique
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  
  const StatBlock({super.key, required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Divider vertical
class DividerVert extends StatelessWidget {
  const DividerVert({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12));
  }
}
