import '../config/app_config.dart';
export 'caliber_normalization.dart';
import 'caliber_normalization.dart';

/// Retourne les suggestions sans jamais remplacer automatiquement la saisie.
List<String> suggestCalibers(String input, {List<String>? calibers}) {
  final catalog = calibers ?? AppConfig.I.calibers;
  final query = normalizeCaliberSearch(input);
  if (query.isEmpty) return catalog;
  return catalog
      .where((caliber) => normalizeCaliberSearch(caliber).contains(query))
      .toList(growable: false);
}

bool isKnownCaliber(String value, {List<String>? calibers}) {
  final key = normalizeCaliberSearch(value);
  if (key.isEmpty) return false;
  return (calibers ?? AppConfig.I.calibers)
      .any((caliber) => normalizeCaliberSearch(caliber) == key);
}

/// Résout uniquement les calibres reconnus vers leur libellé statistique.
/// Une valeur inconnue retourne `null` et reste intacte dans la session.
String pickInitialCaliber({String? existing, String? defaultCaliber}) {
  if (existing != null) return existing;
  return defaultCaliber ?? '';
}
