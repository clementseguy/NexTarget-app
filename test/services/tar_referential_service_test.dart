import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/services/tar_referential_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TarReferentialService', () {
    test('loads the bundled TAR 25m referential for season 2025-2026',
        () async {
      final referential = await TarReferentialService().load();

      expect(referential.metadata.season, '2025-2026');
      expect(referential.metadata.documentVersion, '2026-01-12');
      expect(referential.disciplines.map((d) => d.code),
          containsAll(['830', '831', '832']));

      final discipline830 = referential.resolvedDisciplineByCode('830')!;
      expect(discipline830.distanceMeters, 25);
      expect(discipline830.totalShots, 35);
      expect(discipline830.maxScore, 200);
      expect(discipline830.sequences.map((s) => s.type), [
        'essai',
        'precision',
        'vitesse',
        'vitesse',
      ]);
      expect(discipline830.sequences[2].target, 'gong');
      expect(discipline830.scoring['gong_tombe_pts'], 5);

      final discipline831 = referential.resolvedDisciplineByCode('831')!;
      expect(discipline831.totalShots, 25);
      expect(discipline831.sequences.first.target, 'cible_vitesse_25m');
      expect(discipline831.scoring['tout'], 'pts/zone');

      final discipline832 = referential.resolvedDisciplineByCode('832')!;
      expect(discipline832.name, contains('authentiques'));
      expect(discipline832.identicalTo, '830');
      expect(discipline832.totalShots, 35);
      expect(discipline832.sequences.length, discipline830.sequences.length);
    });

    test('exposes C50, speed target and gong dimensions', () async {
      final referential = await TarReferentialService().load();

      final c50 = referential.targets['C50']!;
      expect(c50.formatMm, [550, 520]);
      expect(c50.zoneDiametersMm['10'], 100);
      expect(c50.zoneDiametersMm['5'], 500);

      final speed = referential.targets['cible_vitesse_25m']!;
      expect(speed.zoneDiametersMm['mouche'], 25);
      expect(speed.zoneDiametersMm['1'], 500);

      final gong = referential.targets['gong']!;
      expect(gong.count, 5);
      expect(gong.formatMm, [200, 200]);
      expect(gong.edgeToEdgeSpacingCm, 20);
      expect(gong.centerHeight25mMeters, 1.40);
    });

    test('rejects referential without mandatory season', () {
      const raw = '''
referentiel:
  source: test
epreuves: []
cibles: {}
''';

      expect(() => TarReferentialService().parse(raw), throwsFormatException);
    });
  });
}
