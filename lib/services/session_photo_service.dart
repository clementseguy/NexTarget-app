import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../interfaces/session_photo_service_interface.dart';
import 'logger.dart';

/// Implémentation par défaut de [ISessionPhotoService], basée sur `image_picker`
/// (galerie + appareil photo) et `path_provider` (répertoire de documents de l'app).
///
/// Les chemins retournés par `image_picker` peuvent pointer vers un cache éphémère :
/// le fichier sélectionné/pris est donc copié dans un sous-dossier persistant des
/// documents de l'app, sous un nom unique et stable, pour survivre au redémarrage
/// de l'app (cf. NT-005).
class SessionPhotoService implements ISessionPhotoService {
  static const _subDir = 'session_photos';

  final ImagePicker _picker;

  SessionPhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<String?> pickAndStore(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return null;
      return _storeFile(picked.path);
    } catch (e) {
      AppLogger.I.error('Erreur lors de la sélection/prise de la photo cible', e);
      return null;
    }
  }

  @override
  Future<void> deleteIfExists(String? path) async {
    if (path == null || path.trim().isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.I.error('Erreur lors de la suppression de la photo cible', e);
    }
  }

  Future<String> _storeFile(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${docsDir.path}/$_subDir');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final fileName = 'target_${const Uuid().v4()}${_extensionOf(sourcePath)}';
    final targetPath = '${targetDir.path}/$fileName';
    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  String _extensionOf(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return '.jpg';
    return path.substring(dotIndex);
  }
}
