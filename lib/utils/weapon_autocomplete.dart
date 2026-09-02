/// Normalisation et autocomplétion centralisées pour le râtelier d'armes
/// (NT-008/NT-009/NT-017), afin que le CRUD du râtelier, l'autocomplétion en
/// saisie de session et le comptage de tirs partagent exactement la même
/// notion de correspondance : espaces en début/fin ignorés, casse ignorée.
/// Aucune autre transformation : contrairement au calibre, le nom d'une arme
/// reste un texte libre.
String normalizeWeaponName(String input) => input.trim().toLowerCase();

/// Vrai si [a] et [b] désignent la même arme une fois normalisés.
bool sameWeaponName(String a, String b) => normalizeWeaponName(a) == normalizeWeaponName(b);

/// Noms du râtelier à proposer pour la saisie [input] (NT-009).
///
/// Ne modifie jamais [input] : ne fait que sélectionner, parmi [rackNames],
/// les noms dont la forme normalisée contient la saisie normalisée. Saisie
/// vide => tout le râtelier est proposé.
List<String> suggestWeaponNames(String input, List<String> rackNames) {
  final q = normalizeWeaponName(input);
  if (q.isEmpty) return List.unmodifiable(rackNames);
  return rackNames.where((n) => normalizeWeaponName(n).contains(q)).toList();
}
