import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/session_constants.dart';
import '../../models/series.dart';
import '../../models/exercise.dart';
import '../../models/exercise_execution.dart';
import '../../models/goal.dart';
import '../../widgets/weapon_autocomplete_field.dart';
import '../../widgets/caliber_autocomplete_field.dart';
import '../../widgets/group_size_help.dart';

/// Étape introduction du wizard (exercice, arme, calibre, catégorie)
class WizardIntroStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool loadingExercise;
  final Exercise? linkedExercise;
  final List<Goal> goals;
  final TextEditingController weaponController;
  final TextEditingController caliberController;
  final FocusNode caliberFocusNode;
  final String? categoryDraft;
  final ValueChanged<String> onCaliberChanged;
  final ValueChanged<String?> onCaliberSaved;
  final ValueChanged<String?> onCategorySaved;
  final VoidCallback onValidate;

  const WizardIntroStep({
    super.key,
    required this.formKey,
    required this.loadingExercise,
    required this.linkedExercise,
    required this.goals,
    required this.weaponController,
    required this.caliberController,
    required this.caliberFocusNode,
    required this.categoryDraft,
    required this.onCaliberChanged,
    required this.onCaliberSaved,
    required this.onCategorySaved,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final hasExercise = linkedExercise != null || loadingExercise;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Démarrage', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exercice',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      if (!hasExercise)
                        const Text('Pas d\'exercice associé')
                      else if (loadingExercise)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (linkedExercise != null) ...[
                        Text(
                          linkedExercise!.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (linkedExercise!.description != null &&
                            linkedExercise!.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            linkedExercise!.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ExerciseMetadataLabel(
                              icon: Icons.list_alt,
                              text:
                                  '${linkedExercise!.consignes.length} consigne(s)',
                            ),
                            _ExerciseMetadataLabel(
                              icon: Icons.timer_outlined,
                              text: linkedExercise!.durationMinutes == null
                                  ? 'Durée : non renseignée'
                                  : 'Durée : ${linkedExercise!.durationMinutes} min',
                            ),
                            _ExerciseMetadataLabel(
                              icon: Icons.build_outlined,
                              text: linkedExercise!.equipment == null ||
                                      linkedExercise!.equipment!.trim().isEmpty
                                  ? 'Matériel requis : non renseigné'
                                  : 'Matériel requis : ${linkedExercise!.equipment!.trim()}',
                            ),
                          ],
                        ),
                        if (goals.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: goals
                                .map(
                                  (goal) => Chip(
                                    label: Text(goal.title),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ] else
                        const Text('Exercice introuvable'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Informations session',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            WeaponAutocompleteField(
              controller: weaponController,
              labelText: 'Arme',
            ),
            const SizedBox(height: 12),
            CaliberAutocompleteField(
              controller: caliberController,
              focusNode: caliberFocusNode,
              onChanged: onCaliberChanged,
              onSaved: onCaliberSaved,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: SessionConstants.categories.contains(categoryDraft)
                  ? categoryDraft
                  : SessionConstants.categoryEntrainement,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: SessionConstants.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(SessionConstants.categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onSaved: onCategorySaved,
              onChanged: onCategorySaved,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onValidate,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Commencer'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ExerciseMetadataLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ExerciseMetadataLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 100,
            ),
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Qualification facultative de l'exercice sur la dernière page du wizard.
class WizardExerciseQualificationStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String initialSynthese;
  final bool? initialPerformed;
  final ProtocolFollowed? initialProtocolFollowed;
  final String? initialComment;
  final bool saving;
  final ValueChanged<String?> onSyntheseSaved;
  final ValueChanged<bool?> onPerformedChanged;
  final ValueChanged<ProtocolFollowed?> onProtocolFollowedChanged;
  final ValueChanged<String?> onCommentSaved;
  final VoidCallback onFinish;

  const WizardExerciseQualificationStep({
    super.key,
    required this.formKey,
    required this.initialSynthese,
    required this.initialPerformed,
    required this.initialProtocolFollowed,
    required this.initialComment,
    required this.saving,
    required this.onSyntheseSaved,
    required this.onPerformedChanged,
    required this.onProtocolFollowedChanged,
    required this.onCommentSaved,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synthèse de la session',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Synthèse du tireur',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('session_synthese'),
              initialValue: initialSynthese,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Commentaire de la session (facultatif)',
                alignLabelWithHint: true,
              ),
              onSaved: onSyntheseSaved,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Analyse de l’exercice',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('Ces informations sont facultatives.'),
            const SizedBox(height: 16),
            _QualificationLabel(
              label: 'Exercice réalisé',
              help: 'Indiquez si vous avez réussi à faire l’exercice du '
                  'début à la fin. Vous pouvez préciser votre réponse dans '
                  'le commentaire.',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('exercise_performed'),
              initialValue: switch (initialPerformed) {
                true => 'yes',
                false => 'no',
                null => 'unanswered',
              },
              decoration: const InputDecoration(labelText: 'Réponse'),
              items: const [
                DropdownMenuItem(
                    value: 'unanswered', child: Text('Non renseigné')),
                DropdownMenuItem(value: 'yes', child: Text('Oui')),
                DropdownMenuItem(value: 'no', child: Text('Non')),
              ],
              onChanged: saving
                  ? null
                  : (value) => onPerformedChanged(switch (value) {
                        'yes' => true,
                        'no' => false,
                        _ => null,
                      }),
            ),
            const SizedBox(height: 20),
            _QualificationLabel(
              label: 'Protocole suivi',
              help: 'Indiquez si vous avez réussi à suivre le protocole '
                  'proposé par l’exercice du début à la fin. Vous pouvez '
                  'préciser votre réponse dans le commentaire.',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const ValueKey('protocol_followed'),
              initialValue: initialProtocolFollowed?.name ?? 'unanswered',
              decoration: const InputDecoration(labelText: 'Réponse'),
              items: const [
                DropdownMenuItem(
                    value: 'unanswered', child: Text('Non renseigné')),
                DropdownMenuItem(value: 'yes', child: Text('Oui')),
                DropdownMenuItem(
                    value: 'partially', child: Text('Partiellement')),
                DropdownMenuItem(value: 'no', child: Text('Non')),
              ],
              onChanged: saving
                  ? null
                  : (value) => onProtocolFollowedChanged(switch (value) {
                        'yes' => ProtocolFollowed.yes,
                        'partially' => ProtocolFollowed.partially,
                        'no' => ProtocolFollowed.no,
                        _ => null,
                      }),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('exercise_comment'),
              initialValue: initialComment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Commentaire sur l’exercice (facultatif)',
                alignLabelWithHint: true,
              ),
              onSaved: onCommentSaved,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onFinish,
                icon: const Icon(Icons.check),
                label: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualificationLabel extends StatelessWidget {
  final String label;
  final String help;

  const _QualificationLabel({required this.label, required this.help});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Tooltip(
          message: help,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 5),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.help_outline, semanticLabel: 'Aide'),
          ),
        ),
      ],
    );
  }
}

/// Étape série individuelle
class WizardSeriesStep extends StatelessWidget {
  final int seriesIndex; // Index réel de la série (0-based)
  final SeriesStepController controller;
  final bool isLastSeries;
  final VoidCallback onValidate;

  const WizardSeriesStep({
    super.key,
    required this.seriesIndex,
    required this.controller,
    required this.isLastSeries,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final consigne = controller.consigne.trim().isEmpty
        ? 'Pas de consigne'
        : controller.consigne;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(consigne, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                    key: ValueKey('points_${seriesIndex}_${controller.points}'),
                    initialValue: '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Points'),
                    onChanged: (v) {
                      controller.points = int.tryParse(v) ?? 0;
                    },
                    validator: (_) =>
                        (controller.showErrors && controller.points <= 0)
                            ? 'Requis'
                            : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextFormField(
                    key: ValueKey(
                        'group_${seriesIndex}_${controller.groupSize}'),
                    initialValue: '',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Groupement',
                      suffixIcon: GroupSizeHelpButton(),
                    ),
                    onChanged: (v) {
                      controller.groupSize = double.tryParse(v) ?? 0;
                    },
                    validator: (_) =>
                        (controller.showErrors && controller.groupSize <= 0)
                            ? 'Requis'
                            : null,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: TextFormField(
                    key: ValueKey(
                        'shots_${seriesIndex}_${controller.shotCount}'),
                    initialValue: controller.shotCount.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Coups'),
                    onChanged: (v) {
                      controller.shotCount =
                          int.tryParse(v) ?? controller.shotCount;
                    },
                    validator: (_) =>
                        (controller.showErrors && controller.shotCount <= 0)
                            ? 'Requis'
                            : null,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextFormField(
                    key: ValueKey('dist_${seriesIndex}_${controller.distance}'),
                    initialValue: controller.distance.toString(),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Distance (m)'),
                    onChanged: (v) {
                      controller.distance =
                          double.tryParse(v) ?? controller.distance;
                    },
                    validator: (_) => (controller.showErrors &&
                            (controller.distance <= 0 ||
                                controller.distance !=
                                    controller.distance.truncateToDouble()))
                        ? 'Entier requis'
                        : null,
                  )),
                ]),
                const SizedBox(height: 12),
                HandMethodSelector(
                  initial: controller.handMethod,
                  onChanged: (m) {
                    controller.handMethod = m;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: ValueKey('comment_$seriesIndex'),
                  initialValue: '',
                  decoration:
                      const InputDecoration(labelText: 'Commentaire série'),
                  onChanged: (v) => controller.comment = v,
                  maxLines: null,
                  validator: (_) => (controller.showErrors &&
                          (controller.comment == null ||
                              controller.comment!.trim().isEmpty))
                      ? 'Requis'
                      : null,
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: onValidate,
                    child: Text(isLastSeries ? 'Suite' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Étape synthèse finale
class WizardSyntheseStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String initialSynthese;
  final bool saving;
  final ValueChanged<String?> onSaved;
  final VoidCallback onFinish;

  const WizardSyntheseStep({
    super.key,
    required this.formKey,
    required this.initialSynthese,
    required this.saving,
    required this.onSaved,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Synthèse', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: TextFormField(
                initialValue: initialSynthese,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Synthèse de la session',
                  alignLabelWithHint: true,
                ),
                onSaved: onSaved,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saving ? null : onFinish,
                icon: const Icon(Icons.check),
                label: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Terminer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Controller pour données d'une série dans le wizard
class SeriesStepController {
  int points;
  double groupSize;
  String? comment;
  int shotCount;
  double distance;
  HandMethod handMethod;
  String consigne;
  bool showErrors;

  SeriesStepController({
    required this.points,
    required this.groupSize,
    required this.comment,
    required this.shotCount,
    required this.distance,
    required this.handMethod,
    required this.consigne,
  }) : showErrors = false;

  Series build() => Series(
        points: points,
        groupSize: groupSize,
        comment: comment ?? '',
        shotCount: shotCount,
        distance: distance,
        handMethod: handMethod,
      );
}

/// Sélecteur de prise (une main / deux mains)
class HandMethodSelector extends StatefulWidget {
  final HandMethod initial;
  final ValueChanged<HandMethod> onChanged;
  const HandMethodSelector(
      {super.key, required this.initial, required this.onChanged});
  @override
  State<HandMethodSelector> createState() => _HandMethodSelectorState();
}

class _HandMethodSelectorState extends State<HandMethodSelector> {
  late HandMethod _method;
  @override
  void initState() {
    super.initState();
    _method = widget.initial;
  }

  void _set(HandMethod m) {
    setState(() => _method = m);
    widget.onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Prise', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        ToggleButtons(
          isSelected: [
            _method == HandMethod.oneHand,
            _method == HandMethod.twoHands
          ],
          borderRadius: BorderRadius.circular(12),
          constraints: const BoxConstraints(minHeight: 34, minWidth: 46),
          onPressed: (i) {
            _set(i == 0 ? HandMethod.oneHand : HandMethod.twoHands);
          },
          children: const [
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.front_hand, size: 18)),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: TwoHandsIconMini()),
          ],
        ),
      ],
    );
  }
}

/// Icône custom pour deux mains
class TwoHandsIconMini extends StatelessWidget {
  const TwoHandsIconMini({super.key});
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return SizedBox(
        width: 30,
        height: 18,
        child: Stack(children: [
          Positioned(
              left: 0,
              top: 0,
              child: Icon(Icons.front_hand,
                  size: 14, color: color.withValues(alpha: 0.8))),
          Positioned(
              left: 12,
              top: 0,
              child: Icon(Icons.front_hand, size: 16, color: color)),
        ]));
  }
}
