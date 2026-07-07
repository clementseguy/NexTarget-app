import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// AppConfig charge le fichier YAML `assets/config.yaml` et expose
/// quelques paramètres utiles avec valeurs de repli.
///
/// NT-061 : plus aucune clé ni configuration Mistral côté client —
/// l'analyse coach passe exclusivement par NexTarget-server.
class AppConfig {
  static AppConfig? _instance;
  final int splashMinDisplayMs;
  final int splashFadeDurationMs;
  final List<String> calibers;
  final bool authEnabled;
  final String authBaseUrl;
  final String authCallbackScheme;

  AppConfig._({
    required this.splashMinDisplayMs,
    required this.splashFadeDurationMs,
    required this.calibers,
    required this.authEnabled,
    required this.authBaseUrl,
    required this.authCallbackScheme,
  });

  static AppConfig get I {
    final inst = _instance;
    if (inst == null) {
      throw StateError('AppConfig not loaded yet. Call AppConfig.load() in main().');
    }
    return inst;
  }

  static Future<void> load({String path = 'assets/config.yaml'}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final yaml = loadYaml(raw);

      // Option: fichier local non versionné pour surcharges
      Map local = {};
      try {
        final localRaw = await rootBundle.loadString('assets/config.local.yaml');
        local = loadYaml(localRaw) as Map;
      } catch (_) {}

      int _readInt(dynamic value, int fallback) {
        if (value == null) return fallback;
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? fallback;
        return fallback;
      }
      final splash = yaml['splash'];
      final calibersYaml = (local['calibers'] ?? yaml['calibers']) as dynamic;
      final defaultCalibers = <String>[
        '.22 LR',
        '.32 S&W Long',
        '9mm (9x19)',
        '.38 Special',
        '.357 Magnum',
        '.380 ACP',
        '.40 S&W',
        '.45 ACP',
        'Autre',
      ];
      List<String> _readCalibers(dynamic val) {
        if (val == null) return defaultCalibers;
        if (val is Iterable) {
          return val.map((e) => e.toString()).toList();
        }
        return defaultCalibers;
      }

      final cfg = AppConfig._(
        splashMinDisplayMs: _readInt(splash?['min_display_ms'], 1500),
        splashFadeDurationMs: _readInt(splash?['fade_duration_ms'], 450),
        calibers: _readCalibers(calibersYaml),
        authEnabled: (yaml['auth']?['enabled'] ?? false) as bool,
        authBaseUrl: (yaml['auth']?['base_url'] ?? 'https://nextarget-server.onrender.com').toString(),
        authCallbackScheme: (yaml['auth']?['callback_scheme'] ?? 'nextarget').toString(),
      );
      _instance = cfg;
    } catch (e) {
      // En cas d'erreur, on installe une config par défaut.
      _instance = AppConfig._(
        splashMinDisplayMs: 1500,
        splashFadeDurationMs: 450,
        calibers: const [
          '.22 LR',
          '.32 S&W Long',
          '9mm (9x19)',
          '.38 Special',
          '.357 Magnum',
          '.380 ACP',
          '.40 S&W',
          '.45 ACP',
          'Autre',
        ],
        authEnabled: false,
        authBaseUrl: 'https://nextarget-server.onrender.com',
        authCallbackScheme: 'nextarget',
      );
    }
  }
}
