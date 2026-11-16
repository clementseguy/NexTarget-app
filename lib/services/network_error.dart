import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_session_exceptions.dart';

enum NetworkErrorFamily {
  offline,
  timeout,
  serviceUnavailable,
  rateLimited,
  sessionInvalid,
  invalidRequest,
  unexpected,
}

enum NetworkErrorAction { retry, reconnect, none }

class NetworkOperationException extends NetworkUnavailableException {
  final NetworkErrorFamily family;

  NetworkOperationException(this.family, String technicalMessage)
      : super(technicalMessage);
}

class InvalidNetworkRequestException implements Exception {
  final String technicalMessage;

  InvalidNetworkRequestException(this.technicalMessage);
}

class NetworkErrorPresentation {
  final NetworkErrorFamily family;
  final String message;
  final NetworkErrorAction action;

  const NetworkErrorPresentation({
    required this.family,
    required this.message,
    required this.action,
  });

  String? get actionLabel => switch (action) {
        NetworkErrorAction.retry => 'Réessayer',
        NetworkErrorAction.reconnect => 'Se reconnecter',
        NetworkErrorAction.none => null,
      };
}

NetworkErrorPresentation presentNetworkError(Object error) {
  if (error is SessionExpiredException) {
    return const NetworkErrorPresentation(
      family: NetworkErrorFamily.sessionInvalid,
      message: 'Votre session a expiré. Reconnectez-vous pour continuer.',
      action: NetworkErrorAction.reconnect,
    );
  }
  if (error is InvalidNetworkRequestException) {
    return const NetworkErrorPresentation(
      family: NetworkErrorFamily.invalidRequest,
      message: 'Certaines informations sont invalides. Vérifiez votre saisie.',
      action: NetworkErrorAction.none,
    );
  }
  final family = _networkFamily(error);
  return switch (family) {
    NetworkErrorFamily.offline => const NetworkErrorPresentation(
        family: NetworkErrorFamily.offline,
        message: 'Aucune connexion disponible. Vérifiez votre réseau.',
        action: NetworkErrorAction.retry,
      ),
    NetworkErrorFamily.timeout => const NetworkErrorPresentation(
        family: NetworkErrorFamily.timeout,
        message: 'Le service met trop de temps à répondre.',
        action: NetworkErrorAction.retry,
      ),
    NetworkErrorFamily.serviceUnavailable => const NetworkErrorPresentation(
        family: NetworkErrorFamily.serviceUnavailable,
        message: 'Le service est temporairement indisponible.',
        action: NetworkErrorAction.retry,
      ),
    NetworkErrorFamily.rateLimited => const NetworkErrorPresentation(
        family: NetworkErrorFamily.rateLimited,
        message: 'Trop de demandes ont été envoyées. Réessayez plus tard.',
        action: NetworkErrorAction.retry,
      ),
    _ => const NetworkErrorPresentation(
        family: NetworkErrorFamily.unexpected,
        message: 'Une erreur inattendue est survenue.',
        action: NetworkErrorAction.none,
      ),
  };
}

NetworkErrorFamily _networkFamily(Object error) {
  if (error is NetworkOperationException) return error.family;
  if (error is TimeoutException) return NetworkErrorFamily.timeout;
  if (error is SocketException ||
      error is http.ClientException ||
      error is NetworkUnavailableException) {
    return NetworkErrorFamily.offline;
  }
  return NetworkErrorFamily.unexpected;
}
