import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../interfaces/backup_location_provider.dart';

/// Implémentation de production reposant sur les plugins natifs Flutter.
class PlatformBackupLocationProvider implements BackupLocationProvider {
  @override
  Future<Directory> getTemporaryDirectory() =>
      path_provider.getTemporaryDirectory();

  @override
  Future<String?> selectExportDirectory() =>
      FilePicker.platform.getDirectoryPath();
}
