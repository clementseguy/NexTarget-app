import 'package:hive_flutter/hive_flutter.dart';
import 'data/local_db_hive.dart';

Future<void> main() async {
  await Hive.initFlutter();
  await Hive.openBox('sessions');
  await LocalDatabaseHive().clearAllSessions();
  // Utilitaire CLI de dev : sortie console voulue.
  // ignore: avoid_print
  print('Toutes les sessions ont été supprimées.');
}