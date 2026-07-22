import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

import '../models/tar_referential.dart';

class TarReferentialService {
  static const defaultAssetPath = 'assets/disciplines_tar.yaml';

  Future<TarReferential> load({String assetPath = defaultAssetPath}) async {
    final raw = await rootBundle.loadString(assetPath);
    return parse(raw);
  }

  TarReferential parse(String rawYaml) {
    final root = _stringKeyedMap(loadYaml(rawYaml));
    final metadataMap = _stringKeyedMap(root['referentiel']);
    final season = metadataMap['saison']?.toString();
    if (season == null || season.trim().isEmpty) {
      throw const FormatException(
          'Le referentiel TAR doit declarer une saison.');
    }

    return TarReferential(
      metadata: TarReferentialMetadata(
        source: metadataMap['source']?.toString() ?? '',
        season: season,
        documentVersion: metadataMap['version_doc']?.toString() ?? '',
      ),
      disciplines: _readDisciplines(root['epreuves']),
      targets: _readTargets(root['cibles']),
      countingRules: _stringKeyedMap(root['regles_comptage']),
    );
  }

  List<TarDiscipline> _readDisciplines(dynamic value) {
    if (value is! Iterable) return const [];
    return value.map((entry) {
      final map = _stringKeyedMap(entry);
      return TarDiscipline(
        code: map['code']?.toString() ?? '',
        name: map['nom']?.toString() ?? '',
        identicalTo: map['identique_a']?.toString(),
        distanceMeters: _readInt(map['distance_m']),
        position: map['position']?.toString(),
        totalShots: _readInt(map['coups_total']),
        shotsPerMagazine: _readInt(map['coups_par_chargeur']),
        maxScore: _readInt(map['score_max']),
        weaponConstraints: _stringKeyedMap(map['contraintes_arme']),
        sequences: _readSequences(map['sequences']),
        scoring: _stringKeyedMap(map['scoring']),
      );
    }).toList();
  }

  List<TarSequence> _readSequences(dynamic value) {
    if (value is! Iterable) return const [];
    return value.map((entry) {
      final map = _stringKeyedMap(entry);
      return TarSequence(
        type: map['type']?.toString() ?? '',
        target: map['cible']?.toString() ?? '',
        shots: _readInt(map['coups']) ?? 0,
        stance: map['tenue']?.toString() ?? '',
        time: map['temps']?.toString() ?? '',
        seriesFormat: map['series']?.toString(),
      );
    }).toList();
  }

  Map<String, TarTarget> _readTargets(dynamic value) {
    final map = _stringKeyedMap(value);
    return map.map((code, targetValue) {
      final target = _stringKeyedMap(targetValue);
      return MapEntry(
        code,
        TarTarget(
          code: code,
          formatMm: _readIntList(target['format_mm']),
          zoneDiametersMm: _readZoneDiameters(target['zones_diametre_mm']),
          count: _readInt(target['nombre']),
          edgeToEdgeSpacingCm: _readInt(target['espacement_bord_a_bord_cm']),
          centerHeight25mMeters: _readDouble(target['hauteur_centre_25m_m']),
        ),
      );
    });
  }

  Map<String, int> _readZoneDiameters(dynamic value) {
    final map = _stringKeyedMap(value);
    return map.map((key, diameter) => MapEntry(key, _readInt(diameter) ?? 0));
  }

  static Map<String, dynamic> _stringKeyedMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is YamlMap) {
      return value
          .map((key, entry) => MapEntry(key.toString(), _normalizeYaml(entry)));
    }
    if (value is Map) {
      return value
          .map((key, entry) => MapEntry(key.toString(), _normalizeYaml(entry)));
    }
    return <String, dynamic>{};
  }

  static dynamic _normalizeYaml(dynamic value) {
    if (value is YamlMap || value is Map) return _stringKeyedMap(value);
    if (value is YamlList || value is List) {
      return value.map(_normalizeYaml).toList();
    }
    return value;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.map(_readInt).whereType<int>().toList();
  }
}
