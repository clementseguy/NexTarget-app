import 'dart:async';
import 'dart:math';
import '../models/weapon.dart';
import '../models/shooting_session.dart';
import '../repositories/weapon_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/hive_session_repository.dart';
import '../utils/weapon_autocomplete.dart';

/// Erreur de validation du râtelier : nom vide (après trim) ou doublon
/// normalisé (espaces en début/fin ignorés, casse ignorée).
class WeaponValidationException implements Exception {
  final String message;
  WeaponValidationException(this.message);

  @override
  String toString() => message;
}

/// Gestion du râtelier d'armes personnel (NT-008) : CRUD simple, renommage
/// propagé aux sessions correspondantes (NT-008) et suppression sans effet
/// sur les sessions existantes.
class WeaponService {
  final WeaponRepository _weapons;
  final SessionRepository _sessions;

  WeaponService({WeaponRepository? weaponRepository, SessionRepository? sessionRepository})
      : _weapons = weaponRepository ?? HiveWeaponRepository(),
        _sessions = sessionRepository ?? HiveSessionRepository();

  // Sérialise les opérations « vérifier l'unicité puis écrire » (addWeapon,
  // renameWeapon) : sans cela, deux appels qui se chevauchent (double-tap,
  // appels concurrents) peuvent chacun lire « nom absent » avant qu'aucun des
  // deux `put` n'ait eu lieu, créant deux armes de même nom normalisé malgré
  // la garantie d'unicité documentée.
  Future<void> _writeLock = Future.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final previous = _writeLock;
    final completer = Completer<void>();
    _writeLock = completer.future;
    return previous.then((_) => action()).whenComplete(completer.complete);
  }

  String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rnd = Random().nextInt(1 << 20).toRadixString(36);
    return '${ts}_$rnd';
  }

  /// Liste triée par nom (insensible à la casse) pour un affichage stable.
  Future<List<Weapon>> listAll() async {
    final list = await _weapons.getAll();
    list.sort((a, b) => normalizeWeaponName(a.name).compareTo(normalizeWeaponName(b.name)));
    return list;
  }

  String _validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw WeaponValidationException("Le nom de l'arme est obligatoire.");
    }
    return trimmed;
  }

  Future<void> _checkUniqueName(String candidateName, {String? excludingId}) async {
    final all = await _weapons.getAll();
    final conflict = all.any((w) => w.id != excludingId && sameWeaponName(w.name, candidateName));
    if (conflict) {
      throw WeaponValidationException('Une arme porte déjà ce nom dans le râtelier.');
    }
  }

  /// Ajoute une arme au râtelier. Lève [WeaponValidationException] si le nom
  /// est vide après trim ou si une arme du même nom (normalisé) existe déjà.
  Future<Weapon> addWeapon(String name) => _serialized(() async {
        final trimmed = _validateName(name);
        await _checkUniqueName(trimmed);
        final weapon = Weapon(id: _generateId(), name: trimmed, createdAt: DateTime.now());
        await _weapons.put(weapon);
        return weapon;
      });

  /// Renomme [weapon] en [newName] et propage le changement aux sessions
  /// prévues et réalisées dont le champ `weapon` correspond exactement à
  /// l'ancien nom après normalisation (espaces en début/fin ignorés, casse
  /// ignorée) — sans toucher aux saisies seulement proches.
  ///
  /// Opération atomique du point de vue utilisateur : si une écriture échoue
  /// en cours de propagation, l'arme et les sessions déjà modifiées sont
  /// restaurées à leur état initial avant que l'exception ne soit relancée.
  Future<Weapon> renameWeapon(Weapon weapon, String newName) => _serialized(() async {
        final trimmed = _validateName(newName);
        await _checkUniqueName(trimmed, excludingId: weapon.id);

        final allSessions = await _sessions.getAll();
        final affected = allSessions.where((s) => sameWeaponName(s.weapon, weapon.name)).toList();
        final originalNames = <int?, String>{for (final s in affected) s.id: s.weapon};

        final renamed = weapon.copyWith(name: trimmed);
        final updatedSessions = <ShootingSession>[];
        try {
          await _weapons.put(renamed);
          for (final s in affected) {
            s.weapon = trimmed;
            await _sessions.update(s, preserveExistingSeriesIfEmpty: false);
            updatedSessions.add(s);
          }
          return renamed;
        } catch (e) {
          // Rollback complet : on restaure l'arme et les sessions déjà modifiées.
          try {
            await _weapons.put(weapon);
          } catch (_) {}
          for (final s in updatedSessions) {
            s.weapon = originalNames[s.id] ?? s.weapon;
            try {
              await _sessions.update(s, preserveExistingSeriesIfEmpty: false);
            } catch (_) {}
          }
          rethrow;
        }
      });

  /// Supprime l'arme du râtelier sans modifier aucune session existante.
  Future<void> deleteWeapon(String id) => _weapons.delete(id);
}
