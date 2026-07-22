import '../constants/session_constants.dart';
import '../utils/caliber_autocomplete.dart';
import 'shooting_session.dart';

class SessionSetupTemplate {
  final String id;
  final String name;
  final String weapon;
  final String caliber;
  final String category;
  final String? disciplineCode;
  final String? disciplineSeason;
  final DateTime updatedAt;

  const SessionSetupTemplate({
    required this.id,
    required this.name,
    required this.weapon,
    required this.caliber,
    required this.category,
    this.disciplineCode,
    this.disciplineSeason,
    required this.updatedAt,
  });

  bool get isUsable =>
      weapon.trim().isNotEmpty ||
      caliber.trim().isNotEmpty ||
      (disciplineCode?.trim().isNotEmpty ?? false);

  String get summary {
    final parts = [
      if (weapon.trim().isNotEmpty) weapon.trim(),
      if (caliber.trim().isNotEmpty) caliber.trim(),
      if (category.trim().isNotEmpty) category.trim(),
      if (disciplineCode?.trim().isNotEmpty ?? false) disciplineCode!.trim(),
    ];
    return parts.join(' - ');
  }

  SessionSetupTemplate copyWith({
    String? id,
    String? name,
    String? weapon,
    String? caliber,
    String? category,
    String? disciplineCode,
    String? disciplineSeason,
    DateTime? updatedAt,
  }) {
    return SessionSetupTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      weapon: weapon ?? this.weapon,
      caliber: canonicalizeCaliber(caliber ?? this.caliber),
      category: category ?? this.category,
      disciplineCode: disciplineCode ?? this.disciplineCode,
      disciplineSeason: disciplineSeason ?? this.disciplineSeason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weapon': weapon,
      'caliber': canonicalizeCaliber(caliber),
      'category': category,
      'discipline_code': disciplineCode,
      'discipline_season': disciplineSeason,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInitialSessionData({required String status}) {
    return {
      'session': {
        'weapon': weapon,
        'caliber': canonicalizeCaliber(caliber),
        'status': status,
        'category': category,
        'series': [],
        'exercises': [],
        'discipline_code': disciplineCode,
        'discipline_season': disciplineSeason,
      },
      'series': [],
    };
  }

  static SessionSetupTemplate fromSession(
    ShootingSession session, {
    String? id,
    String? name,
    DateTime? updatedAt,
  }) {
    final canonicalCaliber = canonicalizeCaliber(session.caliber);
    return SessionSetupTemplate(
      id: id ?? 'setup_${DateTime.now().microsecondsSinceEpoch}',
      name: _cleanName(name) ?? _defaultName(session.weapon, canonicalCaliber),
      weapon: session.weapon.trim(),
      caliber: canonicalCaliber,
      category: session.category.trim().isEmpty
          ? SessionConstants.categoryEntrainement
          : session.category.trim(),
      disciplineCode: _cleanNullable(session.disciplineCode),
      disciplineSeason: _cleanNullable(session.disciplineSeason),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  static SessionSetupTemplate fromMap(Map<dynamic, dynamic> map) {
    final updatedRaw = map['updated_at'] ?? map['updatedAt'];
    return SessionSetupTemplate(
      id: _readString(map['id']) ??
          'setup_${DateTime.now().microsecondsSinceEpoch}',
      name: _readString(map['name']) ?? 'Setup',
      weapon: _readString(map['weapon']) ?? '',
      caliber: canonicalizeCaliber(_readString(map['caliber'])),
      category:
          _readString(map['category']) ?? SessionConstants.categoryEntrainement,
      disciplineCode: _readString(map['discipline_code']) ??
          _readString(map['disciplineCode']),
      disciplineSeason: _readString(map['discipline_season']) ??
          _readString(map['disciplineSeason']),
      updatedAt:
          DateTime.tryParse(updatedRaw?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static String _defaultName(String weapon, String caliber) {
    final parts = [
      if (weapon.trim().isNotEmpty) weapon.trim(),
      if (caliber.trim().isNotEmpty) caliber.trim(),
    ];
    return parts.isEmpty ? 'Setup' : parts.join(' - ');
  }

  static String? _cleanName(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _cleanNullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
