import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/services/dashboard_service.dart';

DetailedShootingSession _session({
  required int id,
  required DateTime date,
  required int points,
  required double groupSize,
  String status = SessionConstants.statusRealisee,
}) =>
    DetailedShootingSession(
      id: id,
      date: date,
      weapon: 'Pistolet $id',
      caliber: '9 mm',
      status: status,
      series: [
        Series(distance: 25, points: points, groupSize: groupSize),
      ],
    );

void main() {
  test('les deux records portent explicitement leur session source', () {
    final scoreSession = _session(
      id: 1,
      date: DateTime(2026, 8, 1),
      points: 49,
      groupSize: 12,
    );
    final groupSession = _session(
      id: 2,
      date: DateTime(2026, 8, 2),
      points: 45,
      groupSize: 6,
    );

    final summary =
        DashboardService([scoreSession, groupSession]).generateSummary();

    expect(summary.bestScore, 49);
    expect(summary.bestScoreSession?.id, 1);
    expect(summary.bestGroupSize, 6);
    expect(summary.bestGroupSizeSession?.id, 2);
  });

  test('les ex æquo retiennent la date récente puis le plus grand identifiant',
      () {
    final old = _session(
      id: 50,
      date: DateTime(2026, 7, 1),
      points: 49,
      groupSize: 6,
    );
    final recentLowId = _session(
      id: 2,
      date: DateTime(2026, 8, 1),
      points: 49,
      groupSize: 6,
    );
    final recentHighId = _session(
      id: 9,
      date: DateTime(2026, 8, 1),
      points: 49,
      groupSize: 6,
    );

    final summary =
        DashboardService([recentLowId, old, recentHighId]).generateSummary();

    expect(summary.bestScoreSession?.id, 9);
    expect(summary.bestGroupSizeSession?.id, 9);
  });

  test('les exclusions existantes et le groupement strictement positif restent',
      () {
    final valid = _session(
      id: 1,
      date: DateTime(2026, 8, 1),
      points: 40,
      groupSize: 8,
    );
    final zeroGroup = _session(
      id: 2,
      date: DateTime(2026, 8, 2),
      points: 41,
      groupSize: 0,
    );
    final planned = _session(
      id: 3,
      date: DateTime(2026, 8, 3),
      points: 50,
      groupSize: 2,
      status: SessionConstants.statusPrevue,
    );

    final summary =
        DashboardService([valid, zeroGroup, planned]).generateSummary();

    expect(summary.bestScore, 41);
    expect(summary.bestScoreSession?.id, 2);
    expect(summary.bestGroupSize, 8);
    expect(summary.bestGroupSizeSession?.id, 1);
  });
}
