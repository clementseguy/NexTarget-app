import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/shooting_session.dart';
import '../services/session_service.dart';
import '../models/goal.dart';
import '../services/goal_service.dart';
import '../services/weapon_service.dart';

/// Service pour exporter / importer toutes les sessions sous forme JSON plat
/// Structure de fichier:
/// {
///   "format": "mycoach-sessions",
///   "version": 1,
///   "exported_at": "2025-09-27T12:00:00Z",
///   "count": N,
///   "sessions": [ { sessionMap... }, ... ]
/// }
class BackupService {
  final SessionService _sessionService;
  final GoalService _goalService;
  final WeaponService _weaponService;

  BackupService({
    SessionService? sessionService,
    GoalService? goalService,
    WeaponService? weaponService,
  })  : _sessionService = sessionService ?? SessionService(),
        _goalService = goalService ?? GoalService(),
        _weaponService = weaponService ?? WeaponService();
  
  /// Lire un fichier JSON.
  /// 
  /// Retourne: Le contenu du fichier sous forme de chaîne.
  Future<String> readJsonFile(String path) async {
    final file = File(path);
    return await file.readAsString();
  }

  Future<File> exportAllSessionsToJsonFile() async {
    final sessions = await _sessionService.getAllSessions();
    await _goalService.init();
    final goals = await _goalService.listAll();
    final weapons = await _weaponService.listAll();
    final data = {
      'format': 'mycoach-data',
      'version': 3,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'sessions_count': sessions.length,
      'goals_count': goals.length,
      'weapons_count': weapons.length,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'metric': g.metric.index,
        'comparator': g.comparator.index,
        'targetValue': g.targetValue,
        'status': g.status.index,
        'period': g.period.index,
        'createdAt': g.createdAt.toIso8601String(),
        'updatedAt': g.updatedAt.toIso8601String(),
        'lastProgress': g.lastProgress,
        'lastMeasuredValue': g.lastMeasuredValue,
        'priority': g.priority,
      }).toList(),
      // NT-008 : râtelier d'armes personnel (simple nom, cf. Weapon.toMap).
      'weapons': weapons.map((w) => w.toMap()).toList(),
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sessions_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    return file;
  }

  /// Importe les sessions depuis une chaîne JSON.
  /// - Les IDs existants sont ignorés pour éviter collisions: on remet id=null (laisser DB attribuer / conserver logique actuelle)
  /// - Retourne le nombre de sessions importées.
  Future<int> importSessionsFromJson(String jsonContent) async {
    final decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Fichier invalide (structure racine).');
    }
    if (decoded['format'] != 'mycoach-data') {
      throw FormatException('Format non reconnu.');
    }
    final sessionsRaw = decoded['sessions'];
    if (sessionsRaw is! List) {
      throw FormatException('Section sessions manquante.');
    }
    final sessions = <ShootingSession>[];
    for (final item in sessionsRaw) {
      if (item is! Map) {
        throw const FormatException('Entrée de session invalide.');
      }
      final map = Map<String, dynamic>.from(item);
      // Forcer id null pour éviter écrasement
      map['id'] = null;
      // Normaliser séries si besoin
      if (map['series'] is List) {
        map['series'] = (map['series'] as List).map((e) => e is Map ? Map<String,dynamic>.from(e) : e).toList();
      }
      sessions.add(ShootingSession.fromMap(map));
    }
    // Toutes les sessions sont validées avant la première écriture. Hive les
    // persiste ensuite dans une unique opération putAll.
    await _sessionService.addSessionsAtomically(sessions);
    // Import goals (facultatif si absent - compat ascendante)
    try {
      await _goalService.init();
      final goalsRaw = decoded['goals'];
      if (goalsRaw is List) {
        for (final g in goalsRaw) {
          if (g is! Map) continue;
          try {
            final goal = Goal(
              id: g['id']?.toString(),
              title: g['title']?.toString() ?? 'Sans titre',
              description: g['description']?.toString(),
              metric: GoalMetric.values[(g['metric'] as num?)?.toInt() ?? 0],
              comparator: GoalComparator.values[(g['comparator'] as num?)?.toInt() ?? 0],
              targetValue: (g['targetValue'] as num?)?.toDouble() ?? 0,
              status: GoalStatus.values[(g['status'] as num?)?.toInt() ?? 0],
              period: GoalPeriod.values[(g['period'] as num?)?.toInt() ?? 0],
              createdAt: DateTime.tryParse(g['createdAt'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(g['updatedAt'] ?? '') ?? DateTime.now(),
              lastProgress: (g['lastProgress'] as num?)?.toDouble(),
              lastMeasuredValue: (g['lastMeasuredValue'] as num?)?.toDouble(),
              priority: (g['priority'] as num?)?.toInt(),
            );
            await _goalService.addGoal(goal);
          } catch (_) {
            // ignore invalid goal
          }
        }
      }
    } catch (_) {}
    // Import du râtelier d'armes (NT-008) : facultatif si absent (anciens
    // exports sans râtelier) ; fusionne avec le râtelier local existant sans
    // l'effacer, en respectant les mêmes règles de validation/déduplication
    // normalisée que la saisie manuelle.
    final weaponsRaw = decoded['weapons'];
    if (weaponsRaw is List) {
      for (final w in weaponsRaw) {
        if (w is! Map) continue;
        final name = w['name']?.toString() ?? '';
        try {
          await _weaponService.addWeapon(name);
        } on WeaponValidationException {
          // Nom invalide ou doublon normalisé déjà présent : entrée ignorée
          // sans bloquer le reste de l'import. Toute autre exception (ex.
          // échec d'écriture Hive) n'est PAS avalée ici : elle remonte à
          // l'appelant pour être signalée à l'utilisateur, plutôt que de
          // terminer l'import en silence sur des armes manquantes.
        }
      }
    }
    return sessions.length;
  }

  /// Exporte toutes les données (sessions + objectifs) dans un fichier JSON
  /// à l'emplacement choisi par l'utilisateur (si la plateforme le permet).
  /// Retourne le fichier écrit ou lève une exception si annulé.
  Future<File?> exportAllSessionsToUserFolder({String? suggestedFileName}) async {
    final sessions = await _sessionService.getAllSessions();
    await _goalService.init();
    final goals = await _goalService.listAll();
    final weapons = await _weaponService.listAll();
    final data = {
      'format': 'mycoach-data',
      'version': 3,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'sessions_count': sessions.length,
      'goals_count': goals.length,
      'weapons_count': weapons.length,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'goals': goals.map((g) => {
        'id': g.id,
        'title': g.title,
        'description': g.description,
        'metric': g.metric.index,
        'comparator': g.comparator.index,
        'targetValue': g.targetValue,
        'status': g.status.index,
        'period': g.period.index,
        'createdAt': g.createdAt.toIso8601String(),
        'updatedAt': g.updatedAt.toIso8601String(),
        'lastProgress': g.lastProgress,
        'lastMeasuredValue': g.lastMeasuredValue,
        'priority': g.priority,
      }).toList(),
      // NT-008 : râtelier d'armes personnel (simple nom, cf. Weapon.toMap).
      'weapons': weapons.map((w) => w.toMap()).toList(),
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Sélection d'un dossier (sur Android utiliser FilePicker.directory)
    String? directoryPath;
    try {
      directoryPath = await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      // Certaines plateformes peuvent ne pas supporter (web). On renvoie null.
      return null;
    }
    if (directoryPath == null) {
      // Annulation utilisateur.
      return null;
    }
    final safeName = suggestedFileName ?? 'mycoach_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('$directoryPath/$safeName');
    await file.writeAsString(jsonString);
    return file;
  }
}
