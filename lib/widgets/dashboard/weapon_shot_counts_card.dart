import 'package:flutter/material.dart';
import '../../models/weapon.dart';

/// Compteur de tirs par arme du râtelier (NT-017), affiché en toute dernière
/// position de `Statistiques > Avancé`. Simple liste texte, sans graphe :
/// une ligne par arme du râtelier, y compris à zéro.
class WeaponShotCountsCard extends StatelessWidget {
  final List<Weapon> weapons;
  final Map<String, int> shotCountsByWeaponId;
  final bool isLoading;

  const WeaponShotCountsCard({
    super.key,
    required this.weapons,
    required this.shotCountsByWeaponId,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tirs par arme', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Total des tirs des sessions réalisées, essais compris.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else if (weapons.isEmpty)
              const Text('Aucune arme dans le râtelier.', style: TextStyle(color: Colors.white60))
            else
              ...weapons.map(
                (w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(w.name)),
                      Text(
                        '${shotCountsByWeaponId[w.id] ?? 0} tirs',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
