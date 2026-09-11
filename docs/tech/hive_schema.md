# Vérification du schéma Hive

Le contrôle NT-077 compare, sans ouvrir aucune box, les migrations déclarées dans `lib/main.dart`, les fichiers de migration, les annotations `HiveType`/`HiveField` et le registre historique `tool/hive_schema_registry.json`.

Le registre réserve définitivement chaque `typeId` et chaque index de champ déjà utilisé. Sa version 2 distingue les types actifs par `status: active`, les champs actifs dans `fields` et les champs retirés dans `retiredFields`. Supprimer un modèle ou un champ ne libère donc jamais son identifiant : un retrait doit être déclaré explicitement dans le registre après une migration compatible. Toute évolution additive doit mettre à jour le code, la migration et le registre dans le même changement.

Le contrôle est bidirectionnel : une annotation absente alors que le type ou le champ reste actif dans le registre échoue également. Le parseur couvre les classes avec clauses `extends`, `with` ou `implements` et son test analyse notamment le modèle `Goal` réel du dépôt.

Exécuter depuis la racine du dépôt :

```bash
dart run tool/verify_hive_schema.dart
```

Le diagnostic indique le fichier, le type ou la version incohérente et le programme termine avec un code non nul. Ce contrôle est lancé par `scripts/verify_before_commit.sh` et par la CI SonarCloud. Il complète, sans les remplacer, les tests de migration utilisant des données historiques.

## Migration de l'exercice principal

La migration Hive v10 remplace, dans chaque enveloppe de session, la liste
historique `exercises` par `exerciseId`. Le premier identifiant dans l'ordre
persisté est conservé ; les suivants sont ignorés. Une liste absente, vide ou
invalide produit une valeur `null`. Les séries et les autres champs de la session
ne sont pas modifiés. La désérialisation conserve le même fallback pour les
sauvegardes historiques importées après la migration locale.

## Qualification de l'exécution d'un exercice

La migration Hive v11 ajoute une valeur `exerciseExecution` vide aux enveloppes
de sessions qui référencent déjà un `exerciseId`. Les sessions sans exercice,
les qualifications existantes, les séries et les autres champs ne sont pas
réécrits. La désérialisation accepte également l'absence de cette structure et
ignore ses valeurs inconnues sans inventer de réponse.

## Provenance des exercices

La migration Hive v12 ajoute `origin: personal` aux exercices qui ne portent
pas encore de provenance. Une valeur existante, notamment `coach_catalog`, est
préservée sans réécriture. La désérialisation applique le même défaut aux
sauvegardes historiques importées après la migration locale et rejette les
valeurs étrangères au contrat partagé.

## Contrat du débrief Coach

La migration Hive v13 ajoute à chaque session un `sessionUuid` stable et un
champ `coachAnalysis` nullable. Les UUID existants et les débriefs déjà
structurés sont préservés. Le modèle génère également un UUID lors de la lecture
d'une sauvegarde historique qui n'en contient pas. Le champ historique
`analyse` n'est pas supprimé afin de conserver l'affichage des réponses Markdown
antérieures à NT-156.
