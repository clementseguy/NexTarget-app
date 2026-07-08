import 'package:hive/hive.dart';
import '../models/series.dart';

class PreferencesService {
  static const _boxName = 'app_preferences';
  static const _handMethodKey = 'default_hand_method';
  static const _defaultCaliberKey = 'default_caliber';
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
    await _box.put(_handMethodKey, method == HandMethod.oneHand ? 'one' : 'two');
  }

  String? getDefaultCaliber() {
    final v = _box.get(_defaultCaliberKey);
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  Future<void> setDefaultCaliber(String? caliber) async {
    if (caliber == null || caliber.trim().isEmpty) {
      await _box.delete(_defaultCaliberKey);
    } else {
      await _box.put(_defaultCaliberKey, caliber.trim());
    }
  }

  /// Onboarding vu au moins une fois (NT-075).
  bool isOnboardingSeen() {
    return _box.get(_onboardingSeenKey, defaultValue: false) == true;
  }

  Future<void> setOnboardingSeen(bool seen) async {
    await _box.put(_onboardingSeenKey, seen);
  }
}
