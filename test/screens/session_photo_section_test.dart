import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/screens/session_detail/session_detail_components.dart';

// IMPORTANT : ces tests n'utilisent jamais Image.file/FileImage avec de
// vrais octets de fichier. Le décodage réel d'image (dart:ui#
// instantiateImageCodec) ne se résout jamais dans cet environnement de test
// headless et bloque le test indéfiniment (vérifié expérimentalement :
// TimeoutException after 0:10:00 même en attendant explicitement la
// résolution du FileImage via tester.runAsync). On utilise donc
// SessionPhotoSection.imageProviderBuilder pour injecter un ImageProvider de
// test qui se résout immédiatement (en erreur) sans jamais passer par le
// décodeur natif. Le rendu pixel de l'image n'est de toute façon pas ce que
// ces tests vérifient : ils vérifient que le widget Image est bien présent
// dans l'arbre et que les éléments construits de façon synchrone (titre)
// s'affichent.
class _FakeImageProvider extends ImageProvider<_FakeImageProvider> {
  const _FakeImageProvider();

  @override
  Future<_FakeImageProvider> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FakeImageProvider>(this);

  @override
  ImageStreamCompleter loadImage(_FakeImageProvider key, ImageDecoderCallback decode) {
    // Complète immédiatement en erreur (silencieuse côté flutter_test) : pas
    // de décodage natif déclenché, le widget Image affiche son errorBuilder.
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(
        StateError('_FakeImageProvider : pas de décodage réel en test'),
      ),
    );
  }
}

void main() {
  group('SessionPhotoSection', () {
    testWidgets(
      'affiche le titre et l\'image de la cible',
      (tester) async {
        const photoPath = '/fake/target_detail.jpg';
        String? capturedPath;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoSection(
                photoPath: photoPath,
                imageProviderBuilder: (path) {
                  capturedPath = path;
                  return const _FakeImageProvider();
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(capturedPath, photoPath);
        expect(find.text('Photo de la cible'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'ne lève pas d\'exception si le fichier photo est introuvable',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoSection(photoPath: '/chemin/inexistant/photo.jpg'),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Photo de la cible'), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'ouvre une vue plein écran au tap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoSection(photoPath: '/chemin/inexistant/photo.jpg'),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
