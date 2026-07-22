class TarReferential {
  final TarReferentialMetadata metadata;
  final List<TarDiscipline> disciplines;
  final Map<String, TarTarget> targets;
  final Map<String, dynamic> countingRules;

  const TarReferential({
    required this.metadata,
    required this.disciplines,
    required this.targets,
    required this.countingRules,
  });

  TarDiscipline? disciplineByCode(String code) {
    for (final discipline in disciplines) {
      if (discipline.code == code) return discipline;
    }
    return null;
  }

  TarDiscipline? resolvedDisciplineByCode(String code) {
    final discipline = disciplineByCode(code);
    if (discipline == null) return null;
    final inheritedCode = discipline.identicalTo;
    if (inheritedCode == null) return discipline;

    final base = disciplineByCode(inheritedCode);
    if (base == null) return discipline;
    return discipline.copyWithInheritedFormat(base);
  }
}

class TarReferentialMetadata {
  final String source;
  final String season;
  final String documentVersion;

  const TarReferentialMetadata({
    required this.source,
    required this.season,
    required this.documentVersion,
  });
}

class TarDiscipline {
  final String code;
  final String name;
  final String? identicalTo;
  final int? distanceMeters;
  final String? position;
  final int? totalShots;
  final int? shotsPerMagazine;
  final int? maxScore;
  final Map<String, dynamic> weaponConstraints;
  final List<TarSequence> sequences;
  final Map<String, dynamic> scoring;

  const TarDiscipline({
    required this.code,
    required this.name,
    this.identicalTo,
    this.distanceMeters,
    this.position,
    this.totalShots,
    this.shotsPerMagazine,
    this.maxScore,
    this.weaponConstraints = const {},
    this.sequences = const [],
    this.scoring = const {},
  });

  TarDiscipline copyWithInheritedFormat(TarDiscipline base) {
    return TarDiscipline(
      code: code,
      name: name,
      identicalTo: identicalTo,
      distanceMeters: distanceMeters ?? base.distanceMeters,
      position: position ?? base.position,
      totalShots: totalShots ?? base.totalShots,
      shotsPerMagazine: shotsPerMagazine ?? base.shotsPerMagazine,
      maxScore: maxScore ?? base.maxScore,
      weaponConstraints: weaponConstraints.isNotEmpty
          ? weaponConstraints
          : base.weaponConstraints,
      sequences: sequences.isNotEmpty ? sequences : base.sequences,
      scoring: scoring.isNotEmpty ? scoring : base.scoring,
    );
  }
}

class TarSequence {
  final String type;
  final String target;
  final int shots;
  final String stance;
  final String time;
  final String? seriesFormat;

  const TarSequence({
    required this.type,
    required this.target,
    required this.shots,
    required this.stance,
    required this.time,
    this.seriesFormat,
  });
}

class TarTarget {
  final String code;
  final List<int> formatMm;
  final Map<String, int> zoneDiametersMm;
  final int? count;
  final int? edgeToEdgeSpacingCm;
  final double? centerHeight25mMeters;

  const TarTarget({
    required this.code,
    required this.formatMm,
    this.zoneDiametersMm = const {},
    this.count,
    this.edgeToEdgeSpacingCm,
    this.centerHeight25mMeters,
  });
}
