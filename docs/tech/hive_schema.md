# Vérification du schéma Hive

Le contrôle NT-077 compare, sans ouvrir aucune box, les migrations déclarées dans `lib/main.dart`, les fichiers de migration, les annotations `HiveType`/`HiveField` et le registre historique `tool/hive_schema_registry.json`.

Le registre réserve définitivement chaque `typeId` et chaque index de champ déjà utilisé. Supprimer un modèle ou un champ ne libère donc jamais son identifiant. Toute évolution additive doit mettre à jour le code, la migration et le registre dans le même changement.

Exécuter depuis la racine du dépôt :

```bash
dart run tool/verify_hive_schema.dart
```

Le diagnostic indique le fichier, le type ou la version incohérente et le programme termine avec un code non nul. Ce contrôle est lancé par `scripts/verify_before_commit.sh` et par la CI SonarCloud. Il complète, sans les remplacer, les tests de migration utilisant des données historiques.
