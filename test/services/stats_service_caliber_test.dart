import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/stats_service.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  ShootingSession session(String caliber, int points) => ShootingSession(
        date: DateTime(2026, 8, 20),
        weapon: 'Pistolet',
        caliber: caliber,
        status: SessionConstants.statusRealisee,
        category: SessionConstants.categoryEntrainement,
        series: [
          Series(
            points: points,
            groupSize: 10,
            distance: 25,
            shotCount: 5,
          ),
        ],
      );

  test('regroupe les alias connus et exclut les inconnus de cette seule vue', () {
    final stats = StatsService(
      [
        session('9mm', 40),
        session('9 mm Para', 50),
        session('.380 ACP', 60),
        session('calibre maison', 70),
      ],
      now: DateTime(2026, 9, 1),
    );

    expect(stats.caliberDistribution(), {'9 mm': 2, '.380 ACP': 1});
    expect(stats.averagePointsLast30Days(), 55);
    expect(stats.distanceDistribution(), {25: 4});
  });
}
