# AGENTS.md — NexTarget App

Instructions pour les agents travaillant sur l'application Flutter NexTarget.

## Projet et sources

- Flutter/Dart, Hive, `provider` et package historique `tir_sportif`.
- Application utilisable hors ligne ; compte facultatif pour le Coach IA.
- Identifiants de code en anglais ; UI et documentation en français.
- Le backlog canonique est dans `docs/backlog/`. Pour une US, commencer par :
  `bash scripts/us_context.sh NT-XXX`.
- Le backlog définit le quoi ; ce fichier définit les invariants techniques.

Lire uniquement la documentation utile à la tâche :

| Besoin | Référence |
|---|---|
| Produit livré | `docs/README.md`, puis `docs/features/` |
| Schéma ou migration Hive | `docs/tech/hive_schema.md` |
| Tests et recette | `docs/tests/README.md` |
| Compte ou Coach | `docs/features/compte-et-coach.md` |
| Serveur local Android | `docs/tech/serveur_local_emulateur_android.md` |
| Build APK | `docs/tech/build_apk_guide.md` |

Le code et les tests restent la référence du comportement exécuté. Ne pas lire
le journal ou les archives du backlog sans besoin historique explicite.

## Architecture

Sens des dépendances :
`screens/widgets → providers → services → repositories → models`.

- Aucun accès Hive direct depuis l'UI.
- Aucun I/O ou appel réseau dans `models/`.
- Toute configuration passe par `AppConfig`.
- La plupart des modèles utilisent `toMap`/`fromMap` ; seul `Goal` utilise des
  adapters générés. Ne pas généraliser un autre mode de persistance sans US.

## Invariants

### Persistance

- Les `typeId` et index `HiveField` sont stables, uniques et jamais réutilisés.
- Toute évolution structurelle est additive et fournit migration, registre et
  test conformément à `docs/tech/hive_schema.md`.
- Après modification d'un type généré, régénérer et committer les adapters.
- Les données historiques et sauvegardes doivent rester lisibles.

### HTTP, authentification et Coach

- Utiliser `AuthenticatedHttpClient` pour les appels authentifiés.
- Stocker les tokens dans `flutter_secure_storage` et ne jamais les journaliser.
- Conserver le retour OAuth par deep link `nextarget://callback`.
- `ServerCoachAnalysisService` est l'unique voie d'analyse Coach. Ne jamais
  ajouter de clé Mistral, prompt serveur ou appel Mistral direct dans l'app.

## Code et tests

- Respecter le style Dart, privilégier `final` et `const`.
- Utiliser `AppLogger`, jamais `print` ; ne pas ajouter `withOpacity`.
- Aucun émoji dans le code, l'UI, la documentation ou les messages Git.
- Toute logique nouvelle reçoit un test nominal et un cas d'erreur pertinent.
- Un changement visible met à jour la recette YAML puis le Markdown généré.
- Après changement d'une interface mockée, régénérer les mocks.
- Dans `test/support`, conserver les garanties de
  `FakeSessionRepository` et utiliser `captureError` pour les erreurs async.

## Validation

Pendant le développement, exécuter uniquement les tests ciblés utiles. À la
fin, lancer une seule fois `bash scripts/verify_before_commit.sh`, qui couvre
déjà analyse, schéma Hive et suite de tests. Ne pas relancer séparément ces
contrôles complets juste avant ou après sans modification du code.

## Livraison

- Flux Git : `main ← dev ← type/NT-XXX-slug` ; jamais de commit direct sur
  `main`.
- Une PR de feature vise `dev`. Inclure `NT-XXX` dans branche, commits et PR.
- Une PR qui clôt une US prépare son statut `FAIT` dans
  `docs/backlog/backlog-unifie.md` et une entrée `LIVRAISON` dans le journal.
- Modifier la définition, la priorité et le statut uniquement dans leurs
  fichiers canoniques décrits par `docs/backlog/README.md`.
- Préserver les changements utilisateur et ne jamais committer de secret.
