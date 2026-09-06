import 'dart:io';

/// Frontière système utilisée par les exports de sauvegarde.
abstract class BackupLocationProvider {
  Future<Directory> getTemporaryDirectory();

  /// Retourne le chemin complet choisi pour le fichier d'export.
  Future<String?> selectExportFilePath(String suggestedFileName);
}
