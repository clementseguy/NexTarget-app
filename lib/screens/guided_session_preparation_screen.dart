import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/session_constants.dart';
import '../models/exercise.dart';
import '../models/series.dart';
import '../services/exercise_service.dart';
import '../services/preferences_service.dart';
import '../services/session_service.dart';
import '../services/weapon_service.dart';
import '../widgets/caliber_autocomplete_field.dart';
import '../widgets/session_form/session_form_components.dart';
import '../widgets/weapon_autocomplete_field.dart';
import 'guided_session_screen.dart';

class GuidedSessionPreparationScreen extends StatefulWidget {
  final SessionService? sessionService;
  final PreferencesService? preferencesService;
  final ExerciseService? exerciseService;
  final WeaponService? weaponService;
  final DateTime? initialDate;
  final Future<void> Function()? onSessionChanged;

  const GuidedSessionPreparationScreen({
    super.key,
    this.sessionService,
    this.preferencesService,
    this.exerciseService,
    this.weaponService,
    this.initialDate,
    this.onSessionChanged,
  });

  @override
  State<GuidedSessionPreparationScreen> createState() =>
      _GuidedSessionPreparationScreenState();
}

class _GuidedSessionPreparationScreenState
    extends State<GuidedSessionPreparationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final SessionService _sessionService =
      widget.sessionService ?? SessionService();
  late final PreferencesService _preferencesService =
      widget.preferencesService ?? PreferencesService();
  late final ExerciseService _exerciseService =
      widget.exerciseService ?? ExerciseService();
  late final TextEditingController _weaponController;
  late final TextEditingController _caliberController;
  late final TextEditingController _seriesCountController;
  late final TextEditingController _shotsController;
  late final TextEditingController _distanceController;
  late DateTime _date;
  String _category = SessionConstants.categoryEntrainement;
  late HandMethod _handMethod;
  final Set<String> _selectedExerciseIds = <String>{};
  List<Exercise> _exercises = const [];
  bool _loadingExercises = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController(
      text: _preferencesService.getDefaultCaliber() ?? '',
    );
    _seriesCountController = TextEditingController(text: '10');
    _shotsController = TextEditingController(text: '5');
    _distanceController = TextEditingController(text: '25');
    _handMethod = _preferencesService.getDefaultHandMethod();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.listAll()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      if (mounted) setState(() => _exercises = exercises);
    } catch (_) {
      // Les exercices sont facultatifs : leur indisponibilité ne bloque pas
      // la préparation d'une séance hors ligne.
    } finally {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  @override
  void dispose() {
    _weaponController.dispose();
    _caliberController.dispose();
    _seriesCountController.dispose();
    _shotsController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  int? _positiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  String? _validatePositiveInt(String? value) =>
      _positiveInt(value ?? '') == null
          ? 'Entier strictement positif requis'
          : null;

  Future<void> _pickDateAndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _start() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final draft = await _sessionService.createGuidedDraft(
        date: _date,
        weapon: _weaponController.text,
        caliber: _caliberController.text,
        category: _category,
        exercises: _selectedExerciseIds.toList(),
        seriesCount: _positiveInt(_seriesCountController.text)!,
        shotsPerSeries: _positiveInt(_shotsController.text)!,
        initialDistance: _positiveInt(_distanceController.text)!,
        initialHandMethod: _handMethod,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GuidedSessionScreen(
            draft: draft,
            sessionService: _sessionService,
            onSessionChanged: widget.onSessionChanged,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de commencer la séance : $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seriesCount = _positiveInt(_seriesCountController.text) ?? 0;
    final shots = _positiveInt(_shotsController.text) ?? 0;
    final dateLabel = DateFormat('EEEE d MMMM y', 'fr_FR').format(_date);
    final timeLabel = DateFormat.Hm('fr_FR').format(_date);
    return Scaffold(
      appBar: AppBar(title: const Text('Préparer la séance')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(dateLabel),
              subtitle: Text(timeLabel),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateAndTime,
            ),
            WeaponAutocompleteField(
              controller: _weaponController,
              weaponService: widget.weaponService,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            CaliberAutocompleteField(controller: _caliberController),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: SessionConstants.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(SessionConstants.categoryLabel(category)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _category = value ?? SessionConstants.categoryEntrainement;
              }),
            ),
            const SizedBox(height: 16),
            ExercisesSelector(
              exercises: _exercises,
              selectedIds: _selectedExerciseIds,
              isLoading: _loadingExercises,
              onToggle: (id) => setState(() {
                _selectedExerciseIds.contains(id)
                    ? _selectedExerciseIds.remove(id)
                    : _selectedExerciseIds.add(id);
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('guided_series_count'),
                    controller: _seriesCountController,
                    decoration: const InputDecoration(labelText: 'Séries'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validatePositiveInt,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('guided_shots_per_series'),
                    controller: _shotsController,
                    decoration:
                        const InputDecoration(labelText: 'Coups par série'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validatePositiveInt,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('guided_initial_distance'),
              controller: _distanceController,
              decoration:
                  const InputDecoration(labelText: 'Distance initiale (m)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validatePositiveInt,
            ),
            const SizedBox(height: 12),
            SegmentedButton<HandMethod>(
              segments: const [
                ButtonSegment(
                  value: HandMethod.oneHand,
                  icon: Icon(Icons.front_hand),
                  label: Text('1 main'),
                ),
                ButtonSegment(
                  value: HandMethod.twoHands,
                  icon: Icon(Icons.pan_tool_alt_outlined),
                  label: Text('2 mains'),
                ),
              ],
              selected: {_handMethod},
              onSelectionChanged: (selection) {
                setState(() => _handMethod = selection.first);
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$seriesCount séries · $shots coups par série · '
                  '${seriesCount * shots} coups prévus',
                  key: const Key('guided_volume_summary'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('start_guided_session'),
              onPressed: _saving ? null : _start,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Commencer la séance'),
            ),
          ],
        ),
      ),
    );
  }
}
