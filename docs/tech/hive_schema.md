# Vérification du schéma Hive

Le contrôle NT-077 compare, sans ouvrir aucune box, les migrations déclarées dans `lib/main.dart`, les fichiers de migration, les annotations `HiveType`/`HiveField` et le registre historique `tool/hive_schema_registry.json`.

Le registre réserve définitivement chaque `typeId` et chaque index de champ déjà utilisé. Sa version 2 distingue les types actifs par `status: active`, les champs actifs dans `fields` et les champs retirés dans `retiredFields`. Supprimer un modèle ou un champ ne libère donc jamais son identifiant : un retrait doit être déclaré explicitement dans le registre après une migration compatible. Toute évolution additive doit mettre à jour le code, la migration et le registre dans le même changement.

Le contrôle est bidirectionnel : une annotation absente alors que le type ou le champ reste actif dans le registre échoue également. Le parseur couvre les classes avec clauses `extends`, `with` ou `implements` et son test analyse notamment le modèle `Goal` réel du dépôt.

Exécuter depuis la racine du dépôt :

```bash
dart run tool/verify_hive_schema.dart
```

Le diagnostic indique le fichier, le type ou la version incohérente et le programme termine avec un code non nul. Ce contrôle est lancé par `scripts/verify_before_commit.sh` et par la CI SonarCloud. Il complète, sans les remplacer, les tests de migration utilisant des données historiques.
