import 'package:flutter/material.dart';

/// Bouton d'aide contextuelle « ? » (NT-075).
///
/// À placer dans l'AppBar d'un écran : ouvre une bottom sheet listant
/// des points d'aide courts et actionnables pour cet écran.
class HelpButton extends StatelessWidget {
  final String title;
  final List<String> points;

  const HelpButton({super.key, required this.title, required this.points});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Aide',
      icon: const Icon(Icons.help_outline),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Theme.of(ctx).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(p)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
