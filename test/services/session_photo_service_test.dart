import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/services/session_photo_service.dart';

/// [ImagePicker] fake : contourne le plugin natif (aucun handler de
/// plateforme en environnement de test headless) en renvoyant directement un
/// [XFile] pointant vers un fichier temporaire préparé par le test, pour
/// exercer le chemin de succès complet de [SessionPhotoService.pickAndStore].
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this._pathToReturn);

  final String? _pathToReturn;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    final path = _pathToReturn;
    if (path == null) return null;
    return XFile(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionPhotoService', () {
    late SessionPhotoService service;

    setUp(() {
      service = SessionPhotoService();
    });

    test('deleteIfExists supprime un fichier existant', () async {
      final tempDir = await Directory.systemTemp.createTemp('nt_photo_service_');
      final file = File('${tempDir.path}/target_test.jpg');
      await file.writeAsBytes([1, 2, 3]);
      expect(await file.exists(), isTrue);

      await service.deleteIfExists(file.path);

      expect(await file.exists(), isFalse);
      await tempDir.delete(recursive: true);
    });

    test('deleteIfExists ne lève pas d\'exception si le fichier est absent', () async {
      final tempDir = await Directory.systemTemp.createTemp('nt_photo_service_');
      final missing = '${tempDir.path}/does_not_exist.jpg';

      await expectLater(service.deleteIfExists(missing), completes);

      await tempDir.delete(recursive: true);
    });

    test('deleteIfExists est un no-op pour un chemin null ou vide', () async {
      await expectLater(service.deleteIfExists(null), completes);
      await expectLater(service.deleteIfExists(''), completes);
      await expectLater(service.deleteIfExists('   '), completes);
    });

    test('pickAndStore retourne null au lieu de lever si le plugin natif est indisponible', () async {
      // En environnement de test, aucun handler de plateforme n'est enregistré pour
      // image_picker : l'appel doit être intercepté et renvoyer null plutôt que de
      // propager une exception (cf. gestion d'erreur dans pickAndStore).
      final result = await service.pickAndStore(ImageSource.gallery);
      expect(result, isNull);
    });

    group('pickAndStore - chemin de succès (mock path_provider)', () {
      // `getApplicationDocumentsDirectory` (path_provider) passe par un
      // platform channel qui n'a aucun handler natif enregistré en
      // environnement de test headless. On mocke ce channel pour renvoyer un
      // répertoire temporaire réel, ce qui permet d'exercer _storeFile
      // (copie effective du fichier sur disque) sans dépendance de
      // plateforme. Technique standard Flutter :
      // TestDefaultBinaryMessengerBinding.setMockMethodCallHandler.
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
      late Directory fakeDocsDir;
      late Directory sourceDir;

      setUp(() async {
        fakeDocsDir = await Directory.systemTemp.createTemp('nt_fake_docs_');
        sourceDir = await Directory.systemTemp.createTemp('nt_photo_source_');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return fakeDocsDir.path;
          }
          return null;
        });
      });

      tearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, null);
        if (await fakeDocsDir.exists()) await fakeDocsDir.delete(recursive: true);
        if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
      });

      test('copie le fichier sélectionné dans <docs>/session_photos/ et retourne son chemin', () async {
        final sourceFile = File('${sourceDir.path}/original.png');
        await sourceFile.writeAsBytes([1, 2, 3, 4]);

        final fakePicker = _FakeImagePicker(sourceFile.path);
        final service = SessionPhotoService(picker: fakePicker);

        final result = await service.pickAndStore(ImageSource.gallery);

        expect(result, isNotNull);
        expect(result, startsWith('${fakeDocsDir.path}/session_photos/'));
        expect(result, endsWith('.png'));
        final storedFile = File(result!);
        expect(await storedFile.exists(), isTrue);
        expect(await storedFile.readAsBytes(), [1, 2, 3, 4]);
      });

      test('génère un nom de fichier unique à chaque appel', () async {
        final sourceFile = File('${sourceDir.path}/shot.jpg');
        await sourceFile.writeAsBytes([9, 9, 9]);

        final service = SessionPhotoService(picker: _FakeImagePicker(sourceFile.path));

        final first = await service.pickAndStore(ImageSource.camera);
        final second = await service.pickAndStore(ImageSource.camera);

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(first, isNot(equals(second)));
      });

      test('préserve une extension absente en retombant sur .jpg', () async {
        final sourceFile = File('${sourceDir.path}/no_extension');
        await sourceFile.writeAsBytes([5, 5]);

        final service = SessionPhotoService(picker: _FakeImagePicker(sourceFile.path));

        final result = await service.pickAndStore(ImageSource.gallery);

        expect(result, isNotNull);
        expect(result, endsWith('.jpg'));
      });

      test('retourne null sans copier de fichier si la sélection est annulée', () async {
        final service = SessionPhotoService(picker: _FakeImagePicker(null));

        final result = await service.pickAndStore(ImageSource.gallery);

        expect(result, isNull);
        final targetDir = Directory('${fakeDocsDir.path}/session_photos');
        expect(await targetDir.exists(), isFalse);
      });
    });
  });
}
