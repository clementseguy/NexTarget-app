import '../forms/series_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../forms/series_form_data.dart';
import '../services/preferences_service.dart';
import '../utils/caliber_autocomplete.dart';
import 'series_cards.dart';
import 'weapon_autocomplete_field.dart';
import 'caliber_autocomplete_field.dart';
import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import '../models/series.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../interfaces/session_photo_service_interface.dart';
import '../services/session_photo_service.dart';
import 'session_form/session_form_components.dart';

class SessionForm extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  final void Function(ShootingSession session) onSave;
  final bool isEdit;
  final ISessionPhotoService? photoService;
  const SessionForm({
    super.key,
    this.initialSessionData,
    required this.onSave,
    this.isEdit = false,
    this.photoService,
  });

  static SessionFormState? of(BuildContext context) {
    return context.findAncestorStateOfType<SessionFormState>();
  }

  @override
  State<SessionForm> createState() => SessionFormState();
}

class SessionFormState extends State<SessionForm> {
  late TextEditingController _syntheseController;
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  late TextEditingController _weaponController;
  late TextEditingController _caliberController;
  late List<SeriesFormData> _series;
  late List<SeriesFormControllers> _seriesControllers;
  String _category = SessionConstants.categoryEntrainement;
  String _status = SessionConstants.statusRealisee; // allow planned
  // Exercises selection
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _allExercises = [];
  final Set<String> _selectedExerciseIds = <String>{};
  bool _loadingExercises = true;
  // Photo de la cible (NT-005)
  late final ISessionPhotoService _photoService =
      widget.photoService ?? SessionPhotoService();
  String? _photoPath;
  String? _initialPhotoPath;
  bool _photoBusy = false;

  @override
  void initState() {
    super.initState();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
    if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      _date = session['date'] != null && session['date'] != ''
          ? DateTime.tryParse(session['date'])
          : null;
      _weaponController.text = session['weapon'] ?? '';
      final existingCal = widget.isEdit ? session['caliber'] as String? : null;
      _caliberController.text = pickInitialCaliber(
          existing: existingCal,
          defaultCaliber: PreferencesService().getDefaultCaliber());
      _syntheseController =
          TextEditingController(text: session['synthese'] ?? '');
      _category = session['category'] ?? SessionConstants.categoryEntrainement;
      _status = session['status'] ?? SessionConstants.statusRealisee;
      _photoPath = session['photoPath'] as String?;
      _initialPhotoPath = _photoPath;
      // Preload existing exercises list from session map if any
      final existingEx = session['exercises'];
      if (existingEx is List) {
        for (final e in existingEx) {
          if (e is String) _selectedExerciseIds.add(e);
        }
      }
      _series = series
          .map((s) => SeriesFormData(
                shotCount: s['shot_count'] ?? 5,
                distance: (s['distance'] as num?)?.toDouble() ?? 25,
                points: s['points'] ?? 0,
                groupSize: (s['group_size'] as num?)?.toDouble() ?? 0,
                comment: s['comment'] ?? '',
              ))
          .toList();
      if (_series.isEmpty) _series = [SeriesFormData(distance: 25)];
    } else {
      _caliberController.text = pickInitialCaliber(
          existing: null,
          defaultCaliber: PreferencesService().getDefaultCaliber());
      _series = [SeriesFormData(distance: 25)];
      _date = null;
      _syntheseController = TextEditingController();
      _category = SessionConstants.categoryEntrainement;
      _status = SessionConstants.statusRealisee;
    }
    final defaultMethod = PreferencesService().getDefaultHandMethod();
    _seriesControllers = _series
        .map((s) => SeriesFormControllers(
              shotCount: s.shotCount,
              distance: s.distance,
              points: s.points,
              groupSize: s.groupSize,
              comment: s.comment,
              handMethod: 'two',
            ))
        .toList();
    for (int i = 0; i < _seriesControllers.length; i++) {
      // Try detect existing map method using initialSessionData raw map if provided
      if (widget.initialSessionData != null) {
        final rawSeries = widget.initialSessionData!['series'];
        if (rawSeries is List && i < rawSeries.length) {
          final raw = rawSeries[i];
          if (raw is Map && raw['hand_method'] == 'one') {
            _seriesControllers[i].handMethod = 'one';
            continue;
          }
          if (raw is Map && raw['hand_method'] == 'two') {
            _seriesControllers[i].handMethod = 'two';
            continue;
          }
        }
      }
      _seriesControllers[i].handMethod =
          defaultMethod == HandMethod.oneHand ? 'one' : 'two';
    }
    // Load exercises asynchronously
    _loadExercises();
  }

  /// Ouvre la galerie ou l'appareil photo, stocke la photo choisie localement
  /// et remplace la photo précédemment sélectionnée dans ce formulaire (le cas
  /// échéant). La photo déjà persistée en base (si édition) n'est nettoyée
  /// qu'après un enregistrement réussi, côté [SessionService.updateSession].
  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => _photoBusy = true);
    try {
      final newPath = await _photoService.pickAndStore(source);
      if (newPath == null) return;
      final oldPath = _photoPath;
      // Ne supprimer immédiatement que les fichiers temporaires créés pendant
      // cette édition (jamais persistés) ; la photo initiale reste intacte
      // tant que l'utilisateur n'a pas confirmé l'enregistrement du formulaire.
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

  Future<void> _loadExercises() async {
    try {
      final list = await _exerciseService.listAll();
      if (mounted) {
        setState(() {
          _allExercises = list
            ..sort((a, b) => a.priority.compareTo(b.priority));
          _loadingExercises = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  @override
  void dispose() {
    for (final c in _seriesControllers) {
      c.dispose();
    }
    _weaponController.dispose();
    _caliberController.dispose();
    _syntheseController.dispose();
    super.dispose();
  }

  void _addSeries() {
    setState(() {
      // Propager la distance de la dernière série si disponible, sinon 25m
      double propagatedDistance = 25;
      if (_seriesControllers.isNotEmpty) {
        final txt = _seriesControllers.last.distanceController.text.trim();
        final parsed = double.tryParse(txt.replaceAll(',', '.'));
        if (parsed != null && parsed > 0) propagatedDistance = parsed;
      }
      _series.add(SeriesFormData(distance: propagatedDistance));
      _seriesControllers.add(SeriesFormControllers(
        shotCount: 5,
        distance: propagatedDistance,
        points: 0,
        groupSize: 0,
        comment: '',
        handMethod:
            PreferencesService().getDefaultHandMethod() == HandMethod.oneHand
                ? 'one'
                : 'two',
      ));
    });
    // Après rebuild, focus précis via FocusNodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _seriesControllers.last;
      final ordered = [
        {'ctrl': c.shotCountController, 'focus': c.shotCountFocus},
        {'ctrl': c.distanceController, 'focus': c.distanceFocus},
        {'ctrl': c.pointsController, 'focus': c.pointsFocus},
        {'ctrl': c.groupSizeController, 'focus': c.groupSizeFocus},
        {'ctrl': c.commentController, 'focus': c.commentFocus},
      ];
      for (final item in ordered) {
        final TextEditingController ctrl =
            item['ctrl'] as TextEditingController;
        final FocusNode node = item['focus'] as FocusNode;
        final text = ctrl.text.trim();
        if (text.isEmpty || text == '0') {
          FocusScope.of(context).requestFocus(node);
          ctrl.selection =
              TextSelection(baseOffset: 0, extentOffset: text.length);
          break;
        }
      }
    });
  }

  // _save supprimé (logique de validation déplacée dans callback externe si nécessaire)
  bool validateAndBuild() {
    if (!_formKey.currentState!.validate()) return false;
    if (_status == SessionConstants.statusRealisee) {
      if (_series.isEmpty ||
          _series.every((s) =>
              s.shotCount == 0 &&
              s.distance == 0 &&
              s.points == 0 &&
              s.groupSize == 0 &&
              s.comment.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Veuillez ajouter au moins une série à la session réalisée.')),
        );
        return false;
      }
    }
    if (_date == null && _status == SessionConstants.statusRealisee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La date est obligatoire.')),
      );
      return false;
    }
    // Conserver l'id session si édition
    int? existingId;
    if (widget.initialSessionData != null) {
      final sess = widget.initialSessionData!['session'];
      if (sess is Map && sess['id'] != null) {
        existingId = sess['id'] as int?;
      }
    }
    final session = DetailedShootingSession(
      id: existingId,
      date: _date,
      weapon: _weaponController.text,
      caliber: _caliberController.text,
      status: _status,
      series: List.generate(
          _series.length,
          (i) => Series(
                shotCount: int.tryParse(
                        _seriesControllers[i].shotCountController.text) ??
                    0,
                distance: double.tryParse(
                        _seriesControllers[i].distanceController.text) ??
                    0,
                points:
                    int.tryParse(_seriesControllers[i].pointsController.text) ??
                        0,
                groupSize: double.tryParse(
                        _seriesControllers[i].groupSizeController.text) ??
                    0,
                comment: _seriesControllers[i].commentController.text.trim(),
                handMethod: _seriesControllers[i].handMethod == 'one'
                    ? HandMethod.oneHand
                    : HandMethod.twoHands,
              )),
      synthese: _syntheseController.text,
      category: _category,
      exercises: _selectedExerciseIds.toList(),
      photoPath: _photoPath,
    );
    widget.onSave(session);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = _seriesControllers.fold<int>(0, (a, c) {
      final v = int.tryParse(c.pointsController.text) ?? 0;
      return a + v;
    });
    final double avgPoints = _seriesControllers.isEmpty
        ? 0.0
        : totalPoints / _seriesControllers.length;
    double? dominantDistance;
    if (_seriesControllers.isNotEmpty) {
      final distances = <double, int>{};
      for (final c in _seriesControllers) {
        final d = double.tryParse(c.distanceController.text) ?? 0;
        if (d > 0) distances[d] = (distances[d] ?? 0) + 1;
      }
      if (distances.isNotEmpty) {
        dominantDistance =
            distances.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          FormSummaryHeader(
            date: _date,
            onPickDate: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
            seriesCount: _seriesControllers.length,
            totalPoints: totalPoints,
            avgPoints: avgPoints,
            dominantDistance: dominantDistance,
          ),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: WeaponAutocompleteField(
                  controller: _weaponController,
                  labelText: 'Arme (optionnel si prévue)',
                  validator: (v) {
                    if (_status == SessionConstants.statusPrevue) {
                      return null; // optional
                    }
                    if (v == null || v.isEmpty) {
                      return 'Requis';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: CaliberAutocompleteField(
                  controller: _caliberController,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(labelText: 'Catégorie'),
            items: SessionConstants.categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(SessionConstants.categoryLabel(c)),
                    ))
                .toList(),
            onChanged: (v) => setState(
                () => _category = v ?? SessionConstants.categoryEntrainement),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(labelText: 'Statut'),
            items: [
              DropdownMenuItem(
                  value: SessionConstants.statusRealisee,
                  child: Text('Réalisée')),
              DropdownMenuItem(
                  value: SessionConstants.statusPrevue, child: Text('Prévue')),
            ],
            onChanged: (v) =>
                setState(() => _status = v ?? SessionConstants.statusRealisee),
          ),
          // No direct goal link; exercises link goals indirectly.
          SizedBox(height: 24),
          // ---- Exercises selection ----
          ExercisesSelector(
            isLoading: _loadingExercises,
            exercises: _allExercises,
            selectedIds: _selectedExerciseIds,
            onToggle: (id) {
              setState(() {
                if (_selectedExerciseIds.contains(id)) {
                  _selectedExerciseIds.remove(id);
                } else {
                  _selectedExerciseIds.add(id);
                }
              });
            },
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.list_alt, size: 18, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Séries',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Spacer(),
              Text('${_seriesControllers.length}',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          SizedBox(height: 8),
          ..._series.asMap().entries.map((entry) {
            final i = entry.key;
            final c = _seriesControllers[i];
            return SeriesEditCard(
              index: i,
              controllers: c,
              canDelete: _series.length > 1,
              onDelete: () {
                setState(() {
                  _series.removeAt(i);
                  _seriesControllers[i].dispose();
                  _seriesControllers.removeAt(i);
                });
              },
              onDuplicate: () {
                setState(() {
                  final newData = SeriesFormData(
                    shotCount: int.tryParse(c.shotCountController.text) ?? 5,
                    distance: double.tryParse(c.distanceController.text) ?? 25,
                    points: int.tryParse(c.pointsController.text) ?? 0,
                    groupSize: double.tryParse(c.groupSizeController.text) ?? 0,
                    comment: c.commentController.text,
                  );
                  _series.insert(i + 1, newData);
                  _seriesControllers.insert(
                      i + 1,
                      SeriesFormControllers(
                        shotCount: newData.shotCount,
                        distance: newData.distance,
                        points: newData.points,
                        groupSize: newData.groupSize,
                        comment: newData.comment,
                        handMethod: c.handMethod,
                      ));
                });
              },
            );
          }),
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addSeries,
            icon: Icon(Icons.add),
            label: Text('Ajouter une série'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amberAccent,
              side:
                  BorderSide(color: Colors.amberAccent.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
          SizedBox(height: 28),
          SessionPhotoField(
            photoPath: _photoPath,
            isBusy: _photoBusy,
            onPickFromGallery: () => _pickPhoto(ImageSource.gallery),
            onPickFromCamera: () => _pickPhoto(ImageSource.camera),
            onRemove: _removePhoto,
          ),
          SizedBox(height: 24),
          SyntheseCard(
            controller: _syntheseController,
            status: _status,
          ),
        ],
      ),
    );
  }
}
