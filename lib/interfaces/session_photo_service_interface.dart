import 'package:image_picker/image_picker.dart';

/// Interface pour le service de gestion de la photo de cible attachée à une session (NT-005).
///
/// Abstraction permettant de mocker facilement la sélection/prise de photo dans les tests
/// (le plugin image_picker ne peut pas être exercé dans un environnement de test headless).
abstract class ISessionPhotoService {
  /// Ouvre la galerie ou l'appareil photo selon [source], copie le fichier sélectionné
  /// dans un répertoire persistant de l'application et retourne le chemin absolu du
  /// fichier stocké. Retourne `null` si l'utilisateur annule la sélection.
  Future<String?> pickAndStore(ImageSource source);

  /// Supprime le fichier photo à l'emplacement [path] s'il existe. Ne fait rien si
  /// [path] est `null`/vide ou si le fichier est déjà absent.
  Future<void> deleteIfExists(String? path);
}
