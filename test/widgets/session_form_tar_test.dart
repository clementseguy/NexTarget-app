import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tir_sportif/config/app_config.dart';
import 'package:tir_sportif/constants/session_constants.dart';
import 'package:tir_sportif/models/series.dart';
import 'package:tir_sportif/models/shooting_session.dart';
import 'package:tir_sportif/models/tar_referential.dart';
import 'package:tir_sportif/services/tar_referential_service.dart';
import 'package:tir_sportif/widgets/session_form.dart';

class _FakeTarReferentialService extends TarReferentialService {
  @override
  Future<TarReferential> load({
    String assetPath = TarReferentialService.defaultAssetPath,
  }) async {
    return _testReferential;
  }
}

const _testReferential = TarReferential(
  metadata: TarReferentialMetadata(
    source: 'test',
    season: '2025-2026',
    documentVersion: 'test',
  ),
  disciplines: [
    TarDiscipline(
      code: '830',
      name: 'Pistolet / Revolver - armes recentes',
      distanceMeters: 25,
      sequences: [
        TarSequence(
          type: 'essai',
          target: 'C50',
          shots: 5,
          stance: '1 ou 2 mains',
          time: '3 min',
        ),
        TarSequence(
          type: 'precision',
          target: 'C50',
          shots: 10,
          stance: '1 main bras franc',
          time: '7 min',
          seriesFormat: '2x5',
        ),
        TarSequence(
          type: 'vitesse',
          target: 'gong',
          shots: 10,
          stance: '1 ou 2 mains',
          time: '2 x 20 s',
          seriesFormat: '2x5',
        ),
        TarSequence(
          type: 'vitesse',
          target: 'gong',
          shots: 10,
          stance: '1 ou 2 mains',
          time: '2 x 10 s',
          seriesFormat: '2x5',
        ),
      ],
      scoring: {'precision': 'pts/zone ISSF', 'gong_tombe_pts': 5},
    ),
    TarDiscipline(
      code: '831',
      name: 'Vitesse reglementaire',
      distanceMeters: 25,
      sequences: [
        TarSequence(
          type: 'essai',
          target: 'cible_vitesse_25m',
          shots: 5,
          stance: '1 ou 2 mains',
          time: '20 s',
        ),
        TarSequence(
          type: 'vitesse',
          target: 'cible_vitesse_25m',
          shots: 10,
          stance: '1 ou 2 mains',
          time: '2 x 20 s',
          seriesFormat: '2x5',
        ),
        TarSequence(
          type: 'vitesse',
          target: 'cible_vitesse_25m',
          shots: 10,
          stance: '1 ou 2 mains',
          time: '2 x 10 s',
          seriesFormat: '2x5',
        ),
      ],
      scoring: {'tout': 'pts/zone'},
    ),
  ],
  targets: {},
  countingRules: {},
);

Future<void> _growSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 4200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

Finder _gongsFields() {
  return find.ancestor(
    of: find.text('Gongs'),
    matching: find.byType(TextFormField),
  );
}

Map<String, dynamic> _initialData({
  String? disciplineCode,
  String? disciplineSeason,
  List<dynamic> series = const [],
}) {
  return {
    'session': {
      'weapon': 'Pistolet TAR',
      'caliber': '.22 LR',
      'status': SessionConstants.statusPrevue,
      'category': SessionConstants.categoryEntrainement,
      'synthese': '',
      'exercises': <String>[],
      'discipline_code': disciplineCode,
      'discipline_season': disciplineSeason,
    },
    'series': series,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.load();
    if (!Hive.isBoxOpen('app_preferences')) {
      final tempDir =
          await Directory.systemTemp.createTemp('nt_session_form_tar_test_');
      Hive.init(tempDir.path);
      await Hive.openBox('app_preferences');
    }
  });

  setUp(() async {
    if (Hive.isBoxOpen('app_preferences')) {
      await Hive.box('app_preferences').clear();
    }
  });

  testWidgets('prefills 830 template series from the TAR referential',
      (tester) async {
    await _growSurface(tester);
    ShootingSession? saved;
    final formKey = GlobalKey<SessionFormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionForm(
            key: formKey,
            initialSessionData: _initialData(
              disciplineCode: '830',
              disciplineSeason: '2025-2026',
            ),
            tarReferentialService: _FakeTarReferentialService(),
            onSave: (session) => saved = session,
          ),
        ),
      ),
    );
    await _pumpAsyncWork(tester);

    expect(find.text('Série 4'), findsOneWidget);
    expect(_gongsFields(), findsNWidgets(2));

    await tester.enterText(_gongsFields().first, '4');
    await tester.pump();

    final ok = formKey.currentState!.validateAndBuild();

    expect(ok, isTrue);
    expect(saved, isNotNull);
    expect(saved!.disciplineCode, '830');
    expect(saved!.disciplineSeason, '2025-2026');
    expect(saved!.series, hasLength(4));

    final trial = saved!.series[0];
    expect(trial.distance, 25);
    expect(trial.shotCount, 5);
    expect(trial.sequenceType, TarSequenceType.essai);
    expect(trial.scoringMode, SeriesScoringMode.pointsZone);
    expect(trial.targetType, 'C50');
    expect(trial.timeLimitLabel, '3 min');
    expect(trial.timeLimitSeconds, 180);

    final precision = saved!.series[1];
    expect(precision.shotCount, 10);
    expect(precision.sequenceType, TarSequenceType.precision);
    expect(precision.handMethod, HandMethod.oneHand);
    expect(precision.timeLimitSeconds, 420);

    final firstGongs = saved!.series[2];
    expect(firstGongs.scoringMode, SeriesScoringMode.gongsTombes);
    expect(firstGongs.targetType, 'gong');
    expect(firstGongs.timeLimitLabel, '2 x 20 s');
    expect(firstGongs.timeLimitSeconds, 20);
    expect(firstGongs.gongsHit, 4);
    expect(firstGongs.gongPointValue, 5);
    expect(firstGongs.points, 20);
    expect(firstGongs.scoredPoints, 20);
  });

  testWidgets('prefills 831 speed target point-zone series', (tester) async {
    await _growSurface(tester);
    ShootingSession? saved;
    final formKey = GlobalKey<SessionFormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionForm(
            key: formKey,
            initialSessionData: _initialData(
              disciplineCode: '831',
              disciplineSeason: '2025-2026',
            ),
            tarReferentialService: _FakeTarReferentialService(),
            onSave: (session) => saved = session,
          ),
        ),
      ),
    );
    await _pumpAsyncWork(tester);

    final ok = formKey.currentState!.validateAndBuild();

    expect(ok, isTrue);
    expect(saved, isNotNull);
    expect(saved!.disciplineCode, '831');
    expect(saved!.disciplineSeason, '2025-2026');
    expect(saved!.series, hasLength(3));
    expect(saved!.series.map((series) => series.targetType),
        everyElement('cible_vitesse_25m'));
    expect(saved!.series.map((series) => series.scoringMode),
        everyElement(SeriesScoringMode.pointsZone));
    expect(
        saved!.series.map((series) => series.gongsHit), everyElement(isNull));
  });

  testWidgets('editing preserves existing TAR fields when event is unchanged',
      (tester) async {
    await _growSurface(tester);
    ShootingSession? saved;
    final formKey = GlobalKey<SessionFormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionForm(
            key: formKey,
            isEdit: true,
            initialSessionData: _initialData(
              disciplineCode: '830',
              disciplineSeason: '2025-2026',
              series: [
                {
                  'shot_count': 10,
                  'distance': 25,
                  'points': 20,
                  'group_size': 0,
                  'comment': 'gongs rapides',
                  'hand_method': 'two',
                  'sequence_type': 'vitesse',
                  'scoring_mode': 'gongs_tombes',
                  'target_type': 'gong',
                  'time_limit_label': '2 x 10 s',
                  'time_limit_seconds': 10,
                  'gongs_hit': 4,
                  'gong_point_value': 5,
                },
              ],
            ),
            tarReferentialService: _FakeTarReferentialService(),
            onSave: (session) => saved = session,
          ),
        ),
      ),
    );
    await _pumpAsyncWork(tester);

    final ok = formKey.currentState!.validateAndBuild();

    expect(ok, isTrue);
    expect(saved, isNotNull);
    expect(saved!.disciplineCode, '830');
    expect(saved!.series, hasLength(1));
    final series = saved!.series.single;
    expect(series.sequenceType, TarSequenceType.vitesse);
    expect(series.scoringMode, SeriesScoringMode.gongsTombes);
    expect(series.targetType, 'gong');
    expect(series.timeLimitLabel, '2 x 10 s');
    expect(series.timeLimitSeconds, 10);
    expect(series.gongsHit, 4);
    expect(series.gongPointValue, 5);
    expect(series.points, 20);
    expect(series.scoredPoints, 20);
  });
}
