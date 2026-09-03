/// Normalisation réservée à la recherche dans le référentiel.
///
/// Elle ne doit jamais être utilisée pour modifier une valeur de session.
String normalizeCaliberSearch(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('×', 'x')
      .replaceAll(RegExp(r'\s+'), '');
}

/// Nettoie le référentiel configurable, retire l'entrée générique `Autre` et
/// élimine les doublons selon la normalisation de recherche.
List<String> validateCaliberCatalog(Iterable<dynamic> values) {
  final result = <String>[];
  final normalized = <String>{};
  for (final raw in values) {
    final value = raw.toString().trim();
    final key = normalizeCaliberSearch(value);
    if (key.isEmpty || key == 'autre' || !normalized.add(key)) continue;
    result.add(value);
  }
  return List.unmodifiable(result);
}

/// Résout uniquement les calibres reconnus vers leur libellé statistique.
/// Une valeur inconnue retourne `null` et reste intacte dans la session.
String? resolveStatisticalCaliber(String value, {required List<String> calibers}) {
  final key = normalizeCaliberSearch(value);
  const nineMillimeterAliases = {
    '9mm',
    '9x19',
    '9mmpara',
    '9mm(9x19)',
  };
  if (nineMillimeterAliases.contains(key)) return '9 mm';

  for (final caliber in calibers) {
    if (normalizeCaliberSearch(caliber) == key) return caliber;
  }
  return null;
}
