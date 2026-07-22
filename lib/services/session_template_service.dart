import '../constants/session_constants.dart';
import '../models/session_setup_template.dart';
import '../models/shooting_session.dart';
import 'preferences_service.dart';

class SessionTemplateService {
  final PreferencesService _preferences;

  SessionTemplateService({PreferencesService? preferences})
      : _preferences = preferences ?? PreferencesService();

  SessionSetupTemplate? getLastSetup() => _preferences.getLastSessionSetup();

  List<SessionSetupTemplate> getFavorites() =>
      _preferences.getSessionSetupFavorites();

  Future<void> recordLastSetup(ShootingSession session) async {
    final template = SessionSetupTemplate.fromSession(
      session,
      id: 'last_setup',
      name: 'Dernier setup',
    );
    if (!template.isUsable) return;
    await _preferences.setLastSessionSetup(template);
    await _preferences.setLastCaliber(template.caliber);
  }

  Future<SessionSetupTemplate> saveFavoriteFromSession(
    ShootingSession session, {
    required String name,
  }) async {
    final favorite = SessionSetupTemplate.fromSession(session, name: name);
    await _preferences.saveSessionSetupFavorite(favorite);
    return favorite;
  }

  Future<SessionSetupTemplate> saveFavoriteFromTemplate(
    SessionSetupTemplate template, {
    String? name,
  }) async {
    final favorite = template.copyWith(
      id: template.id == 'last_setup'
          ? 'setup_${DateTime.now().microsecondsSinceEpoch}'
          : template.id,
      name: name,
      updatedAt: DateTime.now(),
    );
    await _preferences.saveSessionSetupFavorite(favorite);
    return favorite;
  }

  Future<void> deleteFavorite(String id) =>
      _preferences.deleteSessionSetupFavorite(id);

  Map<String, dynamic> emptyInitialData({required bool planned}) {
    return {
      'session': {
        'weapon': '',
        'caliber': _preferences.getLastCaliber() ?? '',
        'status': planned
            ? SessionConstants.statusPrevue
            : SessionConstants.statusRealisee,
        'category': SessionConstants.categoryEntrainement,
        'series': [],
        'exercises': [],
      },
      'series': [],
    };
  }
}
