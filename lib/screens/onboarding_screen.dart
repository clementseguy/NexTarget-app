import 'dart:async';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

/// Mini-onboarding 3 écrans affiché au premier lancement (NT-075).
///
/// Réaffichable depuis Paramètres > « Revoir l'introduction ».
class OnboardingScreen extends StatefulWidget {
  /// Appelé quand l'utilisateur termine ou passe l'introduction.
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardingPage({required this.icon, required this.title, required this.body});
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.track_changes,
      title: 'Votre carnet de tir',
      body: 'Enregistrez vos sessions : arme, calibre, séries, points et '
          'groupements. Tout fonctionne hors-ligne, vos données restent '
          'sur votre téléphone.',
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      title: 'Progressez avec vos stats',
      body: 'Tableau de bord, records, tendances : fixez-vous des objectifs '
          'mesurables et suivez des exercices adaptés pour progresser '
          'séance après séance.',
    ),
    _OnboardingPage(
      icon: Icons.school,
      title: 'Votre coach IA',
      body: 'Obtenez une analyse personnalisée de chaque séance. '
          'L\'utilisation du coach nécessite la création d\'un compte.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _finish() {
    // put() Hive met à jour la valeur en mémoire immédiatement ; l'écriture
    // disque part en tâche de fond, inutile de bloquer la navigation dessus.
    unawaited(PreferencesService().setOnboardingSeen(true));
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Passer'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: colorScheme.primary),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? colorScheme.primary
                            : colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(_isLast ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiche l'onboarding au premier lancement, puis [child] ensuite (NT-075).
class OnboardingGate extends StatefulWidget {
  final Widget child;

  const OnboardingGate({super.key, required this.child});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !PreferencesService().isOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(
        onFinished: () => setState(() => _showOnboarding = false),
      );
    }
    return widget.child;
  }
}
