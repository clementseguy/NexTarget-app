import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/screens/home_screen.dart';
import 'package:tir_sportif/services/server_wake_service.dart';
import 'package:tir_sportif/services/session_service.dart';

import '../support/fake_session_repository.dart';

class _PendingServerWakeService implements ServerWakeService {
  final pending = Completer<void>();
  int calls = 0;

  @override
  Future<void> wake() {
    calls++;
    return pending.future;
  }

  @override
  void close() {}
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nt173_home_');
    Hive.init(directory.path);
    await Hive.openBox('weapons');
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets('réveille après affichage de l’accueil sans attendre la réponse',
      (tester) async {
    final wakeService = _PendingServerWakeService();
    addTearDown(() {
      if (!wakeService.pending.isCompleted) wakeService.pending.complete();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          sessionService: SessionService(
            repository: FakeSessionRepository(),
          ),
          serverWakeService: wakeService,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Synthèse'), findsWidgets);
    expect(wakeService.calls, 1);
    expect(wakeService.pending.isCompleted, isFalse);
    expect(tester.takeException(), isNull);
  });
}
