import 'dart:io';
import 'package:flutter/material.dart';

/// Composants réutilisables pour session_form
/// Extraction pour réduire taille fichier principal et améliorer maintenabilité

/// En-tête récapitulatif du formulaire avec statistiques agrégées
class FormSummaryHeader extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onPickDate;
  final int seriesCount;
  final int totalPoints;
  final double avgPoints;
  final double? dominantDistance;
  
  const FormSummaryHeader({
    super.key,
    required this.date,
    required this.onPickDate,
    required this.seriesCount,
    required this.totalPoints,
    required this.avgPoints,
    required this.dominantDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event, color: Colors.amberAccent),
                const SizedBox(width: 8),
                Text(
                  date != null ? '${date!.day}/${date!.month}/${date!.year}' : 'Date ?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Choisir'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                MiniStat(
                  label: 'Séries',
                  value: seriesCount.toString(),
                  icon: Icons.list_alt,
                  color: Colors.lightBlueAccent,
                ),
                const DividerV(),
                MiniStat(
                  label: 'Total',
                  value: totalPoints.toString(),
                  icon: Icons.score,
                  color: Colors.pinkAccent,
                ),
                const DividerV(),
                MiniStat(
                  label: 'Moy.',
                  value: avgPoints.toStringAsFixed(1),
                  icon: Icons.stacked_line_chart,
                  color: Colors.greenAccent,
                ),
                const DividerV(),
                MiniStat(
                  label: 'Dist.',
                  value: dominantDistance != null
                      ? '${dominantDistance!.toStringAsFixed(0)}m'
                      : '-',
                  icon: Icons.social_distance,
                  color: Colors.tealAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini statistique compacte avec icône et valeur
class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Séparateur vertical compact
class DividerV extends StatelessWidget {
  const DividerV({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

/// Carte synthèse tireur (notes perso)
class SyntheseCard extends StatelessWidget {
  final TextEditingController controller;
  final String status;

  const SyntheseCard({
    super.key,
    required this.controller,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.edit_note, color: Colors.amberAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Synthèse personnelle',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: status == 'prévue'
                    ? 'Objectifs, focus...'
                    : 'Ressentis, observations, axes d\'amélioration...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur d'exercices associés
class ExercisesSelector extends StatelessWidget {
  final List exercises;
  final Set<String> selectedIds;
  final void Function(String) onToggle;
  final bool isLoading;

  const ExercisesSelector({
    super.key,
    required this.exercises,
    required this.selectedIds,
    required this.onToggle,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                children: [
                  Icon(Icons.fitness_center,
                      color: Colors.amberAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Exercices associés',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 12),
              Text('Aucun exercice disponible',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    color: Colors.amberAccent, size: 20),
                const SizedBox(width: 8),
                const Text('Exercices associés',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(
                  '(${selectedIds.length})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exercises.map((ex) {
                final selected = selectedIds.contains(ex.id);
                return FilterChip(
                  label: Text(ex.name, overflow: TextOverflow.ellipsis),
                  selected: selected,
                  onSelected: (_) => onToggle(ex.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sélecteur/aperçu de la photo de la cible attachée à la session (NT-005).
/// Propose systématiquement les deux modes de capture (galerie ET appareil photo).
class SessionPhotoField extends StatelessWidget {
  final String? photoPath;
  final bool isBusy;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final VoidCallback onRemove;

  /// Permet d'injecter un [ImageProvider] alternatif (utilisé par les tests
  /// widgets pour éviter le décodage réel de fichier via [FileImage], qui ne
  /// se résout jamais en environnement headless). Par défaut, comportement
  /// inchangé : [FileImage] sur [photoPath].
  final ImageProvider Function(String path)? imageProviderBuilder;

  const SessionPhotoField({
    super.key,
    required this.photoPath,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onRemove,
    this.isBusy = false,
    this.imageProviderBuilder,
  });

  bool get _hasPhoto => photoPath != null && photoPath!.trim().isNotEmpty;

  ImageProvider _resolveImageProvider() =>
      (imageProviderBuilder ?? (path) => FileImage(File(path)))(photoPath!);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.photo_camera_outlined, color: Colors.amberAccent, size: 20),
                SizedBox(width: 8),
                Text('Photo de la cible', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (isBusy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_hasPhoto) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: _resolveImageProvider(),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Text('Photo introuvable', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filled(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Supprimer la photo',
                      onPressed: onRemove,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  'Aucune photo pour le moment',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onPickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galerie'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onPickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_hasPhoto ? 'Reprendre' : 'Appareil photo'),
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
