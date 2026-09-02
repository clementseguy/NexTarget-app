import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/utils/weapon_autocomplete.dart';

void main() {
  group('normalizeWeaponName', () {
    test('trim les espaces en début/fin et met en minuscule', () {
      expect(normalizeWeaponName('  CZ 75 SP-01 Shadow  '), 'cz 75 sp-01 shadow');
    });

    test('ne modifie pas les espaces internes', () {
      expect(normalizeWeaponName('CZ   75'), 'cz   75');
    });
  });

  group('sameWeaponName', () {
    test('vrai si seuls la casse et les espaces de bord diffèrent', () {
      expect(sameWeaponName('  CZ 75  ', 'cz 75'), isTrue);
    });

    test('faux si le contenu diffère (saisie seulement proche)', () {
      expect(sameWeaponName('CZ 75', 'CZ 09'), isFalse);
    });
  });

  group('suggestWeaponNames', () {
    const rack = ['CZ 75 SP-01 Shadow', 'Glock 17', 'Revolver 357'];

    test('saisie vide retourne tout le râtelier', () {
      expect(suggestWeaponNames('', rack), rack);
    });

    test('filtre insensible à la casse sur une sous-chaîne', () {
      expect(suggestWeaponNames('cz', rack), ['CZ 75 SP-01 Shadow']);
    });

    test('poursuivre la saisie avec une valeur non présente ne retourne aucune suggestion', () {
      // Exemple du backlog : "CZ" propose "CZ 75 SP-01 Shadow" ; "CZ 09" ne matche plus rien.
      expect(suggestWeaponNames('CZ 09', rack), isEmpty);
    });

    test('aucune arme ne matche => liste vide', () {
      expect(suggestWeaponNames('inexistante', rack), isEmpty);
    });
  });
}
