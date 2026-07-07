import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Carte affichant l'analyse du coach rendue en markdown.
/// N'affiche rien si le contenu est vide.
class CoachAnalysisCard extends StatelessWidget {
  final String analyse;
  const CoachAnalysisCard({super.key, required this.analyse});

  @override
  Widget build(BuildContext context) {
    if (analyse.trim().isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.secondary, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analyse du coach', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            MarkdownBody(
              data: analyse,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: colorScheme.onSurface),
                strong: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                h1: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold),
                h2: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
                h3: TextStyle(color: colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
                code: TextStyle(color: colorScheme.secondary),
                blockquote: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                listBullet: TextStyle(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
