import 'package:flutter_test/flutter_test.dart';
import 'async_test_helpers.dart';

void main() {
  group('captureError', () {
    test('retourne null quand aucune exception n\'est levée', () async {
      final error = await captureError(() async {});
      expect(error, isNull);
    });

    test('retourne l\'exception levée par une fonction async', () async {
      final error = await captureError(() async => throw StateError('boom'));
      expect(error, isA<StateError>());
    });
  });
}
