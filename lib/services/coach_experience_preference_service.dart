import 'package:hive/hive.dart';

/// Persistance locale du niveau utilisé par les Coachs.
///
/// Le marqueur d'initialisation distingue une installation jamais migrée d'un
/// choix volontairement laissé vide. Le profil mis en cache n'est consulté
/// qu'une seule fois, pendant l'initialisation de l'application.
class CoachExperiencePreferenceService {
  static const levels = {'beginner', 'advanced', 'expert'};
  static const experienceLevelKey = 'coach_experience_level';
  static const initializedKey = 'coach_experience_level_initialized';

  final Box<dynamic> _preferencesBox;

  CoachExperiencePreferenceService(this._preferencesBox);

  String? get experienceLevel {
    final stored = _preferencesBox.get(experienceLevelKey);
    return stored is String && levels.contains(stored) ? stored : null;
  }

  bool get isInitialized =>
      _preferencesBox.get(initializedKey, defaultValue: false) == true;

  Future<void> updateExperienceLevel(String? level) async {
    if (level != null && !levels.contains(level)) {
      throw ArgumentError.value(level, 'level', 'Niveau non reconnu');
    }
    await _preferencesBox.putAll({
      experienceLevelKey: level,
      initializedKey: true,
    });
  }

  Future<void> initializeFromCachedProfile(
    Future<Map<String, dynamic>?> Function() readCachedProfile,
  ) async {
    if (isInitialized) return;
    final cachedProfile = await readCachedProfile();
    final cachedLevel = cachedProfile?['experience_level'];
    await updateExperienceLevel(
      cachedLevel is String && levels.contains(cachedLevel)
          ? cachedLevel
          : null,
    );
  }
}
