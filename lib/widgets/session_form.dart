import '../forms/series_form_controllers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../forms/series_form_data.dart';
import '../services/preferences_service.dart';
import '../services/session_template_service.dart';
import '../utils/caliber_autocomplete.dart';
import 'series_cards.dart';
import '../models/shooting_session.dart';
import '../constants/session_constants.dart';
import '../models/series.dart';
import '../models/tar_referential.dart';
import '../models/exercise.dart';
import '../services/exercise_service.dart';
import '../interfaces/session_photo_service_interface.dart';
import '../services/session_photo_service.dart';
import '../services/tar_referential_service.dart';
import 'session_form/session_form_components.dart';

class SessionForm extends StatefulWidget {
  final Map<String, dynamic>? initialSessionData;
  final void Function(ShootingSession session) onSave;
  final bool isEdit;
  final ISessionPhotoService? photoService;
  final TarReferentialService? tarReferentialService;
  const SessionForm({
    super.key,
    this.initialSessionData,
    required this.onSave,
    this.isEdit = false,
    this.photoService,
    this.tarReferentialService,
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
  final FocusNode _caliberFocus = FocusNode();
  bool _showAllCaliberOptions = false;
  String _lastCaliberText = '';
  late List<SeriesFormData> _series;
  late List<SeriesFormControllers> _seriesControllers;
  String _category = SessionConstants.categoryEntrainement;
  String _status = SessionConstants.statusRealisee; // allow planned
  // Exercises selection
  final ExerciseService _exerciseService = ExerciseService();
  List<Exercise> _allExercises = [];
  final Set<String> _selectedExerciseIds = <String>{};
  bool _loadingExercises = true;
  late final TarReferentialService _tarReferentialService =
      widget.tarReferentialService ?? TarReferentialService();
  TarReferential? _tarReferential;
  String? _selectedDisciplineCode;
  String? _selectedDisciplineSeason;
  bool _prefillInitialDisciplineWhenReady = false;
  // Photo de la cible (NT-005)
  late final ISessionPhotoService _photoService =
      widget.photoService ?? SessionPhotoService();
  String? _photoPath;
  String? _initialPhotoPath;
  bool _photoBusy = false;

  String? _initialDisciplineCode() {
    final session = widget.initialSessionData?['session'];
    if (session is! Map) return null;
    final value = session['discipline_code'] ?? session['disciplineCode'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _initialDisciplineSeason() {
    final session = widget.initialSessionData?['session'];
    if (session is! Map) return null;
    final value = session['discipline_season'] ?? session['disciplineSeason'];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  SeriesFormData _seriesFormDataFromRaw(dynamic raw) {
    if (raw is Series) {
      return SeriesFormData(
        shotCount: raw.shotCount,
        distance: raw.distance,
        points: raw.points,
        groupSize: raw.groupSize,
        comment: raw.comment,
        handMethod: raw.handMethod,
        sequenceType: raw.sequenceType,
        scoringMode: raw.scoringMode,
        targetType: raw.targetType,
        timeLimitLabel: raw.timeLimitLabel,
        timeLimitSeconds: raw.timeLimitSeconds,
        gongsHit: raw.gongsHit,
        gongPointValue: raw.gongPointValue,
      );
    }
    final map = raw is Map ? raw : const <dynamic, dynamic>{};
    final scoringMode = _scoringModeFromValue(
      map['scoring_mode'] ?? map['scoringMode'],
    );
    final gongsHit = _readInt(map['gongs_hit'] ?? map['gongsHit']);
    final gongPointValue =
        _readInt(map['gong_point_value'] ?? map['gongPointValue']) ?? 5;
    final points = _readInt(map['points']) ??
        (scoringMode == SeriesScoringMode.gongsTombes && gongsHit != null
            ? gongsHit * gongPointValue
            : 0);

    return SeriesFormData(
      shotCount: _readInt(map['shot_count'] ?? map['shotCount']) ?? 5,
      distance: _readDouble(map['distance']) ?? 25,
      points: points,
      groupSize: _readDouble(map['group_size'] ?? map['groupSize']) ?? 0,
      comment: map['comment']?.toString() ?? '',
      handMethod: _handMethodFromValue(map['hand_method'] ?? map['handMethod']),
      sequenceType:
          _sequenceTypeFromValue(map['sequence_type'] ?? map['sequenceType']),
      scoringMode: scoringMode,
      targetType: _cleanString(map['target_type'] ?? map['targetType']),
      timeLimitLabel:
          _cleanString(map['time_limit_label'] ?? map['timeLimitLabel']),
      timeLimitSeconds:
          _readInt(map['time_limit_seconds'] ?? map['timeLimitSeconds']),
      gongsHit: gongsHit,
      gongPointValue: gongPointValue,
    );
  }

  SeriesFormControllers _controllersFromData(SeriesFormData data) {
    final controller = SeriesFormControllers(
      shotCount: data.shotCount,
      distance: data.distance,
      points: data.points,
      groupSize: data.groupSize,
      comment: data.comment,
      handMethod: data.handMethod == HandMethod.oneHand ? 'one' : 'two',
      sequenceType: data.sequenceType,
      scoringMode: data.scoringMode,
      targetType: data.targetType,
      timeLimitLabel: data.timeLimitLabel,
      timeLimitSeconds: data.timeLimitSeconds,
      gongsHit: data.gongsHit,
      gongPointValue: data.gongPointValue,
    );
    controller.syncGongPoints();
    return controller;
  }

  Future<void> _loadTarReferential() async {
    try {
      final referential = await _tarReferentialService.load();
      if (!mounted) return;
      setState(() {
        _tarReferential = referential;
        if (_selectedDisciplineCode != null) {
          _selectedDisciplineSeason ??= referential.metadata.season;
        }
        if (_prefillInitialDisciplineWhenReady &&
            _selectedDisciplineCode != null) {
          final discipline =
              referential.resolvedDisciplineByCode(_selectedDisciplineCode!);
          if (discipline != null) {
            _replaceSeriesFromDiscipline(discipline);
          }
          _prefillInitialDisciplineWhenReady = false;
        }
      });
    } catch (_) {
      // Le formulaire reste utilisable sans referentiel charge.
    }
  }

  void _onDisciplineChanged(String? code) {
    final referential = _tarReferential;
    setState(() {
      _selectedDisciplineCode = code;
      _selectedDisciplineSeason =
          code == null ? null : referential?.metadata.season;
      if (code == null) {
        _prefillInitialDisciplineWhenReady = false;
        return;
      }
      if (referential == null) {
        _prefillInitialDisciplineWhenReady = true;
        return;
      }
      final discipline = referential.resolvedDisciplineByCode(code);
      if (discipline != null) {
        _replaceSeriesFromDiscipline(discipline);
      }
      _prefillInitialDisciplineWhenReady = false;
    });
  }

  void _replaceSeriesFromDiscipline(TarDiscipline discipline) {
    for (final controller in _seriesControllers) {
      controller.dispose();
    }
    _series = _seriesFromDiscipline(discipline);
    _seriesControllers = _series.map(_controllersFromData).toList();
  }

  List<SeriesFormData> _seriesFromDiscipline(TarDiscipline discipline) {
    final distance = (discipline.distanceMeters ?? 25).toDouble();
    final gongPointValue = _readInt(discipline.scoring['gong_tombe_pts']) ?? 5;
    return discipline.sequences.map((sequence) {
      final scoringMode = sequence.target == 'gong'
          ? SeriesScoringMode.gongsTombes
          : SeriesScoringMode.pointsZone;
      return SeriesFormData(
        shotCount: sequence.shots,
        distance: distance,
        points: 0,
        groupSize: 0,
        comment: '',
        handMethod: _handMethodFromStance(sequence.stance),
        sequenceType: _sequenceTypeFromValue(sequence.type),
        scoringMode: scoringMode,
        targetType: sequence.target,
        timeLimitLabel: sequence.time,
        timeLimitSeconds: _timeLimitSeconds(sequence.time),
        gongsHit: scoringMode == SeriesScoringMode.gongsTombes ? 0 : null,
        gongPointValue: gongPointValue,
      );
    }).toList();
  }

  List<DropdownMenuItem<String?>> _disciplineItems() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Aucune épreuve TAR'),
      ),
    ];
    final referential = _tarReferential;
    if (referential == null) {
      final code = _selectedDisciplineCode;
      if (code != null) {
        items.add(DropdownMenuItem<String?>(
          value: code,
          child: Text('$code - chargement...'),
        ));
      }
      return items;
    }

    for (final code in const ['830', '831', '832']) {
      final discipline = referential.resolvedDisciplineByCode(code);
      if (discipline == null) continue;
      items.add(DropdownMenuItem<String?>(
        value: code,
        child: Text('$code - ${discipline.name}'),
      ));
    }
    final selectedCode = _selectedDisciplineCode;
    if (selectedCode != null &&
        !items.any((item) => item.value == selectedCode)) {
      items.add(DropdownMenuItem<String?>(
        value: selectedCode,
        child: Text('$selectedCode - epreuve inconnue'),
      ));
    }
    return items;
  }

  Series _buildSeries(int index) {
    final controller = _seriesControllers[index];
    controller.syncGongPoints();
    final shotCount = _readInt(controller.shotCountController.text) ?? 0;
    final distance = _readDouble(controller.distanceController.text) ?? 0;
    final groupSize = _readDouble(controller.groupSizeController.text) ?? 0;
    final gongsHit = controller.isGongScoring
        ? _readInt(controller.gongsHitController.text) ?? 0
        : controller.gongsHit;
    final points = controller.isGongScoring
        ? (gongsHit ?? 0) * controller.gongPointValue
        : _readInt(controller.pointsController.text) ?? 0;

    return Series(
      shotCount: shotCount,
      distance: distance,
      points: points,
      groupSize: groupSize,
      comment: controller.commentController.text.trim(),
      handMethod: controller.handMethod == 'one'
          ? HandMethod.oneHand
          : HandMethod.twoHands,
      sequenceType: controller.sequenceType,
      scoringMode: controller.scoringMode,
      targetType: controller.targetType,
      timeLimitLabel: controller.timeLimitLabel,
      timeLimitSeconds: controller.timeLimitSeconds,
      gongsHit: controller.isGongScoring ? gongsHit : null,
      gongPointValue: controller.gongPointValue,
    );
  }

  static TarSequenceType? _sequenceTypeFromValue(dynamic value) {
    if (value is TarSequenceType) return value;
    switch (value?.toString()) {
      case 'essai':
        return TarSequenceType.essai;
      case 'precision':
        return TarSequenceType.precision;
      case 'vitesse':
        return TarSequenceType.vitesse;
      default:
        return null;
    }
  }

  static SeriesScoringMode _scoringModeFromValue(dynamic value) {
    if (value is SeriesScoringMode) return value;
    switch (value?.toString()) {
      case 'gongs_tombes':
      case 'gongsTombes':
        return SeriesScoringMode.gongsTombes;
      case 'points_zone':
      case 'pointsZone':
      default:
        return SeriesScoringMode.pointsZone;
    }
  }

  static HandMethod _handMethodFromValue(dynamic value) {
    if (value is HandMethod) return value;
    return value?.toString() == 'one'
        ? HandMethod.oneHand
        : HandMethod.twoHands;
  }

  static HandMethod _handMethodFromStance(String stance) {
    final normalized = stance.toLowerCase();
    return normalized.contains('1 main') && !normalized.contains('1 ou 2')
        ? HandMethod.oneHand
        : HandMethod.twoHands;
  }

  static int? _timeLimitSeconds(String label) {
    final normalized = label.toLowerCase().replaceAll('×', 'x');
    final unit = normalized.contains('min') ? 'min' : 's';
    final matches = RegExp(r'(\d+)').allMatches(normalized).toList();
    if (matches.isEmpty) return null;
    final value = int.tryParse(matches.last.group(1) ?? '');
    if (value == null) return null;
    return unit == 'min' ? value * 60 : value;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }
    return null;
  }

  static String? _cleanString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  void initState() {
    super.initState();
    _weaponController = TextEditingController();
    _caliberController = TextEditingController();
    _selectedDisciplineCode = _initialDisciplineCode();
    _selectedDisciplineSeason = _initialDisciplineSeason();
    if (widget.initialSessionData != null) {
      final session = widget.initialSessionData!['session'];
      final seriesRaw = widget.initialSessionData!['series'];
      final List<dynamic> series = (seriesRaw is List) ? seriesRaw : [];
      _prefillInitialDisciplineWhenReady =
          !widget.isEdit && series.isEmpty && _selectedDisciplineCode != null;
      _date = session['date'] != null && session['date'] != ''
          ? DateTime.tryParse(session['date'])
          : null;
      _weaponController.text = session['weapon'] ?? '';
      final existingCal = (session['caliber'] as String?);
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
      _series = series.map(_seriesFormDataFromRaw).toList();
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
    _seriesControllers = _series.map(_controllersFromData).toList();
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
      if (_series[i].handMethod != HandMethod.twoHands) {
        _seriesControllers[i].handMethod = 'one';
        continue;
      }
      _seriesControllers[i].handMethod =
          defaultMethod == HandMethod.oneHand ? 'one' : 'two';
    }
    _lastCaliberText = _caliberController.text;
    _caliberFocus.addListener(() {
      if (_caliberFocus.hasFocus) {
        setState(() => _showAllCaliberOptions = true);
        final val = _caliberController.value;
        _caliberController.value =
            val.copyWith(text: val.text, selection: val.selection);
      } else {
        if (_showAllCaliberOptions) {
          setState(() => _showAllCaliberOptions = false);
        }
      }
    });
    // Load exercises asynchronously
    _loadExercises();
    _loadTarReferential();
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
    _caliberFocus.dispose();
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

  Future<void> _saveCurrentSetupFavorite() async {
    final weapon = _weaponController.text.trim();
    final caliber = canonicalizeCaliber(_caliberController.text);
    if (weapon.isEmpty && caliber.isEmpty && _selectedDisciplineCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Renseignez au moins une arme ou un calibre.')),
      );
      return;
    }

    final suggestedName =
        [weapon, caliber].where((v) => v.isNotEmpty).join(' - ');
    final nameController = TextEditingController(
      text: suggestedName.isEmpty ? 'Setup' : suggestedName,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nom du favori'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nom'),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, nameController.text),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    final cleanName = name?.trim();
    if (cleanName == null || cleanName.isEmpty) return;

    final setupSession = ShootingSession(
      weapon: weapon,
      caliber: caliber,
      series: const [],
      status: _status,
      category: _category,
      disciplineCode: _selectedDisciplineCode,
      disciplineSeason: _selectedDisciplineSeason,
    );
    await SessionTemplateService().saveFavoriteFromSession(
      setupSession,
      name: cleanName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Favori enregistré: $cleanName')),
    );
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
    final session = ShootingSession(
      id: existingId,
      date: _date,
      weapon: _weaponController.text,
      caliber: canonicalizeCaliber(_caliberController.text),
      status: _status,
      series: List.generate(_seriesControllers.length, _buildSeries),
      synthese: _syntheseController.text,
      category: _category,
      exercises: _selectedExerciseIds.toList(),
      photoPath: _photoPath,
      disciplineCode: _selectedDisciplineCode,
      disciplineSeason: _selectedDisciplineSeason,
    );
    widget.onSave(session);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = _seriesControllers.fold<int>(0, (a, c) {
      c.syncGongPoints();
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
                child: TextFormField(
                  controller: _weaponController,
                  decoration:
                      InputDecoration(labelText: 'Arme (optionnel si prévue)'),
                  validator: (v) {
                    if (_status == SessionConstants.statusPrevue) {
                      return null; // optional
                    }
                    if (v == null || v.isEmpty) return 'Requis';
                    return null;
                  },
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: RawAutocomplete<String>(
                  textEditingController: _caliberController,
                  focusNode: _caliberFocus,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final list = normalizedCaliberOptions();
                    if (_showAllCaliberOptions) return list;
                    final q = textEditingValue.text.trim();
                    if (q.isEmpty) return list; // show all when empty
                    return list.where(
                        (c) => c.toLowerCase().contains(q.toLowerCase()));
                  },
                  fieldViewBuilder: (context, ctrl, focus, onFieldSubmitted) {
                    return TextFormField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(labelText: 'Calibre'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                      onChanged: (txt) {
                        if (_showAllCaliberOptions) {
                          setState(() => _showAllCaliberOptions = false);
                        }
                        final wasDeletion =
                            txt.length < _lastCaliberText.length;
                        _lastCaliberText = txt;
                        if (wasDeletion) return;
                        final res = suggestFor(txt);
                        if (res.autoReplacement != null &&
                            ctrl.text != res.autoReplacement) {
                          ctrl.value = ctrl.value.copyWith(
                            text: res.autoReplacement,
                            selection: TextSelection.collapsed(
                                offset: res.autoReplacement!.length),
                          );
                          _lastCaliberText = res.autoReplacement!;
                        }
                      },
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                  onSelected: (value) {
                    _caliberController.text = canonicalizeCaliber(value);
                    _lastCaliberText = _caliberController.text;
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    final opts = options.toList();
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Theme.of(context).cardColor,
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: 220, minWidth: 220),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: opts.length,
                            itemBuilder: (context, index) {
                              final opt = opts[index];
                              return ListTile(
                                dense: true,
                                title: Text(opt),
                                onTap: () {
                                  if (opt == 'Autre') {
                                    final val = 'Autre : ';
                                    _caliberController.value = TextEditingValue(
                                        text: val,
                                        selection: TextSelection.collapsed(
                                            offset: val.length));
                                  } else {
                                    onSelected(opt);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _saveCurrentSetupFavorite,
              icon: const Icon(Icons.star_border),
              label: const Text('Favori'),
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _selectedDisciplineCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Épreuve TAR 25 m',
            ),
            items: _disciplineItems(),
            selectedItemBuilder: (context) => _disciplineItems()
                .map((item) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.value == null ? 'Aucune épreuve TAR' : item.value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: _onDisciplineChanged,
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: InputDecoration(labelText: 'Catégorie'),
            items: SessionConstants.categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                    handMethod: c.handMethod == 'one'
                        ? HandMethod.oneHand
                        : HandMethod.twoHands,
                    sequenceType: c.sequenceType,
                    scoringMode: c.scoringMode,
                    targetType: c.targetType,
                    timeLimitLabel: c.timeLimitLabel,
                    timeLimitSeconds: c.timeLimitSeconds,
                    gongsHit: int.tryParse(c.gongsHitController.text),
                    gongPointValue: c.gongPointValue,
                  );
                  _series.insert(i + 1, newData);
                  _seriesControllers.insert(
                      i + 1, _controllersFromData(newData));
                });
              },
              onChanged: () => setState(() {
                c.syncGongPoints();
              }),
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
