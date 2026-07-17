import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/widgets/session_form/session_form_components.dart';
import 'package:tir_sportif/models/exercise.dart';

// IMPORTANT : ne jamais faire passer un vrai fichier (octets valides ou non)
// par Image.file/FileImage dans ces tests. Le décodage réel d'image
// (dart:ui#instantiateImageCodec) ne se résout jamais dans cet environnement
// de test headless et bloque le test indéfiniment (vérifié expérimentalement
// : TimeoutException after 0:10:00 même en attendant explicitement la
// résolution du FileImage via tester.runAsync). SessionPhotoField expose
// imageProviderBuilder pour injecter un ImageProvider de test qui se résout
// immédiatement (en erreur) sans jamais passer par le décodeur natif. Le
// rendu pixel de l'image n'est de toute façon pas ce que ces tests
// vérifient : ils vérifient uniquement les éléments construits de façon
// synchrone autour de l'image (bouton supprimer, libellé "Reprendre", etc.).
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
  group('FormSummaryHeader', () {
    testWidgets('affiche correctement les statistiques de session', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSummaryHeader(
              date: DateTime(2025, 10, 17),
              onPickDate: () {},
              seriesCount: 4,
              totalPoints: 150,
              avgPoints: 37.5,
              dominantDistance: 25.0,
            ),
          ),
        ),
      );

      expect(find.text('Résumé'), findsNothing); // Le titre n'existe pas dans ce widget
      expect(find.text('17/10/2025'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.text('37.5'), findsOneWidget);
      expect(find.text('25m'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('affiche "-" quand distance dominante est null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSummaryHeader(
              date: DateTime(2025, 10, 17),
              onPickDate: () {},
              seriesCount: 4,
              totalPoints: 100,
              avgPoints: 25.0,
              dominantDistance: null,
            ),
          ),
        ),
      );

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('le bouton Choisir appelle onPickDate', (tester) async {
      bool called = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FormSummaryHeader(
              date: DateTime(2025, 10, 17),
              onPickDate: () => called = true,
              seriesCount: 4,
              totalPoints: 100,
              avgPoints: 25.0,
              dominantDistance: 25.0,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Choisir'));
      expect(called, isTrue);
    });
  });

  group('MiniStat', () {
    testWidgets('affiche label et valeur correctement', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                MiniStat(
                  label: 'Total',
                  value: '250 pts',
                  icon: Icons.score,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('250 pts'), findsOneWidget);
      expect(find.byIcon(Icons.score), findsOneWidget);
    });

    testWidgets('affiche icône et couleur personnalisées', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: const [
                MiniStat(
                  label: 'Test',
                  value: '42',
                  icon: Icons.star,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });

  group('DividerV', () {
    testWidgets('rend un divider vertical', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DividerV(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, 1);
      expect(container.constraints?.maxHeight, 40);
    });
  });

  group('SyntheseCard', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('affiche le champ synthèse avec placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyntheseCard(
              controller: controller,
              status: 'test_status',
            ),
          ),
        ),
      );

      expect(find.text('Synthèse personnelle'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('le contrôleur reçoit le texte saisi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyntheseCard(
              controller: controller,
              status: 'test_status',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Bonne session');
      expect(controller.text, 'Bonne session');
    });
  });

  group('ExercisesSelector', () {
    final mockExercises = [
      Exercise(
        id: 'ex1',
        name: 'Exercice 1',
        description: 'Description 1',
        goalIds: [],
        categoryEnum: ExerciseCategory.technique,
        type: ExerciseType.stand,
        createdAt: DateTime.now(),
      ),
      Exercise(
        id: 'ex2',
        name: 'Exercice 2',
        description: 'Description 2',
        goalIds: [],
        categoryEnum: ExerciseCategory.precision,
        type: ExerciseType.stand,
        createdAt: DateTime.now(),
      ),
    ];

    testWidgets('affiche la liste des exercices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExercisesSelector(
              exercises: mockExercises,
              selectedIds: const {},
              onToggle: (_) {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Exercices associés'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testWidgets('affiche loading indicator quand isLoading=true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExercisesSelector(
              exercises: mockExercises,
              selectedIds: const {},
              onToggle: (_) {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('callback onToggle est appelé lors du tap', (tester) async {
      String? toggledId;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExercisesSelector(
              exercises: mockExercises,
              selectedIds: const {},
              onToggle: (id) => toggledId = id,
              isLoading: false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Exercice 1'));
      expect(toggledId, 'ex1');
    });

    testWidgets('affiche le compte d\'exercices sélectionnés', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExercisesSelector(
              exercises: mockExercises,
              selectedIds: const {'ex1'},
              onToggle: (_) {},
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('(1)'), findsOneWidget);
    });
  });

  group('SessionPhotoField', () {
    testWidgets(
      'sans photo : propose Galerie et Appareil photo',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoField(
                photoPath: null,
                onPickFromGallery: () {},
                onPickFromCamera: () {},
                onRemove: () {},
              ),
            ),
          ),
        );

        expect(find.text('Galerie'), findsOneWidget);
        expect(find.text('Appareil photo'), findsOneWidget);
        expect(find.text('Aucune photo pour le moment'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'onPickFromGallery et onPickFromCamera sont appelés',
      (tester) async {
        bool galleryCalled = false;
        bool cameraCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoField(
                photoPath: null,
                onPickFromGallery: () => galleryCalled = true,
                onPickFromCamera: () => cameraCalled = true,
                onRemove: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Galerie'));
        await tester.tap(find.text('Appareil photo'));

        expect(galleryCalled, isTrue);
        expect(cameraCalled, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'affiche un indicateur de chargement quand isBusy=true et désactive les boutons',
      (tester) async {
        bool galleryCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoField(
                photoPath: null,
                isBusy: true,
                onPickFromGallery: () => galleryCalled = true,
                onPickFromCamera: () {},
                onRemove: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(find.text('Galerie'), warnIfMissed: false);
        expect(galleryCalled, isFalse);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'avec une photo : affiche le bouton supprimer et "Reprendre"',
      (tester) async {
        const photoPath = '/fake/target_test.jpg';
        bool removed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionPhotoField(
                photoPath: photoPath,
                imageProviderBuilder: (_) => const _FakeImageProvider(),
                onPickFromGallery: () {},
                onPickFromCamera: () {},
                onRemove: () => removed = true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Reprendre'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        expect(removed, isTrue);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
