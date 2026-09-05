import 'dart:io';

/// Frontière système utilisée par les exports de sauvegarde.
abstract class BackupLocationProvider {
  Future<Directory> getTemporaryDirectory();

  Future<String?> selectExportDirectory();
}
