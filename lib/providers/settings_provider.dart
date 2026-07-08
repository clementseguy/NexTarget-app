import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/backup_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

/// Provider pour gérer l'état de l'écran des paramètres
class SettingsProvider extends ChangeNotifier {
  final BackupService _backupService;
  final SessionService _sessionService;
  final Box _preferencesBox;
  
  SettingsProvider({
    BackupService? backupService,
    SessionService? sessionService,
    Box? preferencesBox,
  }) : 
    _backupService = backupService ?? BackupService(),
    _sessionService = sessionService ?? SessionService(),
    _preferencesBox = preferencesBox ?? Hive.box('app_preferences');
    
  // Getters pour les préférences
  String get defaultHandMethod => 
      _preferencesBox.get('default_hand_method', defaultValue: 'two');
      
  String? get defaultCaliber => 
      _preferencesBox.get('default_caliber');

  // Persona du coach IA (NT-032) : 'coach_neutre' ou 'coach_cool'.
  // Valeur = prompt_variant envoyé au serveur (POST /coach/analyze-session).
  static const coachPersonas = ['coach_neutre', 'coach_cool'];

  String get coachPersona {
    final stored = _preferencesBox.get('coach_persona', defaultValue: 'coach_neutre');
    return coachPersonas.contains(stored) ? stored : 'coach_neutre';
  }

  Future<void> updateCoachPersona(String persona) async {
    if (!coachPersonas.contains(persona)) return;
    await _preferencesBox.put('coach_persona', persona);
    notifyListeners();
  }

  // Thème
  AppThemeType get themeType {
    final stored = _preferencesBox.get('app_theme', defaultValue: 'classique');
    return AppThemeType.values.firstWhere(
      (t) => t.name == stored,
      orElse: () => AppThemeType.classique,
    );
  }

  Future<void> updateTheme(AppThemeType type) async {
    await _preferencesBox.put('app_theme', type.name);
    notifyListeners();
  }
  
  // Méthodes pour mettre à jour les préférences
  Future<void> updateDefaultHandMethod(String value) async {
    await _preferencesBox.put('default_hand_method', value);
    notifyListeners();
  }
  
  Future<void> updateDefaultCaliber(String value) async {
    if (value.isEmpty) {
      await _preferencesBox.delete('default_caliber');
    } else {
      await _preferencesBox.put('default_caliber', value);
    }
    notifyListeners();
  }
  
  // Méthodes pour l'exportation et l'importation
  Future<void> exportToJson(Function(String) onSuccess, Function(String) onError) async {
    try {
      final file = await _backupService.exportAllSessionsToJsonFile();
      onSuccess('Fichier exporté: ${file.path}');
    } catch (e) {
      onError('Erreur export: $e');
    }
  }
  
  Future<void> exportToFolder(Function(String?) onSuccess, Function(String) onError) async {
    try {
      final file = await _backupService.exportAllSessionsToUserFolder();
      if (file == null) {
        onSuccess(null); // Export annulé
      } else {
        onSuccess(file.path);
      }
    } catch (e) {
      onError('Erreur sauvegarde: $e');
    }
  }
  
  Future<void> importFromJson(String path, Function(String) onSuccess, Function(String) onError) async {
    try {
      final content = await _backupService.readJsonFile(path);
      final imported = await _backupService.importSessionsFromJson(content);
      final total = (await _sessionService.getAllSessions()).length;
      onSuccess('$imported sessions importées. Total: $total');
    } catch (e) {
      onError('Erreur import: $e');
    }
  }
}