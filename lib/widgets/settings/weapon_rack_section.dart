import 'package:flutter/material.dart';
import '../../models/weapon.dart';
import '../../services/weapon_service.dart';

/// Section CRUD du râtelier d'armes personnel, affichée dans
/// `Paramètres > Préférences Tir` (NT-008).
class WeaponRackSection extends StatefulWidget {
  final WeaponService? weaponService;

  const WeaponRackSection({super.key, this.weaponService});

  @override
  State<WeaponRackSection> createState() => _WeaponRackSectionState();
}

class _WeaponRackSectionState extends State<WeaponRackSection> {
  late final WeaponService _service = widget.weaponService ?? WeaponService();
  final _addController = TextEditingController();
  List<Weapon> _weapons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await _service.listAll();
    if (!mounted) return;
    setState(() {
      _weapons = list;
      _loading = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final name = _addController.text;
    try {
      await _service.addWeapon(name);
      _addController.clear();
      await _reload();
    } on WeaponValidationException catch (e) {
      _showSnack(e.message);
    }
  }

  Future<void> _rename(Weapon weapon) async {
    final controller = TextEditingController(text: weapon.name);
    final proposedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Renommer l'arme"),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );
    if (proposedName == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le renommage'),
        content: Text(
          'Renommer "${weapon.name}" en "${proposedName.trim()}" ? '
          'Les sessions correspondantes seront mises à jour.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.renameWeapon(weapon, proposedName);
      await _reload();
      _showSnack('Arme renommée.');
    } on WeaponValidationException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Erreur lors du renommage, aucune modification appliquée.');
    }
  }

  Future<void> _delete(Weapon weapon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Supprimer l'arme"),
        content: Text(
          'Supprimer "${weapon.name}" du râtelier ? '
          'Les sessions existantes ne seront pas modifiées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.deleteWeapon(weapon.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Râtelier d'armes", style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addController,
                decoration: const InputDecoration(labelText: 'Nouvelle arme'),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.add), tooltip: 'Ajouter', onPressed: _add),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (_weapons.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucune arme enregistrée.', style: TextStyle(color: Colors.white60)),
          )
        else
          ..._weapons.map(
            (w) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(w.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), tooltip: 'Renommer', onPressed: () => _rename(w)),
                  IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Supprimer', onPressed: () => _delete(w)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
