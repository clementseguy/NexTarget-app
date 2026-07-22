import 'series.dart';

class ShootingSession {
  int? id;
  DateTime? date;
  String weapon;
  String caliber;
  List<Series> series;
  String status; // "prévue" ou "réalisée"
  String? analyse;
  String? synthese;
  String category; // entraînement / match / test matériel
  List<String> exercises; // exercise IDs linked to this session (can be empty)
  String? photoPath; // chemin local persistant de la photo de cible (NT-005)
  String? disciplineCode; // epreuve TAR officielle: 830 / 831 / 832
  String? disciplineSeason; // saison du referentiel associe, ex. 2025-2026

  ShootingSession({
    this.id,
    this.date,
    required this.weapon,
    required this.caliber,
    required this.series,
    this.status = 'réalisée',
    this.analyse,
    this.synthese,
    this.category = 'entraînement',
    List<String>? exercises,
    this.photoPath,
    this.disciplineCode,
    this.disciplineSeason,
  }) : exercises = exercises ?? <String>[];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'weapon': weapon,
      'caliber': caliber,
      'series': series.map((s) => s.toMap()).toList(),
      'status': status,
      'analyse': analyse,
      'synthese': synthese,
      'category': category,
      'exercises': exercises,
      'photoPath': photoPath,
      'discipline_code': disciplineCode,
      'discipline_season': disciplineSeason,
    };
  }

  static ShootingSession fromMap(Map<String, dynamic> map) {
    final rawSeries = map['series'];
    final List<Series> seriesList = (rawSeries is List)
        ? rawSeries
            .map((e) => Series.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <Series>[];
    return ShootingSession(
      id: map['id'] as int?,
      date: map['date'] != null ? DateTime.tryParse(map['date']) : null,
      weapon: map['weapon'] as String,
      caliber: map['caliber'] as String,
      series: seriesList,
      status: map['status'] as String? ?? 'réalisée',
      analyse: map['analyse'] as String?,
      synthese: map['synthese'] as String?,
      category: map['category'] as String? ?? 'entraînement',
      exercises: (map['exercises'] is List)
          ? (map['exercises'] as List).whereType<String>().toList()
          : <String>[],
      photoPath: map['photoPath'] as String?,
      disciplineCode: map['discipline_code'] as String?,
      disciplineSeason: map['discipline_season'] as String?,
    );
  }

  /// Indique si une photo de la cible est associée à cette session
  bool get hasPhoto => (photoPath != null && photoPath!.trim().isNotEmpty);

  /// Indique si une analyse coach est disponible
  bool get hasAnalysis => (analyse != null && analyse!.trim().isNotEmpty);

  /// Indique si une synthèse tireur est disponible
  bool get hasSynthese => (synthese != null && synthese!.trim().isNotEmpty);
  bool get hasDiscipline =>
      disciplineCode != null && disciplineCode!.trim().isNotEmpty;
}
