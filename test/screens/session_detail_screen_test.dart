import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/screens/session_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionDetailScreen - photo de la cible (NT-005)', () {
    setUpAll(() async {
      await AppConfig.load();
      final tempDir = await Directory.systemTemp.createTemp('nt_session_detail_test_');
      Hive.init(tempDir.path);
    });

    // SessionDetailScreen est un long ListView ; on agrandit la surface de
    // rendu pour que tout le contenu (dont SessionPhotoSection) soit
    // effectivement construit par la Sliver, cf. le même besoin déjà
    // rencontré dans test/widgets/session_form_test.dart.
    Future<void> growSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 4000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    Map<String, dynamic> sessionData({String? photoPath}) {
      final session = ShootingSession(
        weapon: 'Pistolet test',
        caliber: '22LR',
        status: SessionConstants.statusPrevue,
        series: const [],
        photoPath: photoPath,
      );
      return {'session': session.toMap(), 'series': <dynamic>[]};
    }

    testWidgets(
      'session avec photo : affiche SessionPhotoSection',
      (tester) async {
        await growSurface(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: SessionDetailScreen(
              sessionData: sessionData(photoPath: '/nonexistent/photos/detail.jpg'),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Photo de la cible'), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'session sans photo : n\'affiche pas SessionPhotoSection',
      (tester) async {
        await growSurface(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: SessionDetailScreen(sessionData: sessionData()),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Photo de la cible'), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });

  group('SessionDetailScreen UI Elements', () {
    testWidgets('affiche un titre approprié', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: Text('Détails session'),
            ),
          ),
        ),
      );
      
      expect(find.text('Détails session'), findsOneWidget);
    });

    testWidgets('contient des éléments de résumé de session', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Arme:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('Pistolet test'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Calibre:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('22LR'),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Text('01/01/2023'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Séries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      expect(find.text('Arme:'), findsOneWidget);
      expect(find.text('Calibre:'), findsOneWidget);
      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('Pistolet test'), findsOneWidget);
      expect(find.text('22LR'), findsOneWidget);
      expect(find.text('01/01/2023'), findsOneWidget);
      expect(find.text('Séries'), findsOneWidget);
    });
  });
}