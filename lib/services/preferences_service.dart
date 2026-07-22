import 'package:hive/hive.dart';
import '../models/session_setup_template.dart';
import '../models/series.dart';
import '../utils/caliber_autocomplete.dart';

class PreferencesService {
  static const _boxName = 'app_preferences';
  static const _handMethodKey = 'default_hand_method';
  static const _defaultCaliberKey = 'default_caliber';
  static const _lastSessionSetupKey = 'last_session_setup';
  static const _sessionSetupFavoritesKey = 'session_setup_favorites';
  static const _onboardingSeenKey = 'onboarding_seen';
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Box<dynamic> get _box => Hive.box(_boxName);

  HandMethod getDefaultHandMethod() {
    final v = _box.get(_handMethodKey, defaultValue: 'two');
    return v == 'one' ? HandMethod.oneHand : HandMethod.twoHands;
  }

  Future<void> setDefaultHandMethod(HandMethod method) async {
    await _box.put(
        _handMethodKey, method == HandMethod.oneHand ? 'one' : 'two');
  }

  String? getDefaultCaliber() {
    return getLastCaliber();
  }

  Future<void> setDefaultCaliber(String? caliber) async {
    await setLastCaliber(caliber);
  }

  String? getLastCaliber() {
    final v = _box.get(_defaultCaliberKey);
    if (v is String && v.trim().isNotEmpty) return canonicalizeCaliber(v);
    return null;
  }

  Future<void> setLastCaliber(String? caliber) async {
    final canonical = canonicalizeCaliber(caliber);
    if (canonical.isEmpty) {
      await _box.delete(_defaultCaliberKey);
    } else {
      await _box.put(_defaultCaliberKey, canonical);
    }
  }

  SessionSetupTemplate? getLastSessionSetup() {
    final raw = _box.get(_lastSessionSetupKey);
    if (raw is Map) return SessionSetupTemplate.fromMap(raw);
    return null;
  }

  Future<void> setLastSessionSetup(SessionSetupTemplate? template) async {
    if (template == null || !template.isUsable) {
      await _box.delete(_lastSessionSetupKey);
      return;
    }
    await _box.put(_lastSessionSetupKey, template.toMap());
  }

  List<SessionSetupTemplate> getSessionSetupFavorites() {
    final raw = _box.get(_sessionSetupFavoritesKey);
    if (raw is! List) return const [];
    final favorites = <SessionSetupTemplate>[];
    for (final item in raw) {
      if (item is Map) {
        final template = SessionSetupTemplate.fromMap(item);
        if (template.isUsable) favorites.add(template);
      }
    }
    favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return favorites;
  }

  Future<void> saveSessionSetupFavorite(SessionSetupTemplate template) async {
    if (!template.isUsable) return;
    final favorites = getSessionSetupFavorites();
    final next = <SessionSetupTemplate>[
      template.copyWith(updatedAt: DateTime.now()),
      ...favorites.where((favorite) => favorite.id != template.id),
    ];
    await _box.put(
      _sessionSetupFavoritesKey,
      next.take(10).map((favorite) => favorite.toMap()).toList(),
    );
  }

  Future<void> deleteSessionSetupFavorite(String id) async {
    final next = getSessionSetupFavorites()
        .where((favorite) => favorite.id != id)
        .map((favorite) => favorite.toMap())
        .toList();
    await _box.put(_sessionSetupFavoritesKey, next);
  }

  /// Onboarding vu au moins une fois (NT-075).
  bool isOnboardingSeen() {
    return _box.get(_onboardingSeenKey, defaultValue: false) == true;
  }

  Future<void> setOnboardingSeen(bool seen) async {
    await _box.put(_onboardingSeenKey, seen);
  }
}
