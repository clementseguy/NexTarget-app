import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/session_constants.dart';
import '../interfaces/session_photo_service_interface.dart';
import '../models/exercise.dart';
import '../models/shooting_session.dart';
import '../services/exercise_service.dart';
import '../services/preferences_service.dart';
import '../services/session_photo_service.dart';
import '../utils/caliber_autocomplete.dart';
import 'caliber_autocomplete_field.dart';
import 'session_form/session_form_components.dart';
import 'weapon_autocomplete_field.dart';

class SimpleSessionForm extends StatefulWidget {
  final SimpleShootingSession? initialSession;
  final ValueChanged<SimpleShootingSession> onSave;
  final ISessionPhotoService? photoService;

  const SimpleSessionForm({
    super.key,
    this.initialSession,
    required this.onSave,
    this.photoService,
  });

  @override
  State<SimpleSessionForm> createState() => SimpleSessionFormState();
}

class SimpleSessionFormState extends State<SimpleSessionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weaponController;
  late final TextEditingController _caliberController;
  late final TextEditingController _shotCountController;
  late final TextEditingController _distanceController;
  late final TextEditingController _syntheseController;
  late final ISessionPhotoService _photoService;
  final ExerciseService _exerciseService = ExerciseService();
  final Set<String> _selectedExerciseIds = {};
  List<Exercise> _exercises = const [];
  late DateTime _date;
  late String _category;
  String? _photoPath;
  String? _initialPhotoPath;
  bool _photoBusy = false;
  bool _loadingExercises = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSession;
    _date = initial?.date ?? DateTime.now();
    _category = initial?.category ?? SessionConstants.categoryEntrainement;
    _weaponController = TextEditingController(text: initial?.weapon ?? '');
    _caliberController = TextEditingController(
      text: pickInitialCaliber(
        existing: initial?.caliber,
        defaultCaliber: PreferencesService().getDefaultCaliber(),
      ),
    );
    _shotCountController =
        TextEditingController(text: initial?.shotCount.toString() ?? '');
    _distanceController = TextEditingController(
      text: initial == null ? '' : _formatDistance(initial.distance),
    );
    _syntheseController = TextEditingController(text: initial?.synthese ?? '');
    _selectedExerciseIds.addAll(initial?.exercises ?? const []);
    _photoPath = initial?.photoPath;
    _initialPhotoPath = _photoPath;
    _photoService = widget.photoService ?? SessionPhotoService();
    _loadExercises();
  }

  String _formatDistance(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();

  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.listAll()
        ..sort((a, b) => a.priority.compareTo(b.priority));
      if (mounted) setState(() => _exercises = exercises);
    } finally {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _photoBusy = true);
    try {
      final newPath = await _photoService.pickAndStore(source);
      if (newPath == null) return;
      final oldPath = _photoPath;
      if (oldPath != null && oldPath != _initialPhotoPath) {
        await _photoService.deleteIfExists(oldPath);
      }
      if (mounted) setState(() => _photoPath = newPath);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    final oldPath = _photoPath;
    if (oldPath != null && oldPath != _initialPhotoPath) {
      await _photoService.deleteIfExists(oldPath);
    }
    if (mounted) setState(() => _photoPath = null);
  }

  bool validateAndBuild() {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final session = SimpleShootingSession(
      id: widget.initialSession?.id,
      date: _date,
      weapon: _weaponController.text.trim(),
      caliber: _caliberController.text.trim(),
      shotCount: int.parse(_shotCountController.text),
      distance: int.parse(_distanceController.text),
      category: _category,
      synthese: _syntheseController.text.trim(),
      exercises: _selectedExerciseIds.toList(),
      photoPath: _photoPath,
    );
    widget.onSave(session);
    return true;
  }

  String? _positiveIntegerValidator(String? text) {
    final value = int.tryParse(text ?? '');
    return value == null || value <= 0 ? 'Entier positif requis' : null;
  }

  @override
  void dispose() {
    _weaponController.dispose();
    _caliberController.dispose();
    _shotCountController.dispose();
    _distanceController.dispose();
    _syntheseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          FormSummaryHeader.dateOnly(
            date: _date,
            onPickDate: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: WeaponAutocompleteField(
                  controller: _weaponController,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Requis' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CaliberAutocompleteField(
                  controller: _caliberController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('simpleShotCount'),
                  controller: _shotCountController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre total de tirs',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _positiveIntegerValidator,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: const Key('simpleDistance'),
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distance',
                    suffixText: 'm',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _positiveIntegerValidator,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: SessionConstants.categories
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(SessionConstants.categoryLabel(category)),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value ?? SessionConstants.categoryEntrainement;
            }),
          ),
          const SizedBox(height: 24),
          ExercisesSelector(
            isLoading: _loadingExercises,
            exercises: _exercises,
            selectedIds: _selectedExerciseIds,
            onToggle: (id) => setState(() {
              _selectedExerciseIds.contains(id)
                  ? _selectedExerciseIds.remove(id)
                  : _selectedExerciseIds.add(id);
            }),
          ),
          const SizedBox(height: 24),
          SessionPhotoField(
            photoPath: _photoPath,
            isBusy: _photoBusy,
            onPickFromGallery: () => _pickPhoto(ImageSource.gallery),
            onPickFromCamera: () => _pickPhoto(ImageSource.camera),
            onRemove: _removePhoto,
          ),
          const SizedBox(height: 24),
          SyntheseCard(
            controller: _syntheseController,
            status: SessionConstants.statusRealisee,
          ),
        ],
      ),
    );
  }
}
