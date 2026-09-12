import 'package:hive/hive.dart';

import '../constants/session_constants.dart';
import '../models/coach_session_analysis.dart';
import 'migration.dart';

/// Convertit le débrief Markdown vers le contrat structuré NT-156.
class Migration14RemoveLegacyCoachAnalysis extends HiveMigration {
  @override
  int get toVersion => 14;

  @override
  Future<void> apply() async {
    final box = Hive.isBoxOpen(SessionConstants.hiveBoxSessions)
        ? Hive.box(SessionConstants.hiveBoxSessions)
        : await Hive.openBox(SessionConstants.hiveBoxSessions);
    final updates = <dynamic, dynamic>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map || raw['session'] is! Map) continue;
      final envelope = Map<String, dynamic>.from(raw);
      final session = Map<String, dynamic>.from(raw['session'] as Map);
      if (!session.containsKey('analyse')) continue;
      final legacyAnalysis = session['analyse'];
      final sessionUuid = session['sessionUuid'];
      if (session['coachAnalysis'] is! Map &&
          legacyAnalysis is String &&
          legacyAnalysis.trim().isNotEmpty &&
          sessionUuid is String &&
          sessionUuid.trim().isNotEmpty) {
        session['coachAnalysis'] = CoachSessionAnalysis.fromLegacyMarkdown(
          markdown: legacyAnalysis,
          sessionId: sessionUuid,
          generatedAt: _readDate(session['date']) ?? DateTime.utc(1970),
        ).toMap();
      }
      session.remove('analyse');
      envelope['session'] = session;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}

DateTime? _readDate(dynamic value) {
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}
