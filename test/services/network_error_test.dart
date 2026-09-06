import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tir_sportif/services/auth_session_exceptions.dart';
import 'package:tir_sportif/services/network_error.dart';

void main() {
  test('mappe toutes les familles avec leur action attendue', () {
    final cases = <Object, (NetworkErrorFamily, NetworkErrorAction)>{
      const SocketException('dns interne'): (
        NetworkErrorFamily.offline,
        NetworkErrorAction.retry,
      ),
      TimeoutException('détail timeout'): (
        NetworkErrorFamily.timeout,
        NetworkErrorAction.retry,
      ),
      NetworkOperationException(
        NetworkErrorFamily.serviceUnavailable,
        'HTTP 503 interne',
      ): (NetworkErrorFamily.serviceUnavailable, NetworkErrorAction.retry),
      NetworkOperationException(
        NetworkErrorFamily.rateLimited,
        'HTTP 429 interne',
      ): (NetworkErrorFamily.rateLimited, NetworkErrorAction.retry),
      SessionExpiredException('refresh révoqué'): (
        NetworkErrorFamily.sessionInvalid,
        NetworkErrorAction.reconnect,
      ),
      InvalidNetworkRequestException('HTTP 422 interne'): (
        NetworkErrorFamily.invalidRequest,
        NetworkErrorAction.none,
      ),
      StateError('secret interne'): (
        NetworkErrorFamily.unexpected,
        NetworkErrorAction.none,
      ),
      http.ClientException('hôte interne'): (
        NetworkErrorFamily.offline,
        NetworkErrorAction.retry,
      ),
    };

    for (final entry in cases.entries) {
      final presentation = presentNetworkError(entry.key);
      expect(presentation.family, entry.value.$1);
      expect(presentation.action, entry.value.$2);
      expect(presentation.message, isNot(contains('HTTP')));
      expect(presentation.message, isNot(contains('interne')));
      expect(presentation.message, isNot(contains('Exception')));
    }
  });

  test('réserve Réessayer aux erreurs transitoires', () {
    expect(
      presentNetworkError(const SocketException('dns')).actionLabel,
      'Réessayer',
    );
    expect(
      presentNetworkError(SessionExpiredException('révoqué')).actionLabel,
      'Se reconnecter',
    );
    expect(
      presentNetworkError(InvalidNetworkRequestException('422')).actionLabel,
      isNull,
    );
  });
}
