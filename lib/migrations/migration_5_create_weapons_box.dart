import 'package:hive/hive.dart';
import 'migration.dart';

/// Migration v5: crée la box 'weapons' (râtelier d'armes personnel, NT-008)
/// si elle n'existe pas encore.
class Migration5CreateWeaponsBox extends HiveMigration {
  @override
  int get toVersion => 5;

  @override
  Future<void> apply() async {
    if (!Hive.isBoxOpen('weapons')) {
      await Hive.openBox('weapons');
    }
  }
}
