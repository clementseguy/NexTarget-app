import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../interfaces/backup_location_provider.dart';

/// Implémentation de production reposant sur les plugins natifs Flutter.
class PlatformBackupLocationProvider implements BackupLocationProvider {
  @override
  Future<Directory> getTemporaryDirectory() =>
      path_provider.getTemporaryDirectory();

  @override
  Future<File?> saveExportFile(
    String suggestedFileName,
    List<int> bytes,
  ) async {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la sauvegarde',
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      // file_picker 8 exige les octets sur Android/iOS et réalise lui-même
      // l'écriture via le sélecteur de documents natif. Les plateformes de
      // bureau renvoient au contraire un chemin à écrire avec dart:io.
      bytes: isMobile ? Uint8List.fromList(bytes) : null,
    );
    if (path == null) return null;

    final file = File(path);
    if (!isMobile) await file.writeAsBytes(bytes);
    return file;
  }
}
