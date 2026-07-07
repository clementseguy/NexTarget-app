# AGENTS.md — NexTarget App

Instructions pour les agents de développement IA travaillant sur ce dépôt.
Objectif : produire du code cohérent avec l'existant et **maintenir un niveau de
qualité élevé** (ce repo doit pouvoir être partagé sans réserve).

## Projet

NexTarget est le carnet de tir sportif du tireur solo : saisie des sessions
(armes, calibres, séries, groupements), statistiques, objectifs, exercices, et un
**coach IA** qui analyse les séances. L'app fonctionne **hors-ligne** ; un compte
(OAuth) est **optionnel** et sert à sécuriser les appels IA (proxy serveur).

- **Stack** : Flutter / Dart (SDK `>=3.0.0 <4.0.0`), stockage local **Hive**
- **State management** : `provider` (`ChangeNotifier`)
- **Backend** : NexTarget-server (OAuth + proxy Coach IA), consommé via `http`
- **Version** : voir `pubspec.yaml` (`version:`) — actuellement 0.4.1
- **Package id historique** : `tir_sportif` (branding affiché = *NexTarget*, ne pas renommer le package)
- **Langue** : identifiants en **anglais** ; commentaires, docs et **UI en français** ; certaines valeurs métier sont en français (`"réalisée"`, `"entraînement"`) — les conserver telles quelles.

## Source de vérité produit

Le **quoi/pourquoi** vit dans le backlog unifié, pas ici :

- **Backlog** : [`docs/backlog/backlog-unifie.md`](docs/backlog/backlog-unifie.md) — items `NT-XXX`.
- **Vue app** : [`docs/backlog/vue-app.md`](docs/backlog/vue-app.md).
- **Gouvernance / DoD / convention d'IDs** : [`docs/backlog/README.md`](docs/backlog/README.md).
- **Écarts & décisions** : [`docs/backlog/incoherences.md`](docs/backlog/incoherences.md).

En cas de conflit entre ce fichier et le backlog sur le périmètre produit, **le
backlog prime**. Cet `AGENTS.md` fait autorité sur le **comment** (architecture,
conventions, qualité).

## Architecture (`lib/`)

```
lib/
  main.dart          # Bootstrap : AppConfig, Hive.initFlutter, migrations, adapters, providers
  app/               # MyApp (MaterialApp, thèmes, routing racine)
  config/            # AppConfig (singleton) — charge assets/config.yaml + secrets
  constants/         # Constantes (noms de box Hive, catégories, etc.)
  models/            # Modèles de domaine (majoritairement toMap/fromMap ; Goal en @HiveType)
  repositories/      # Accès données Hive (une box par agrégat)
  services/          # Logique métier (stats, coach, backup, auth, préférences…)
  providers/         # État applicatif (Navigation, Settings, Auth) via ChangeNotifier
  interfaces/        # Contrats/abstractions
  navigation/        # Navigation
  screens/           # Écrans (UI)
  widgets/           # Composants réutilisables
  forms/             # Contrôleurs/état de formulaires
  theme/             # Thèmes visuels
  migrations/        # MigrationRunner + migrations de schéma Hive versionnées
  utils/             # Utilitaires transverses
```

### Règles d'architecture
- **Sens des dépendances** : `screens/widgets → providers → services → repositories → models`. Ne jamais faire remonter (un service n'importe pas un écran, un modèle ne dépend de rien).
- **Pas d'accès Hive direct depuis l'UI** : passer par un repository, puis un service.
- **Modèles = données** : pas d'I/O ni d'appel réseau dans `models/` (leur rôle : structure + `toMap`/`fromMap`).
- **Persistance Hive** : la plupart des modèles sont stockés en `Map<String, dynamic>` (sérialisation manuelle `toMap`/`fromMap`). Seul `Goal` utilise l'adapter généré (`@HiveType`, `part 'goal.g.dart'`).
- **Config & secrets** : tout passe par `AppConfig` (charge `assets/config.yaml`). La clé Mistral vient de `dart-define` / env / `config.local.yaml` — **jamais commitée**.

## Hive — règles impératives

Casser la persistance = corrompre les données des utilisateurs. Traiter avec soin.

1. **typeIds stables et uniques.** Les `@HiveType(typeId:)` (Goal : 40–44) ne se
   réutilisent **jamais**. Nouveau type persisté → nouveau typeId non utilisé.
2. **Champs additifs.** Ajouter un champ = nouvel index `@HiveField`, jamais
   réutiliser un ancien index. Ne pas réordonner/supprimer des champs existants.
3. **Migration obligatoire pour tout changement de schéma structurel.** Ajouter une
   `HiveMigration` (`toVersion` croissant) et l'enregistrer dans le `MigrationRunner`
   de `main.dart`. Fournir un test de migration (cf. `test/migrations/`).
4. **Après modif d'un modèle `@HiveType`** : régénérer les adapters
   (`dart run build_runner build --delete-conflicting-outputs`) et committer le
   `*.g.dart`.
5. **Ne pas ouvrir une box avant que migrations + adapters soient prêts** (ordre de
   `main.dart` : `AppConfig.load` → `Hive.initFlutter` → migrations → `registerAdapter` → `openBox`).

## Conventions de code

- **Style Dart standard** : `lowerCamelCase` (variables/fonctions), `UpperCamelCase`
  (types), `snake_case.dart` (fichiers), un widget/écran par fichier.
- **`const` partout où c'est possible** (widgets, littéraux) — c'est aussi une
  attente de l'analyse statique.
- **Immutabilité** : privilégier `final` ; modèles avec `copyWith` quand pertinent
  (cf. `Exercise`).
- **Async** : `async/await`, gérer explicitement les erreurs réseau (voir les
  services coach : `TimeoutException`, `SocketException`, codes HTTP).
- **Logging** : utiliser `services/logger.dart` (`AppLogger`), **pas** `print`.
  ⚠️ Il reste des `print('[DEBUG] …')` hérités dans le code coach : ne pas en
  ajouter, et les retirer si tu touches ces fichiers.
- **Dépréciations** : ne pas introduire de `withOpacity(` (déprécié ; le
  pré-commit le signale) — préférer `.withValues(...)`.
- **UI** : Material, textes en français, thématisable (`theme/`).

## HTTP & Auth
- Client HTTP : package `http`. Pour les appels **authentifiés**, utiliser
  `AuthenticatedHttpClient` (injecte le JWT), pas un `http.Client` nu.
- Tokens stockés via `flutter_secure_storage`. Ne jamais logguer un token ni une clé.
- OAuth : flow délégué au serveur, retour par **deep link** `nextarget://callback?token=…`
  (`app_links`). Ne pas réimplémenter le flow ailleurs.
- **Coach IA** : décision produit (2026-07-07) = **coach connecté uniquement**
  (cf. NT-061). Cible : ne garder que `ServerCoachAnalysisService`, **supprimer**
  `CoachAnalysisService` (Mistral direct) et toute clé Mistral côté client. Ne pas
  réintroduire d'appel Mistral direct. Le reste de l'app doit rester utilisable
  hors-ligne.

## Tests

- **Framework** : `flutter_test` + `mockito` (mocks générés → `*.mocks.dart` via
  `build_runner`).
- **Organisation** : `test/` reflète `lib/` (`test/models`, `test/services`,
  `test/repositories`, `test/screens`, `test/forms`, `test/migrations`). ~67 fichiers
  de test aujourd'hui — **maintenir cette couverture**.
- **Attendu pour toute évolution** : au moins un test nominal + un cas d'erreur.
  Nouveau service/logique → test unitaire. Nouvel écran → widget test. Changement de
  schéma → test de migration.
- **Lancement** : `flutter test` (tout) ou `flutter test --coverage` (rapport LCOV
  pour SonarCloud).
- **Régénérer les mocks** après changement d'interface mockée :
  `dart run build_runner build --delete-conflicting-outputs`.

## Qualité & CI

- **Analyse statique** : `flutter analyze` doit passer **sans warning**.
  ⚠️ Aujourd'hui `flutter_lints` est **désactivé** dans `analysis_options.yaml`
  (`include` commenté) — durcir le ruleset est une tâche qualité (NT-051). Si tu
  actives un ruleset, corrige les warnings dans le même lot.
- **SonarCloud** : workflow `.github/workflows/sonarcloud.yml` (push `dev`/`main`,
  PR vers `main`, run quotidien). Quality Gate visé **≥ B**, couverture importée via
  `coverage/lcov.info`. Ne pas dégrader le Quality Gate.
- **Cahier de recette** : `docs/tests/cahier_recette.md` généré depuis
  `docs/specs/cahier_recette.yaml` (`scripts/generate_cahier_recette.dart`). Le
  **rejouer avant toute MR vers `main`** ; si un comportement visible change, mettre
  à jour le YAML **et** régénérer.

## Avant de committer (checklist)

1. `bash scripts/verify_before_commit.sh` (lance `flutter analyze` + `flutter test` ;
   `… fast` pour un sous-ensemble rapide).
2. Adapters régénérés/committés si un modèle `@HiveType` a changé.
3. Migration + test de migration ajoutés si le schéma Hive a changé.
4. Statut de l'item mis à jour dans `docs/backlog/` + `CHANGELOG.md`.
5. Aucun secret, token ou clé dans le diff ; aucun nouveau `print`/`withOpacity`.

## Workflow Git (rappel gouvernance)

- **Branche par item** : `type/NT-XXX-slug` (ex. `feat/NT-061-coach-connecte-uniquement`).
- **Commit** : sujet préfixé par l'ID — `feat(coach): NT-032 persona coach cool`.
- **PR vers `main`** : titre `[NT-XXX] …`, corps listant les IDs + critères
  d'acceptation cochés ; la CI SonarCloud s'exécute sur la PR.
- **Definition of Done** : voir [`docs/backlog/README.md`](docs/backlog/README.md).

## Décisions intentionnelles (ne pas « corriger »)

- **Package id `tir_sportif`** conservé (le branding NexTarget est au niveau UI).
- **Stockage Map + `toMap`/`fromMap`** pour la plupart des modèles (seul `Goal` en
  adapter généré) — choix assumé, ne pas tout migrer sans raison.
- **Coach à double chemin** = état **transitoire** ; la cible est *connecté
  uniquement* (NT-061), pas un design pérenne.
- **Valeurs métier en français** dans les données (`status`, `category`).

## Commandes de référence

```bash
flutter pub get                 # dépendances
flutter run                     # lancer l'app
flutter test                    # tous les tests
flutter test --coverage         # tests + couverture (lcov)
flutter analyze                 # analyse statique
dart run build_runner build --delete-conflicting-outputs   # (ré)générer adapters & mocks
bash scripts/verify_before_commit.sh        # garde pré-commit (full)
bash scripts/verify_before_commit.sh fast   # variante rapide
dart run scripts/generate_cahier_recette.dart   # régénérer le cahier de recette
```

## Documentation de référence
- [`docs/backlog/`](docs/backlog/) — backlog unifié, vues, gouvernance (source de vérité produit)
- [`docs/tech/`](docs/tech/) — specs techniques (API serveur, charts, build APK)
- [`docs/features/`](docs/features/) — specs fonctionnelles (statistiques, objectifs…)
- [`CHANGELOG.md`](CHANGELOG.md) — historique des changements
