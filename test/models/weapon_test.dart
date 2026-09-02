import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/weapon.dart';

void main() {
  group('Weapon', () {
    test('toMap/fromMap round-trip conserve id, name et createdAt', () {
      final createdAt = DateTime(2026, 1, 15, 10, 30);
      final w = Weapon(id: 'w1', name: 'CZ 75 SP-01 Shadow', createdAt: createdAt);

      final map = w.toMap();
      final restored = Weapon.fromMap(map);

      expect(restored.id, 'w1');
      expect(restored.name, 'CZ 75 SP-01 Shadow');
      expect(restored.createdAt, createdAt);
    });

    test('fromMap tolère un createdAt absent ou invalide (valeur par défaut = maintenant)', () {
      final restored = Weapon.fromMap({'id': 'w2', 'name': 'Glock 17'});
      expect(restored.id, 'w2');
      expect(restored.name, 'Glock 17');
      expect(restored.createdAt, isNotNull);
    });

    test('copyWith ne modifie que le nom', () {
      final createdAt = DateTime(2026, 1, 1);
      final w = Weapon(id: 'w1', name: 'Glock 17', createdAt: createdAt);
      final renamed = w.copyWith(name: 'Glock 19');

      expect(renamed.id, w.id);
      expect(renamed.createdAt, w.createdAt);
      expect(renamed.name, 'Glock 19');
    });
  });
}
