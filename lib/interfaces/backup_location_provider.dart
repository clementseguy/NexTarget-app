import 'dart:io';

/// Frontière système utilisée par les exports de sauvegarde.
abstract class BackupLocationProvider {
  Future<Directory> getTemporaryDirectory();

  /// Sélectionne la destination et écrit le contenu de l'export.
  ///
  /// Retourne `null` en cas d'annulation. La frontière prend en charge les
  /// écritures natives Android/iOS qui ne fournissent pas un chemin Dart IO
  /// directement exploitable.
  Future<File?> saveExportFile(String suggestedFileName, List<int> bytes);
}
