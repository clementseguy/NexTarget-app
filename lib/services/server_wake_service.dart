import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'logger.dart';

abstract interface class ServerWakeService {
  Future<void> wake();

  void close();
}

/// Réveille le serveur en best effort, sans authentification ni donnée métier.
class HttpServerWakeService implements ServerWakeService {
  static const defaultTimeout = Duration(seconds: 5);
  static const defaultCooldown = Duration(seconds: 30);

  final String _baseUrl;
  final http.Client _client;
  final Duration _timeout;
  final Duration _cooldown;
  final DateTime Function() _now;

  DateTime? _lastAttemptAt;
  Future<void>? _inFlight;

  HttpServerWakeService({
    required String baseUrl,
    http.Client? client,
    Duration timeout = defaultTimeout,
    Duration cooldown = defaultCooldown,
    DateTime Function()? now,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _client = client ?? http.Client(),
        _timeout = timeout,
        _cooldown = cooldown,
        _now = now ?? DateTime.now;

  factory HttpServerWakeService.fromConfig({
    http.Client? client,
    Duration timeout = defaultTimeout,
    Duration cooldown = defaultCooldown,
    DateTime Function()? now,
  }) =>
      HttpServerWakeService(
        baseUrl: AppConfig.I.authBaseUrl,
        client: client,
        timeout: timeout,
        cooldown: cooldown,
        now: now,
      );

  @override
  Future<void> wake() {
    final inFlight = _inFlight;
    if (inFlight != null) return Future<void>.value();

    final now = _now();
    final lastAttemptAt = _lastAttemptAt;
    if (lastAttemptAt != null && now.difference(lastAttemptAt) < _cooldown) {
      return Future<void>.value();
    }

    _lastAttemptAt = now;
    final attempt = _sendHealthRequest();
    _inFlight = attempt;
    unawaited(
      attempt.whenComplete(() {
        if (identical(_inFlight, attempt)) _inFlight = null;
      }),
    );
    return attempt;
  }

  Future<void> _sendHealthRequest() async {
    try {
      final response =
          await _client.get(Uri.parse('$_baseUrl/health')).timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        AppLogger.I.debug(
          'SERVER_WAKE: réponse HTTP ${response.statusCode} ignorée',
        );
      }
    } on TimeoutException catch (error) {
      AppLogger.I.debug('SERVER_WAKE: délai dépassé: $error');
    } catch (error, stackTrace) {
      AppLogger.I.error('SERVER_WAKE: réveil impossible', error, stackTrace);
    }
  }

  @override
  void close() => _client.close();

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
