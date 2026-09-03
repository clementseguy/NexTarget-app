/// Constantes centralisées pour éviter la répétition de chaînes "magiques".
/// Facilite aussi une future i18n ou une migration de stockage.
class SessionConstants {
  /// Statut : session réalisée / terminée
  static const String statusRealisee = 'réalisée';

  /// Statut : session prévue (non encore effectuée)
  static const String statusPrevue = 'prévue';

  /// Nom de la box Hive pour les sessions
  static const String hiveBoxSessions = 'sessions';

  /// Catégories de session
  static const String categoryEntrainement = 'entraînement';
  static const String categoryMatch = 'match';
  static const String categoryTest = 'test matériel';
  static const List<String> categories = [
    categoryEntrainement,
    categoryMatch,
    categoryTest,
  ];

  /// Libellé d'affichage sans modifier la valeur canonique persistée.
  static String categoryLabel(String? category) {
    final value = category?.trim() ?? '';
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  /// Retrouve la valeur canonique d'un libellé de catégorie connu.
  static String categoryValue(String? label) {
    final value = label?.trim() ?? '';
    return categories.firstWhere(
      (category) =>
          categoryLabel(category).toLowerCase() == value.toLowerCase(),
      orElse: () => value,
    );
  }
}
