import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/utils/caliber_autocomplete.dart';

void main() {
  setUpAll(() async {
    await AppConfig.load();
  });

  test('la recherche propose zéro, une ou plusieurs valeurs sans remplacement', () {
    expect(suggestCalibers('38'), containsAll(['.38 Special', '.380 ACP']));
    expect(suggestCalibers('45'), ['.45 ACP']);
    expect(suggestCalibers('inconnu'), isEmpty);
  });

  test('le référentiel est nettoyé et dédupliqué après normalisation', () {
    expect(
      validateCaliberCatalog([' 9mm ', '9 mm', 'Autre', '', '.380 ACP']),
      ['9mm', '.380 ACP'],
    );
    expect(AppConfig.I.calibers, isNot(contains('Autre')));
  });

  test('la valeur existante, y compris vide, prévaut sur la préférence', () {
    expect(
      pickInitialCaliber(existing: 'Libre', defaultCaliber: '.45 ACP'),
      'Libre',
    );
    expect(pickInitialCaliber(existing: '', defaultCaliber: '.45 ACP'), '');
    expect(pickInitialCaliber(defaultCaliber: '.45 ACP'), '.45 ACP');
    expect(pickInitialCaliber(), '');
  });

  test('les alias 9 mm ont un libellé statistique commun', () {
    for (final alias in ['9mm', '9 mm', '9x19', '9 mm Para', '9mm (9x19)']) {
      expect(
        resolveStatisticalCaliber(alias, calibers: AppConfig.I.calibers),
        '9 mm',
        reason: alias,
      );
    }
  });

  test('.380 ACP reste distinct et les valeurs inconnues ne sont pas résolues', () {
    expect(
      resolveStatisticalCaliber('.380 ACP', calibers: AppConfig.I.calibers),
      '.380 ACP',
    );
    expect(
      resolveStatisticalCaliber('9 mm court', calibers: AppConfig.I.calibers),
      isNull,
    );
    expect(
      resolveStatisticalCaliber('calibre maison', calibers: AppConfig.I.calibers),
      isNull,
    );
  });
}
