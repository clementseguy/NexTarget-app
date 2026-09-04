import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/constants/session_constants.dart';

void main() {
  test('les libellés de catégorie commencent par une majuscule', () {
    expect(
      SessionConstants.categories.map(SessionConstants.categoryLabel),
      ['Entraînement', 'Match', 'Test matériel'],
    );
  });

  test('un libellé connu retrouve sa valeur canonique persistée', () {
    expect(
      SessionConstants.categoryValue('Test matériel'),
      SessionConstants.categoryTest,
    );
  });
}
