import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/services/server_wake_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(AppConfig.load);

  test('utilise GET /health depuis AppConfig sans donnée sensible', () async {
    late http.Request captured;
    final service = HttpServerWakeService.fromConfig(
      client: MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      }),
    );
    addTearDown(service.close);

    await service.wake();

    expect(captured.method, 'GET');
    expect(captured.url, Uri.parse('${AppConfig.I.authBaseUrl}/health'));
    expect(captured.url.query, isEmpty);
    expect(captured.bodyBytes, isEmpty);
    final headerNames = captured.headers.keys.map((key) => key.toLowerCase());
    expect(headerNames, isNot(contains('authorization')));
    expect(headerNames, isNot(contains('cookie')));
  });

  test('absorbe timeout, erreur réseau et réponse non 2xx', () async {
    final timeoutService = HttpServerWakeService(
      baseUrl: 'https://example.test',
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 1),
    );
    final networkService = HttpServerWakeService(
      baseUrl: 'https://example.test',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    final rejectedService = HttpServerWakeService(
      baseUrl: 'https://example.test',
      client: MockClient((_) async => http.Response('indisponible', 503)),
    );
    addTearDown(timeoutService.close);
    addTearDown(networkService.close);
    addTearDown(rejectedService.close);

    await expectLater(timeoutService.wake(), completes);
    await expectLater(networkService.wake(), completes);
    await expectLater(rejectedService.wake(), completes);
  });

  test('déduplique un appel en cours et les déclenchements rapprochés',
      () async {
    var now = DateTime(2026, 11, 16, 10);
    var requestCount = 0;
    var response = Completer<http.Response>();
    final service = HttpServerWakeService(
      baseUrl: 'https://example.test/',
      client: MockClient((_) {
        requestCount++;
        return response.future;
      }),
      cooldown: const Duration(minutes: 5),
      now: () => now,
    );
    addTearDown(service.close);

    final first = service.wake();
    await service.wake();
    await Future<void>.delayed(Duration.zero);
    expect(requestCount, 1);

    response.complete(http.Response('', 200));
    await first;
    await service.wake();
    expect(requestCount, 1);

    now = now.add(const Duration(minutes: 5, seconds: 1));
    response = Completer<http.Response>();
    final afterCooldown = service.wake();
    await Future<void>.delayed(Duration.zero);
    expect(requestCount, 2);
    response.complete(http.Response('', 200));
    await afterCooldown;
  });
}
