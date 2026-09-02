import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/models/weapon.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/services/dashboard_service.dart';

void main() {
  group('DashboardService.generateWeaponShotCounts (NT-017)', () {
    test('additionne les shotCount des sessions réalisées correspondantes, essais compris', () {
      final sessions = [
        ShootingSession(
          id: 1,
          date: DateTime(2026, 1, 1),
          weapon: '  CZ 75 SP-01 Shadow  ', // espaces de bord ignorés
          caliber: '9mm',
          status: SessionConstants.statusRealisee,
          series: List.generate(10, (_) => Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)),
        ),
        ShootingSession(
          id: 2,
          date: DateTime(2026, 1, 2),
          weapon: 'cz 75 sp-01 shadow', // casse différente
          caliber: '9mm',
          status: SessionConstants.statusRealisee,
          series: List.generate(10, (_) => Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)),
        ),
      ];
      final rack = [Weapon(id: 'w1', name: 'CZ 75 SP-01 Shadow', createdAt: DateTime(2026, 1, 1))];

      final counts = DashboardService(sessions).generateWeaponShotCounts(rack);

      expect(counts['w1'], 100);
    });

    test('exclut les sessions prévues', () {
      final sessions = [
        ShootingSession(
          id: 1,
          date: DateTime(2026, 1, 1),
          weapon: 'Glock 17',
          caliber: '9mm',
          status: SessionConstants.statusPrevue,
          series: [Series(distance: 25, points: 0, groupSize: 0, shotCount: 20)],
        ),
      ];
      final rack = [Weapon(id: 'w1', name: 'Glock 17', createdAt: DateTime(2026, 1, 1))];

      final counts = DashboardService(sessions).generateWeaponShotCounts(rack);

      expect(counts['w1'], 0);
    });

    test('une saisie seulement proche ne compte pas', () {
      final sessions = [
        ShootingSession(
          id: 1,
          date: DateTime(2026, 1, 1),
          weapon: 'CZ 09',
          caliber: '9mm',
          status: SessionConstants.statusRealisee,
          series: [Series(distance: 25, points: 45, groupSize: 5, shotCount: 5)],
        ),
      ];
      final rack = [Weapon(id: 'w1', name: 'CZ 75', createdAt: DateTime(2026, 1, 1))];

      final counts = DashboardService(sessions).generateWeaponShotCounts(rack);

      expect(counts['w1'], 0);
    });

    test('toutes les armes du râtelier apparaissent, y compris à zéro', () {
      final rack = [
        Weapon(id: 'w1', name: 'Glock 17', createdAt: DateTime(2026, 1, 1)),
        Weapon(id: 'w2', name: 'CZ 75', createdAt: DateTime(2026, 1, 1)),
      ];

      final counts = DashboardService(const []).generateWeaponShotCounts(rack);

      expect(counts.keys.toSet(), {'w1', 'w2'});
      expect(counts['w1'], 0);
      expect(counts['w2'], 0);
    });
  });
}
