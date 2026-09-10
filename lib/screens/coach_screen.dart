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
          if (settingsProvider?.isCoachDataSharingAllowed == true) {
            return const Center(
              child: Text('Coming soon', style: TextStyle(fontSize: 24)),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
          );
        },
      ),
    );
  }
}
