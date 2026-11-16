import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../constants/session_constants.dart';
import 'migration.dart';

/// Migration NT-156 : ajoute l'UUID de synchronisation et le débrief structuré.
class Migration13AddCoachSessionContract extends HiveMigration {
  @override
  int get toVersion => 13;

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
      final currentUuid = session['sessionUuid'];
      if (currentUuid is! String || currentUuid.trim().isEmpty) {
        session['sessionUuid'] = const Uuid().v4();
      }
      session.putIfAbsent('coachAnalysis', () => null);
      envelope['session'] = session;
      updates[key] = envelope;
    }
    if (updates.isNotEmpty) await box.putAll(updates);
  }
}
