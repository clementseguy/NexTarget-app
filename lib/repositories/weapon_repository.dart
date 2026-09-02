import 'package:hive/hive.dart';
import '../models/weapon.dart';

abstract class WeaponRepository {
  Future<List<Weapon>> getAll();
  Future<void> put(Weapon weapon);
  Future<void> delete(String id);
  Future<void> clear();
}

class HiveWeaponRepository implements WeaponRepository {
  static const String defaultBoxName = 'weapons';
  final String _boxName;
  HiveWeaponRepository({String? boxName}) : _boxName = boxName ?? defaultBoxName;
  Box? _box;

  Future<Box> _ensureBox() async {
    if (_box != null) return _box!;
    _box = await Hive.openBox(_boxName);
    return _box!;
  }

  @override
  Future<void> clear() async {
    final b = await _ensureBox();
    await b.clear();
  }

  @override
  Future<void> delete(String id) async {
    final b = await _ensureBox();
    await b.delete(id);
  }

  @override
  Future<List<Weapon>> getAll() async {
    final b = await _ensureBox();
    return b.values.map((e) => Weapon.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  @override
  Future<void> put(Weapon weapon) async {
    final b = await _ensureBox();
    await b.put(weapon.id, weapon.toMap());
  }
}
