import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/interfaces/session_photo_service_interface.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/widgets/session_form.dart';

// IMPORTANT : les chemins de photo utilisés dans ces tests pointent
// délibérément vers des fichiers inexistants (jamais de vrais octets
// d'image). SessionPhotoField (utilisé par SessionForm) ne propose pas de
// point d'injection pour l'ImageProvider ; avec un chemin inexistant,
// FileImage échoue tôt (File.readAsBytes lève avant tout appel au décodeur
// dart:ui#instantiateImageCodec), donc aucun risque de blocage — cf. le même
// choix déjà validé dans test/screens/session_photo_section_test.dart
// (cas "fichier introuvable").
class _FakeSessionPhotoService implements ISessionPhotoService {
  /// Valeur renvoyée par le prochain appel à [pickAndStore] (null = annulation).
  String? nextPickResult;
  final List<ImageSource> pickCalls = [];
  final List<String?> deletedPaths = [];

  @override
  Future<String?> pickAndStore(ImageSource source) async {
    pickCalls.add(source);
    return nextPickResult;
  }

  @override
  Future<void> deleteIfExists(String? path) async {
    deletedPaths.add(path);
  }
}

/// SessionForm est un long ListView (résumé, champs, exercices, séries, photo,
/// synthèse) qui dépasse largement la taille par défaut de la surface de test
/// (800x600) : sans agrandir la surface, la Sliver ne construit même pas les
/// éléments hors du viewport+cacheExtent (dont SessionPhotoField), et les
/// finders les cherchant échouent silencieusement (0 widget trouvé). On
/// agrandit donc la surface de rendu pour que tout le formulaire soit
/// construit sans avoir besoin de scroller dans chaque test.
Future<void> _growSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Map<String, dynamic> _sessionData({String? photoPath}) => {
      'session': {
        'weapon': 'Pistolet 22',
        'caliber': '.22 LR',
        'status': SessionConstants.statusPrevue, // évite les contraintes date/séries pour simplifier le montage
        'category': SessionConstants.categoryEntrainement,
        'synthese': '',
        'exercises': <String>[],
        'photoPath': photoPath,
      },
      'series': <dynamic>[],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load(); // échoue silencieusement (assets indisponibles en test) et installe la config par défaut
    final tempDir = await Directory.systemTemp.createTemp('nt_session_form_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('app_preferences')) {
      await Hive.openBox('app_preferences');
    }
  });

  group('SessionForm - photo de la cible (NT-005)', () {
    testWidgets(
      'sans photo initiale : tap Galerie déclenche pickAndStore et le nouveau photoPath est transmis à onSave',
      (tester) async {
        await _growSurface(tester);
        final photoService = _FakeSessionPhotoService()
          ..nextPickResult = '/nonexistent/photos/new_photo.jpg';
        ShootingSession? saved;
        final formKey = GlobalKey<SessionFormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionForm(
                key: formKey,
                initialSessionData: _sessionData(),
                photoService: photoService,
                onSave: (s) => saved = s,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Aucune photo pour le moment'), findsOneWidget);

        await tester.tap(find.text('Galerie'));
        await tester.pump(); // _photoBusy = true
        await tester.pump(); // pickAndStore résolu, _photoPath mis à jour

        expect(photoService.pickCalls, [ImageSource.gallery]);
        expect(find.text('Reprendre'), findsOneWidget); // preuve que _photoPath n'est plus null
        expect(find.byIcon(Icons.close), findsOneWidget);

        final ok = formKey.currentState!.validateAndBuild();

        expect(ok, isTrue);
        expect(saved, isNotNull);
        expect(saved!.photoPath, '/nonexistent/photos/new_photo.jpg');
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'le bouton supprimer déclenche _removePhoto et remet photoPath à null',
      (tester) async {
        await _growSurface(tester);
        final photoService = _FakeSessionPhotoService()
          ..nextPickResult = '/nonexistent/photos/picked.jpg';
        ShootingSession? saved;
        final formKey = GlobalKey<SessionFormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionForm(
                key: formKey,
                initialSessionData: _sessionData(),
                photoService: photoService,
                onSave: (s) => saved = s,
              ),
            ),
          ),
        );
        await tester.pump();

        // Sélectionne d'abord une photo pour faire apparaître le bouton supprimer.
        await tester.tap(find.text('Galerie'));
        await tester.pump();
        await tester.pump();
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(find.text('Aucune photo pour le moment'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);
        // La photo était temporaire (jamais persistée) : elle est bien nettoyée.
        expect(photoService.deletedPaths, contains('/nonexistent/photos/picked.jpg'));

        final ok = formKey.currentState!.validateAndBuild();
        expect(ok, isTrue);
        expect(saved!.photoPath, isNull);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'édition avec photo initiale : remplacer la photo supprime la précédente mais pas la photo initiale tant que non modifiée',
      (tester) async {
        await _growSurface(tester);
        const initialPath = '/nonexistent/photos/initial.jpg';
        final photoService = _FakeSessionPhotoService()
          ..nextPickResult = '/nonexistent/photos/replacement.jpg';
        ShootingSession? saved;
        final formKey = GlobalKey<SessionFormState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionForm(
                key: formKey,
                initialSessionData: _sessionData(photoPath: initialPath),
                isEdit: true,
                photoService: photoService,
                onSave: (s) => saved = s,
              ),
            ),
          ),
        );
        await tester.pump();

        // La photo initiale est déjà affichée (bouton Reprendre visible dès le montage).
        expect(find.text('Reprendre'), findsOneWidget);

        // Prendre une nouvelle photo (Appareil photo) remplace le chemin en mémoire ;
        // comme oldPath (initialPath) == _initialPhotoPath, elle ne doit PAS être supprimée
        // immédiatement (elle reste potentiellement affichée/persistée tant que non sauvegardée).
        await tester.tap(find.text('Reprendre'));
        await tester.pump();
        await tester.pump();

        expect(photoService.pickCalls, [ImageSource.camera]);
        expect(photoService.deletedPaths, isNot(contains(initialPath)));

        // Suppression manuelle ensuite : la photo courante (replacement, != _initialPhotoPath)
        // doit être supprimée, l'initiale ne l'est toujours pas puisqu'elle n'était déjà plus active.
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(photoService.deletedPaths, contains('/nonexistent/photos/replacement.jpg'));
        expect(photoService.deletedPaths, isNot(contains(initialPath)));

        final ok = formKey.currentState!.validateAndBuild();
        expect(ok, isTrue);
        expect(saved!.photoPath, isNull);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
