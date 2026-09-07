import 'package:flutter/material.dart';

class GroupSizeHelpButton extends StatelessWidget {
  const GroupSizeHelpButton({super.key});

  static const String semanticsLabel =
      'Aide pour estimer la taille du groupement';

  Future<void> _showHelp(BuildContext context) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Estimer le groupement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Poing fermé, moins de 10 centimètres',
                child: const Text('Poing fermé : moins de 10 cm.'),
              ),
              const SizedBox(height: 10),
              Semantics(
                label:
                    'Poing fermé avec pouce déployé en forme like, environ 15 centimètres',
                child: const Text(
                  'Poing fermé avec le pouce déployé, en forme « like » : environ 15 cm.',
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                label:
                    'Pouce et petit doigt déployés en forme téléphone, environ 20 centimètres',
                child: const Text(
                  'Pouce et petit doigt déployés, en forme « téléphone » : environ 20 cm.',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Ces valeurs sont approximatives et dépendent de la taille de votre main. Comparez au niveau de la cible, pas depuis le pas de tir.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: IconButton(
        tooltip: semanticsLabel,
        icon: const Icon(Icons.help_outline),
        onPressed: () => _showHelp(context),
      ),
    );
  }
}
