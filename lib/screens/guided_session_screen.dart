import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/exercise.dart';
import '../models/series.dart';
import '../models/shooting_session.dart';
import '../services/exercise_service.dart';
import '../services/session_photo_service.dart';
import '../services/session_service.dart';
import '../interfaces/session_photo_service_interface.dart';
import '../widgets/session_form/session_form_components.dart';
import 'session_detail_screen.dart';

class GuidedSessionScreen extends StatefulWidget {
  final DetailedShootingSession draft;
  final SessionService? sessionService;
  final ExerciseService? exerciseService;
  final ISessionPhotoService? photoService;
  final Future<void> Function()? onSessionChanged;

  const GuidedSessionScreen({
    super.key,
    required this.draft,
    this.sessionService,
    this.exerciseService,
    this.photoService,
    this.onSessionChanged,
  });

  @override
  State<GuidedSessionScreen> createState() => _GuidedSessionScreenState();
}

class _GuidedSessionScreenState extends State<GuidedSessionScreen> {
  static const _autosaveDelay = Duration(milliseconds: 600);

  late final SessionService _sessionService =
      widget.sessionService ?? SessionService();
  late final ExerciseService _exerciseService =
      widget.exerciseService ?? ExerciseService();
  late final ISessionPhotoService _photoService =
      widget.photoService ?? SessionPhotoService();
  late DetailedShootingSession _draft;
  late int _currentIndex;
  bool _showSummary = false;
  bool _saving = false;
  bool _allowPop = false;
  bool _leaving = false;
  bool _photoBusy = false;
  String? _persistenceError;
  Timer? _autosaveTimer;
  Future<void> _saveQueue = Future<void>.value();
  List<Exercise> _exercises = const [];

  late TextEditingController _shotsController;
  late TextEditingController _distanceController;
  late TextEditingController _pointsController;
  late TextEditingController _groupController;
  late TextEditingController _commentController;
  late TextEditingController _summaryController;
  final _shotsFocus = FocusNode();
  final _distanceFocus = FocusNode();
  final _pointsFocus = FocusNode();
  final _groupFocus = FocusNode();
  final _commentFocus = FocusNode();
  HandMethod _handMethod = HandMethod.twoHands;

  bool get _mutationsLocked => _saving || _leaving;

  @override
  void initState() {
    super.initState();
    _draft = DetailedShootingSession.fromMap(widget.draft.toMap());
    final firstIncomplete =
        _draft.series.indexWhere((item) => !item.isCompleted);
    _currentIndex = firstIncomplete == -1
        ? (_draft.series.isEmpty ? 0 : _draft.series.length - 1)
        : firstIncomplete;
    _summaryController = TextEditingController(text: _draft.synthese ?? '');
    _createSeriesControllers();
    _bindCurrentSeries();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.listAll();
      if (mounted) setState(() => _exercises = exercises);
    } catch (_) {
      // Les identifiants restent visibles si le catalogue est indisponible.
    }
  }

  void _createSeriesControllers() {
    _shotsController = TextEditingController();
    _distanceController = TextEditingController();
    _pointsController = TextEditingController();
    _groupController = TextEditingController();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _shotsController.dispose();
    _distanceController.dispose();
    _pointsController.dispose();
    _groupController.dispose();
    _commentController.dispose();
    _summaryController.dispose();
    _shotsFocus.dispose();
    _distanceFocus.dispose();
    _pointsFocus.dispose();
    _groupFocus.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Series get _currentSeries => _draft.series[_currentIndex];

  void _bindCurrentSeries() {
    if (_draft.series.isEmpty) return;
    final series = _currentSeries;
    if (!series.isDraftStarted && _currentIndex > 0) {
      final previous = _draft.series[_currentIndex - 1];
      series.distance = previous.distance;
      series.handMethod = previous.handMethod;
    }
    _shotsController.text = series.shotCount > 0 ? '${series.shotCount}' : '';
    _distanceController.text =
        series.distance > 0 ? series.distance.toStringAsFixed(0) : '';
    _pointsController.text = series.isScoreEntered ? '${series.points}' : '';
    _groupController.text = series.groupSize > 0
        ? series.groupSize.toString().replaceFirst(RegExp(r'\.0$'), '')
        : '';
    _commentController.text = series.comment;
    _handMethod = series.handMethod;
  }

  double? _parseGroup(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  bool get _currentHasInput =>
      _currentSeries.isDraftStarted ||
      _pointsController.text.trim().isNotEmpty ||
      _groupController.text.trim().isNotEmpty ||
      _commentController.text.trim().isNotEmpty;

  Series _seriesFromFields({required bool completed}) => Series(
        id: _currentSeries.id,
        shotCount: int.tryParse(_shotsController.text.trim()) ?? 0,
        distance: double.tryParse(_distanceController.text.trim()) ?? 0,
        points: int.tryParse(_pointsController.text.trim()) ?? 0,
        groupSize: _parseGroup(_groupController.text) ?? 0,
        comment: _commentController.text.trim(),
        handMethod: _handMethod,
        isCompleted: completed,
        isDraftStarted: true,
        isScoreEntered: _pointsController.text.trim().isNotEmpty,
      );

  String? _validationMessage() {
    final shots = int.tryParse(_shotsController.text.trim());
    if (shots == null || shots <= 0) {
      return 'Le nombre de coups doit être un entier strictement positif.';
    }
    final distance = int.tryParse(_distanceController.text.trim());
    if (distance == null || distance <= 0) {
      return 'La distance doit être un entier strictement positif.';
    }
    final points = int.tryParse(_pointsController.text.trim());
    if (points == null || points < 0) {
      return 'Le score est obligatoire et ne peut pas être négatif.';
    }
    final group = _parseGroup(_groupController.text);
    if (group == null || group <= 0) {
      return 'Le groupement doit être strictement positif.';
    }
    return null;
  }

  void _onFieldChanged() {
    if (_mutationsLocked) return;
    _draft.series[_currentIndex] = _seriesFromFields(completed: false);
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () {
      _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()))
          .catchError((_) {});
    });
    setState(() => _persistenceError = null);
  }

  Future<void> _enqueueSave(DetailedShootingSession snapshot) {
    final completer = Completer<void>();
    _saveQueue = _saveQueue.catchError((_) {}).then((_) async {
      try {
        await _sessionService.saveGuidedDraft(snapshot);
        if (mounted) setState(() => _persistenceError = null);
        completer.complete();
      } catch (error, stackTrace) {
        if (mounted) {
          setState(() {
            _persistenceError = 'Sauvegarde locale impossible : $error';
          });
        }
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<bool> _saveCurrent({required bool validate}) async {
    _autosaveTimer?.cancel();
    if (validate) {
      final message = _validationMessage();
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return false;
      }
    }
    if (_currentHasInput || validate || _currentSeries.isCompleted) {
      _draft.series[_currentIndex] =
          _seriesFromFields(completed: validate || _currentSeries.isCompleted);
    }
    try {
      await _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _previous() async {
    if (_mutationsLocked || _currentIndex == 0) return;
    if (!await _saveCurrent(validate: false) || !mounted) return;
    setState(() {
      _currentIndex--;
      _bindCurrentSeries();
    });
  }

  Future<void> _next() async {
    if (_mutationsLocked) return;
    if (!await _saveCurrent(validate: true) || !mounted) return;
    if (_currentIndex == _draft.series.length - 1) {
      if (_draft.series.any((item) => !item.isCompleted)) {
        await _finishEarly();
        return;
      }
      setState(() => _showSummary = true);
      return;
    }
    setState(() {
      _currentIndex++;
      _bindCurrentSeries();
    });
  }

  Future<void> _addSeries() async {
    if (_mutationsLocked) return;
    if (_showSummary) {
      _draft.synthese = _summaryController.text.trim();
    }
    final shouldCompleteCurrent =
        _currentHasInput || _currentSeries.isCompleted;
    if (!await _saveCurrent(validate: shouldCompleteCurrent) || !mounted) {
      return;
    }
    final base = _currentSeries;
    _draft.series.add(
      Series(
        shotCount: base.shotCount > 0 ? base.shotCount : 5,
        distance: base.distance > 0 ? base.distance : 25,
        points: 0,
        groupSize: 0,
        handMethod: base.handMethod,
        isCompleted: false,
        isDraftStarted: false,
        isScoreEntered: false,
      ),
    );
    try {
      await _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()));
      if (!mounted) return;
      setState(() {
        _currentIndex = _draft.series.length - 1;
        _showSummary = false;
        _bindCurrentSeries();
      });
    } catch (_) {}
  }

  Future<void> _finishEarly() async {
    if (_mutationsLocked) return;
    if (_currentHasInput && !_currentSeries.isCompleted) {
      if (!await _saveCurrent(validate: true) || !mounted) return;
    } else if (!await _saveCurrent(validate: false) || !mounted) {
      return;
    }
    final completed = _draft.series.where((item) => item.isCompleted).length;
    if (completed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrez au moins une série.')),
      );
      return;
    }
    final removed = _draft.series.length - completed;
    if (removed == 0) {
      setState(() => _showSummary = true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminer plus tôt ?'),
        content: Text(
          '$removed série${removed > 1 ? 's' : ''} non renseignée${removed > 1 ? 's' : ''} '
          '${removed > 1 ? 'seront retirées' : 'sera retirée'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _draft.series =
        _draft.series.where((item) => item.isCompleted).toList(growable: true);
    try {
      await _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()));
      if (mounted) setState(() => _showSummary = true);
    } catch (_) {}
  }

  Future<void> _leave() async {
    if (_mutationsLocked) return;
    _leaving = true;
    if (_showSummary) {
      _draft.synthese = _summaryController.text.trim();
    }
    if (!await _saveCurrent(validate: false)) {
      _leaving = false;
      return;
    }
    await _notifySessionChanged();
    await _popScreen();
  }

  Future<void> _popScreen() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _notifySessionChanged() async {
    try {
      await widget.onSessionChanged?.call();
    } catch (_) {
      // La synchronisation de la liste ne doit pas remettre en cause une
      // opération de persistance déjà réussie localement.
    }
  }

  void _onSummaryChanged(String value) {
    if (_mutationsLocked) return;
    _draft.synthese = value.trim();
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(_autosaveDelay, () {
      _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()))
          .catchError((_) {});
    });
  }

  Future<void> _abandon() async {
    if (_mutationsLocked) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abandonner la séance ?'),
        content: const Text(
          'Le brouillon et les séries enregistrées seront supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _leaving = true;
    _autosaveTimer?.cancel();
    await _saveQueue.catchError((_) {});
    try {
      await _sessionService.abandonGuidedDraft(_draft);
      await _notifySessionChanged();
      await _popScreen();
    } catch (error) {
      if (!mounted) return;
      _leaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’abandonner la séance : $error')),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_mutationsLocked || _photoBusy) return;
    setState(() => _photoBusy = true);
    final previousPath = _draft.photoPath;
    try {
      final path = await _photoService.pickAndStore(source);
      if (path == null) return;
      _draft.photoPath = path;
      await _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()));
    } catch (_) {
      if (_draft.photoPath != previousPath) {
        await _photoService.deleteIfExists(_draft.photoPath);
      }
      _draft.photoPath = previousPath;
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_mutationsLocked || _photoBusy) return;
    final previousPath = _draft.photoPath;
    _draft.photoPath = null;
    try {
      await _enqueueSave(DetailedShootingSession.fromMap(_draft.toMap()));
    } catch (_) {
      _draft.photoPath = previousPath;
    }
  }

  Future<void> _complete() async {
    if (_mutationsLocked || _photoBusy) return;
    setState(() => _saving = true);
    FocusScope.of(context).unfocus();
    _autosaveTimer?.cancel();
    await _saveQueue.catchError((_) {});
    _draft.synthese = _summaryController.text.trim();
    try {
      final savedDraft = await _sessionService.saveGuidedDraft(_draft);
      final realized = await _sessionService.completeGuidedDraft(savedDraft);
      await _notifySessionChanged();
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(
            sessionData: {
              'session': realized.toMap(),
              'series': realized.series.map((item) => item.toMap()).toList(),
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La séance n’a pas pu être terminée. Le brouillon est conservé : $error',
          ),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_leaving) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showSummary
              ? 'Synthèse de la séance'
              : 'Série ${_currentIndex + 1} / ${_draft.series.length}'),
          leading: IconButton(
            tooltip: 'Quitter temporairement',
            onPressed: _mutationsLocked ? null : _leave,
            icon: const Icon(Icons.close),
          ),
          actions: [
            IconButton(
              tooltip: 'Ajouter une série',
              onPressed: _mutationsLocked ? null : _addSeries,
              icon: const Icon(Icons.playlist_add),
            ),
            PopupMenuButton<String>(
              tooltip: 'Actions de la séance',
              enabled: !_mutationsLocked,
              onSelected: (value) {
                if (value == 'early') _finishEarly();
                if (value == 'abandon') _abandon();
              },
              itemBuilder: (_) => [
                if (!_showSummary)
                  const PopupMenuItem(
                    value: 'early',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined),
                      title: Text('Terminer plus tôt'),
                    ),
                  ),
                const PopupMenuItem(
                  value: 'abandon',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Abandonner'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _mutationsLocked,
          child: _showSummary ? _buildSummary() : _buildSeries(),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final completed = _draft.completedSeriesCount;
    final shots = _draft.completedShotCount;
    final plannedShots = _draft.series.fold<int>(
      0,
      (total, item) => total + item.shotCount,
    );
    final remaining = (plannedShots - shots).clamp(0, plannedShots);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Text('$completed / ${_draft.series.length} séries enregistrées'),
            Text('$shots coups enregistrés'),
            Text('$remaining coups restants'),
          ],
        ),
      ),
    );
  }

  Widget _buildSeries() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildProgress(),
        if (_persistenceError != null)
          MaterialBanner(
            content: Text(_persistenceError!),
            actions: [
              TextButton(
                onPressed: () => _saveCurrent(validate: false),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('guided_shots'),
                controller: _shotsController,
                focusNode: _shotsFocus,
                decoration: const InputDecoration(labelText: 'Nombre de coups'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _onFieldChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    key: const Key('guided_distance'),
                    controller: _distanceController,
                    focusNode: _distanceFocus,
                    decoration:
                        const InputDecoration(labelText: 'Distance (m)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.social_distance, size: 18),
                        label: const Text('15 m'),
                        onPressed: () {
                          _distanceController.text = '15';
                          _onFieldChanged();
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.social_distance, size: 18),
                        label: const Text('25 m'),
                        onPressed: () {
                          _distanceController.text = '25';
                          _onFieldChanged();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('guided_points'),
                controller: _pointsController,
                focusNode: _pointsFocus,
                decoration: const InputDecoration(labelText: 'Points ou score'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => _onFieldChanged(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('guided_group'),
                controller: _groupController,
                focusNode: _groupFocus,
                decoration: const InputDecoration(labelText: 'Groupement (cm)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                onChanged: (_) => _onFieldChanged(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Prise', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
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
            _onFieldChanged();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('guided_comment'),
          controller: _commentController,
          focusNode: _commentFocus,
          decoration: const InputDecoration(
            labelText: 'Commentaire (facultatif)',
            helperText: 'Recommandé pour améliorer l’analyse du Coach',
            alignLabelWithHint: true,
          ),
          minLines: 2,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: true,
          enableSuggestions: true,
          onChanged: (_) => _onFieldChanged(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (_currentIndex > 0)
              OutlinedButton.icon(
                key: const Key('guided_previous'),
                onPressed: _previous,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédente'),
              ),
            const Spacer(),
            FilledButton.icon(
              key: const Key('guided_next'),
              onPressed: _next,
              icon: Icon(_currentIndex == _draft.series.length - 1
                  ? Icons.summarize_outlined
                  : Icons.arrow_forward),
              label: Text(_currentIndex == _draft.series.length - 1
                  ? 'Récapitulatif'
                  : 'Suivante'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final completed = _draft.series.where((item) => item.isCompleted).toList();
    final shots =
        completed.fold<int>(0, (total, item) => total + item.shotCount);
    final points = completed.fold<int>(0, (total, item) => total + item.points);
    final distances =
        completed.map((item) => item.distance.toInt()).toSet().toList()..sort();
    final exerciseNames = _draft.exercises.map((id) {
      final match = _exercises.where((item) => item.id == id);
      return match.isEmpty ? id : match.first.name;
    }).join(', ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Récapitulatif',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('Arme : ${_draft.weapon}'),
                Text('Calibre : ${_draft.caliber}'),
                Text('Catégorie : ${_draft.category}'),
                Text(
                    'Exercices : ${exerciseNames.isEmpty ? 'Aucun' : exerciseNames}'),
                Text('Séries réalisées : ${completed.length}'),
                Text('Total des coups : $shots'),
                Text(
                    'Distances : ${distances.map((item) => '$item m').join(', ')}'),
                Text('Total des points : $points'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('guided_summary'),
          controller: _summaryController,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: true,
          enableSuggestions: true,
          decoration: const InputDecoration(
            labelText: 'Synthèse (facultative)',
            hintText: 'Ressentis, observations, axes d’amélioration...',
            alignLabelWithHint: true,
          ),
          onChanged: _onSummaryChanged,
        ),
        const SizedBox(height: 16),
        SessionPhotoField(
          photoPath: _draft.photoPath,
          isBusy: _photoBusy,
          onPickFromGallery: () => _pickPhoto(ImageSource.gallery),
          onPickFromCamera: () => _pickPhoto(ImageSource.camera),
          onRemove: _removePhoto,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _showSummary = false;
                _currentIndex = _draft.series.length - 1;
                _bindCurrentSeries();
              }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Corriger'),
            ),
            const Spacer(),
            FilledButton.icon(
              key: const Key('complete_guided_session'),
              onPressed: _saving || _photoBusy ? null : _complete,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Terminer la séance'),
            ),
          ],
        ),
      ],
    );
  }
}
