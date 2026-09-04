import '../constants/session_constants.dart';
import 'series.dart';

/// Racine commune des sessions détaillées et libres.
abstract class ShootingSession {
  static const detailedType = 'detailed';
  static const simpleType = 'simple';

  String get sessionType;
  int? get id;
  set id(int? value);
  DateTime? get date;
  set date(DateTime? value);
  String get weapon;
  set weapon(String value);
  String get caliber;
  set caliber(String value);
  String get status;
  set status(String value);
  String? get synthese;
  set synthese(String? value);
  String get category;
  set category(String value);
  List<String> get exercises;
  set exercises(List<String> value);
  String? get photoPath;
  set photoPath(String? value);

  Map<String, dynamic> toMap();

  static ShootingSession fromMap(Map<String, dynamic> map) {
    final type = map['sessionType'];
    if (type == null || type == detailedType) {
      return DetailedShootingSession.fromMap(map);
    }
    if (type == simpleType) {
      return SimpleShootingSession.fromMap(map);
    }
    throw FormatException('Type de session inconnu: $type');
  }

  bool get hasPhoto => photoPath != null && photoPath!.trim().isNotEmpty;
  bool get hasSynthese => synthese != null && synthese!.trim().isNotEmpty;
}

class DetailedShootingSession implements ShootingSession {
  @override
  int? id;
  @override
  DateTime? date;
  @override
  String weapon;
  @override
  String caliber;
  List<Series> series;
  @override
  String status;
  String? analyse;
  @override
  String? synthese;
  @override
  String category;
  @override
  List<String> exercises;
  @override
  String? photoPath;

  DetailedShootingSession({
    this.id,
    this.date,
    required this.weapon,
    required this.caliber,
    required this.series,
    this.status = SessionConstants.statusRealisee,
    this.analyse,
    this.synthese,
    this.category = SessionConstants.categoryEntrainement,
    List<String>? exercises,
    this.photoPath,
  }) : exercises = exercises ?? <String>[];

  @override
  String get sessionType => ShootingSession.detailedType;

  @override
  Map<String, dynamic> toMap() => {
        'sessionType': sessionType,
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
      };

  factory DetailedShootingSession.fromMap(Map<String, dynamic> map) {
    final rawSeries = map['series'];
    final status = map['status'] as String? ?? SessionConstants.statusRealisee;
    if (!SessionConstants.detailedStatuses.contains(status)) {
      throw FormatException('État de session détaillée inconnu: $status');
    }
    final date = _readDate(map['date']);
    final weapon = map['weapon'] as String? ?? '';
    final caliber = map['caliber'] as String? ?? '';
    final category =
        map['category'] as String? ?? SessionConstants.categoryEntrainement;
    final parsedSeries = rawSeries is List
        ? rawSeries
            .whereType<Map>()
            .map((e) => Series.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <Series>[];
    if (status == SessionConstants.statusDraft &&
        (date == null ||
            weapon.trim().isEmpty ||
            caliber.trim().isEmpty ||
            !SessionConstants.categories.contains(category) ||
            parsedSeries.isEmpty)) {
      throw const FormatException('Brouillon de séance guidée invalide.');
    }
    return DetailedShootingSession(
      id: _readId(map['id']),
      date: date,
      weapon: weapon,
      caliber: caliber,
      series: parsedSeries,
      status: status,
      analyse: map['analyse'] as String?,
      synthese: map['synthese'] as String?,
      category: category,
      exercises: _readExercises(map['exercises']),
      photoPath: map['photoPath'] as String?,
    );
  }

  bool get hasAnalysis => analyse != null && analyse!.trim().isNotEmpty;

  bool get isDraft => status == SessionConstants.statusDraft;

  int get completedSeriesCount =>
      series.where((item) => item.isCompleted).length;

  int get completedShotCount => series
      .where((item) => item.isCompleted)
      .fold(0, (total, item) => total + item.shotCount);

  @override
  bool get hasPhoto => photoPath != null && photoPath!.trim().isNotEmpty;

  @override
  bool get hasSynthese => synthese != null && synthese!.trim().isNotEmpty;
}

class SimpleShootingSession implements ShootingSession {
  @override
  int? id;
  @override
  DateTime? date;
  @override
  String weapon;
  @override
  String caliber;
  int shotCount;
  double distance;
  @override
  String status;
  @override
  String? synthese;
  @override
  String category;
  @override
  List<String> exercises;
  @override
  String? photoPath;

  SimpleShootingSession({
    this.id,
    required DateTime this.date,
    required this.weapon,
    required this.caliber,
    required this.shotCount,
    required num distance,
    this.synthese,
    this.category = SessionConstants.categoryEntrainement,
    List<String>? exercises,
    this.photoPath,
  })  : distance = distance.toDouble(),
        status = SessionConstants.statusRealisee,
        exercises = exercises ?? <String>[] {
    validate();
  }

  @override
  String get sessionType => ShootingSession.simpleType;

  void validate() {
    if (date == null) throw ArgumentError('La date est obligatoire.');
    if (weapon.trim().isEmpty) throw ArgumentError('L’arme est obligatoire.');
    if (caliber.trim().isEmpty) {
      throw ArgumentError('Le calibre est obligatoire.');
    }
    if (shotCount <= 0) {
      throw ArgumentError('Le nombre de tirs doit être strictement positif.');
    }
    if (distance <= 0 || distance != distance.truncateToDouble()) {
      throw ArgumentError(
        'La distance doit être un entier strictement positif.',
      );
    }
    if (!SessionConstants.categories.contains(category)) {
      throw ArgumentError('Catégorie de session libre inconnue: $category');
    }
    if (status != SessionConstants.statusRealisee) {
      throw ArgumentError('Une session libre doit être réalisée.');
    }
  }

  @override
  Map<String, dynamic> toMap() => {
        'sessionType': sessionType,
        'id': id,
        'date': date?.toIso8601String(),
        'weapon': weapon,
        'caliber': caliber,
        'shotCount': shotCount,
        'distance': distance,
        'status': SessionConstants.statusRealisee,
        'synthese': synthese,
        'category': category,
        'exercises': exercises,
        'photoPath': photoPath,
      };

  factory SimpleShootingSession.fromMap(Map<String, dynamic> map) {
    final date = _readDate(map['date']);
    if (date == null) {
      throw const FormatException('Date de session libre invalide.');
    }
    final rawShotCount = map['shotCount'] as num?;
    final distance = map['distance'] as num?;
    if (rawShotCount == null ||
        rawShotCount.toDouble() != rawShotCount.truncateToDouble() ||
        distance == null) {
      throw const FormatException(
          'Champs numériques de session libre manquants.');
    }
    if (map['status'] != null &&
        map['status'] != SessionConstants.statusRealisee) {
      throw const FormatException('Une session libre doit être réalisée.');
    }
    try {
      return SimpleShootingSession(
        id: _readId(map['id']),
        date: date,
        weapon: map['weapon'] as String? ?? '',
        caliber: map['caliber'] as String? ?? '',
        shotCount: rawShotCount.toInt(),
        distance: distance,
        synthese: map['synthese'] as String?,
        category:
            map['category'] as String? ?? SessionConstants.categoryEntrainement,
        exercises: _readExercises(map['exercises']),
        photoPath: map['photoPath'] as String?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
          error.message?.toString() ?? 'Session libre invalide.');
    }
  }

  @override
  bool get hasPhoto => photoPath != null && photoPath!.trim().isNotEmpty;

  @override
  bool get hasSynthese => synthese != null && synthese!.trim().isNotEmpty;
}

int? _readId(dynamic value) => value is num ? value.toInt() : null;

DateTime? _readDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _readExercises(dynamic value) =>
    value is List ? value.whereType<String>().toList() : <String>[];

extension ShootingSessionTypeAccess on ShootingSession {
  bool get isSimple => this is SimpleShootingSession;

  /// Vue en lecture des séries détaillées. Une session libre n'en expose
  /// aucune et n'en persiste aucune.
  List<Series> get detailedSeries => this is DetailedShootingSession
      ? (this as DetailedShootingSession).series
      : const <Series>[];

  /// Alias de compatibilité en lecture pour les agrégateurs existants.
  List<Series> get series => detailedSeries;

  set series(List<Series> value) {
    if (this is! DetailedShootingSession) {
      throw UnsupportedError('Une session libre ne possède pas de séries.');
    }
    (this as DetailedShootingSession).series = value;
  }

  String? get analyse => this is DetailedShootingSession
      ? (this as DetailedShootingSession).analyse
      : null;

  bool get hasAnalysis => analyse != null && analyse!.trim().isNotEmpty;

  int get totalShotCount => this is SimpleShootingSession
      ? (this as SimpleShootingSession).shotCount
      : detailedSeries.fold(0, (total, series) => total + series.shotCount);
}
