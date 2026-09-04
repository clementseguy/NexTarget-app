# Tests et recette

## Tests automatisés

Depuis la racine du dépôt :

```bash
flutter analyze
flutter test
```

Pour la validation complète avant commit :

```bash
bash scripts/verify_before_commit.sh
```

Les tests suivent l'organisation de `lib/`. Les appels OAuth et Mistral sont mockés ; la suite ne doit effectuer aucun appel réseau réel.

## Recette manuelle

La source éditable est [cahier_recette.yaml](cahier_recette.yaml). Le fichier [cahier_recette.md](cahier_recette.md) est généré et ne doit pas être modifié à la main.

Après toute évolution visible :

```bash
dart run scripts/generate_cahier_recette.dart
git diff --exit-code docs/tests/cahier_recette.md
```

Le cahier couvre notamment les deux types de session, les statistiques 30/90 jours, les objectifs, exercices, préférences, sauvegardes, l'authentification durable et le Coach connecté uniquement. Il doit être rejoué avant une merge request vers `main`.

Les anciens guides OAuth séparés ont été supprimés : ils dupliquaient ces scénarios et décrivaient plusieurs flux qui ne sont plus implémentés.
