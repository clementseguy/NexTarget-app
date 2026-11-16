import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_router.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_bar_title.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const AppBarTitle(
          icon: Icons.school,
          label: 'Coach',
        ),
      ),
      body: Builder(
        builder: (context) {
          final settingsProvider = Provider.of<SettingsProvider?>(context);
          final allowed = settingsProvider?.isCoachDataSharingAllowed == true;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!allowed) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline, size: 40),
                        const SizedBox(height: 16),
                        const Text(
                          'Le partage de vos données est requis pour utiliser les Coachs NexTarget.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Paramètres Coach'),
                          onPressed: () => AppRouter.showSettingsTab(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _CoachPresentationCard(
                icon: Icons.fact_check_outlined,
                title: 'Coach de session',
                description:
                    'Un débrief factuel accessible depuis chaque session réalisée.',
                availability: 'Disponible dans le détail de la session',
              ),
              const SizedBox(height: 16),
              const _CoachPresentationCard(
                icon: Icons.trending_up,
                title: 'Coach de progression',
                description:
                    'Il analysera votre progression et décidera de la prochaine priorité.',
                availability: 'Bientôt disponible',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CoachPresentationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String availability;

  const _CoachPresentationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(description),
              const SizedBox(height: 12),
              Text(
                availability,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
