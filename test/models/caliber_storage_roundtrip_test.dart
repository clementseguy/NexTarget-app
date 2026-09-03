import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/shooting_session.dart';

void main() {
  test('la sérialisation utilisée par les sauvegardes conserve le texte libre', () {
    final session = ShootingSession(
      date: DateTime(2026, 9, 2),
      weapon: 'Pistolet',
      caliber: ' 9 mm perso ',
      status: SessionConstants.statusRealisee,
      category: SessionConstants.categoryEntrainement,
      series: const [],
    );

    final exported = session.toMap();
    expect(exported['caliber'], ' 9 mm perso ');
    expect(ShootingSession.fromMap(exported).caliber, ' 9 mm perso ');
  });
}
