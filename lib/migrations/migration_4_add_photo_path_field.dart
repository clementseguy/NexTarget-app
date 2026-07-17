import 'package:hive/hive.dart';
import 'migration.dart';

/// Migration v4: ensure each session map has a 'photoPath' key (null if absent).
/// Support de NT-005 (photo de la cible attachée à la session).
class Migration4AddPhotoPathField extends HiveMigration {
  @override
  int get toVersion => 4;

  @override
  Future<void> apply() async {
    // Sessions stored in 'sessions' box as maps {session: {...}, series: [...]}
    if (!Hive.isBoxOpen('sessions')) return; // nothing to do if not opened yet
    final box = Hive.box('sessions');
    final keys = box.keys.toList();
    for (final k in keys) {
      final raw = box.get(k);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final session = Map<String, dynamic>.from(map['session']);
        // Add photoPath key if missing, sans écraser une valeur existante.
        session.putIfAbsent('photoPath', () => null);
        map['session'] = session;
        await box.put(k, map);
      }
    }
  }
}
