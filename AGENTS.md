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
- **Version** : voir `pubspec.yaml` (`version:`) — actuellement 0.6.0
- **Package id historique** : `tir_sportif` (branding affiché = *NexTarget*, ne pas renommer le package)
- **Langue** : identifiants en **anglais** ; commentaires, docs et **UI en français** ; certaines valeurs métier sont en français (`"réalisée"`, `"entraînement"`) — les conserver telles quelles.

## Source de vérité produit

Le **quoi/pourquoi** vit dans le backlog unifié, pas ici :

- **Backlog** : [`docs/backlog/backlog-unifie.md`](docs/backlog/backlog-unifie.md) — items `NT-XXX`.
- **Vue app** : [`docs/backlog/vue-app.md`](docs/backlog/vue-app.md).
- **Vue serveur canonique** : [`docs/backlog/vue-serveur.md`](docs/backlog/vue-serveur.md).
- **Gouvernance / DoD / convention d'IDs** : [`docs/backlog/README.md`](docs/backlog/README.md).

Le backlog et ses vues se modifient **uniquement dans `NexTarget-app`**. Le repo
`NexTarget-server` peut pointer vers la vue serveur canonique, mais ne maintient
ni copie synchronisée ni backlog concurrent : aucune synchronisation inverse
depuis le serveur n'est attendue.

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
- **Config & secrets** : tout passe par `AppConfig` (charge `assets/config.yaml`). Depuis NT-061, **aucun secret côté client** (la clé Mistral vit côté serveur) ; `config.local.yaml` ne sert plus qu'aux surcharges locales non sensibles (ex. calibres).

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
  ATTENTION : il reste des `print('[DEBUG] …')` hérités dans le code coach -> ne pas en
  ajouter, et les retirer si tu touches ces fichiers.
- **Dépréciations** : ne pas introduire de `withOpacity(` (déprécié ; le
  pré-commit le signale) — préférer `.withValues(...)`.
- **UI** : Material, textes en français, thématisable (`theme/`).
- **Aucun émoji** : ni dans le code (commentaires, docstrings, messages de log,
  textes affichés à l'utilisateur), ni dans la documentation (`*.md`, `AGENTS.md`
  inclus), ni dans les messages de commit/PR. Ce dépôt est de la documentation
  technique, pas un post LinkedIn — texte brut uniquement.

## HTTP & Auth
- Client HTTP : package `http`. Pour les appels **authentifiés**, utiliser
  `AuthenticatedHttpClient` (injecte le JWT), pas un `http.Client` nu.
- Tokens stockés via `flutter_secure_storage`. Ne jamais logguer un token ni une clé.
- OAuth : flow délégué au serveur, retour par **deep link** `nextarget://callback?token=…`
  (`app_links`). Ne pas réimplémenter le flow ailleurs.
- **Coach IA** : **coach connecté uniquement** (NT-061, livré) —
  `ServerCoachAnalysisService` est l'unique chemin d'analyse ; il n'existe plus de
  clé Mistral ni d'appel Mistral direct côté client. **Ne jamais les réintroduire.**
  Le reste de l'app reste utilisable hors-ligne.

## Tests

- **Framework** : `flutter_test` + `mockito` (mocks générés → `*.mocks.dart` via
  `build_runner`).
- **Organisation** : `test/` reflète `lib/` (`test/models`, `test/services`,
  `test/repositories`, `test/screens`, `test/forms`, `test/migrations`). ~103 fichiers
  de test aujourd'hui — **maintenir cette couverture**.
- **Attendu pour toute évolution** : au moins un test nominal + un cas d'erreur.
  Nouveau service/logique → test unitaire. Nouvel écran → widget test. Changement de
  schéma → test de migration.
- **Fakes de repository (`test/support/`, NT-058)** : pour un `SessionRepository`
  en mémoire, utiliser/étendre `test/support/fake_session_repository.dart`
  (`FakeSessionRepository`) plutôt que d'écrire un nouveau fake ad hoc.
  **Impératif : `getAll()` doit cloner** chaque élément (ex.
  `ShootingSession.fromMap(s.toMap())`), jamais `List.of(...)` seul — un fake qui
  partage les références d'objets mutables peut laisser un état incohérent si le
  code testé mute un champ avant un `update()` qui échoue (rollback), contrairement
  à `HiveSessionRepository` qui reconstruit toujours des objets frais. Ce défaut a
  provoqué un débogage long et trompeur lors de NT-008 (le message d'échec de
  `expect()` semblait accuser le mauvais code). Un stub en lecture seule qui
  renvoie une liste fixe (sans `insert`/`update` réels) n'a pas besoin de ce
  clonage et peut rester ad hoc.
- **Erreurs async (`test/support/async_test_helpers.dart`)** : pour vérifier
  qu'une fonction `async` lève une exception, utiliser `captureError(() => ...)`
  (awaited) plutôt que `expect(() => asyncFn(), throwsA(...))` **non awaité** —
  ce dernier peut laisser un travail asynchrone en suspens qui se résout pendant
  le test suivant, avec un message d'échec attribué à la mauvaise assertion.
  `await expectLater(future, throwsA(...))` (Future direct, pas de closure) reste
  une alternative correcte.
- **Lancement** : `flutter test` (tout) ou `flutter test --coverage` (rapport LCOV
  pour SonarCloud). Pendant un débogage, cibler un fichier/test précis
  (`flutter test test/xxx_test.dart --plain-name "..."`) avant de relancer toute
  la suite.
- **Régénérer les mocks** après changement d'interface mockée :
  `dart run build_runner build --delete-conflicting-outputs`.

## Qualité & CI

- **Analyse statique** : `flutter_lints` est **actif** (`analysis_options.yaml`,
  NT-051) et `flutter analyze` doit rester à **zéro issue** (infos comprises) —
  la CI exécute `flutter analyze --fatal-infos`. Pas de nouveau `// ignore:`
  sans justification en commentaire.
- **SonarCloud** : workflow `.github/workflows/sonarcloud.yml` (push `dev`/`main`,
  PR vers `main`, run quotidien). Couverture importée via `coverage/lcov.info`.
  **Le Quality Gate SonarCloud (check « SonarCloud Code Analysis ») est
  informatif, non bloquant** (décision 2026-07-09, gate par défaut 80 % nouveau
  code non personnalisable en compte gratuit — inadapté à un diff UI-heavy).
  Le check bloquant des PR est le job **« Test & SonarCloud »** (analyze
  --fatal-infos + tests). Règle qualité : tout nouveau service/logique reçoit
  des tests (nominal + erreur) ; viser ~60 % sur le nouveau code, sans y
  sacrifier des tests de layout à faible valeur.
- **Cahier de recette** : `docs/tests/cahier_recette.md` généré depuis
  `docs/tests/cahier_recette.yaml` (`scripts/generate_cahier_recette.dart`). Le
  **rejouer avant toute MR vers `main`** ; si un comportement visible change, mettre
  à jour le YAML **et** régénérer.

## Avant de committer (checklist)

1. `bash scripts/verify_before_commit.sh` (lance `flutter analyze` + `flutter test` ;
   `… fast` pour un sous-ensemble rapide).
2. Adapters régénérés/committés si un modèle `@HiveType` a changé.
3. Migration + test de migration ajoutés si le schéma Hive a changé.
4. Statut de l'item mis à jour dans `docs/backlog/` + `CHANGELOG.md`.
5. Aucun secret, token ou clé dans le diff ; aucun nouveau `print`/`withOpacity`.
6. Aucun émoji dans le diff (code, doc, `CHANGELOG.md`, message de commit/PR).

## Workflow Git (rappel gouvernance)

- **Flux de branches (Git flow)** : `main` ← `dev` ← `feature/<code_nom_feature>`.
  - **`main`** : branche de **production**, taggée à chaque **release**. Jamais de commit direct.
  - **`dev`** : branche d'**intégration** ; reçoit les features validées.
  - Toute branche de développement part de **`dev`** (jamais de `main`) et suit la
    convention `type/NT-XXX-slug` (ex. `feature/NT-061-coach-connecte-uniquement`).
    Pour un lot multi-features, une branche `features/<codes_noms_features>` regroupant
    les IDs concernés est acceptée.
- **Cycle de développement d'une (ou plusieurs) feature(s)** :
  1. Créer la branche depuis **`dev`**.
  2. Développer, puis ouvrir une **PR de la branche vers `dev`** (merge après revue + CI verte).
  3. Pour livrer : ouvrir une **PR de `dev` vers `main`**, accompagnée d'une **release**
     (bump de version dans `pubspec.yaml`, `CHANGELOG.md`, tag).
- **Commit** : sujet préfixé par l'ID — Exemple : `feat(coach): NT-032 persona coach cool`.
- **PR** : titre `[NT-XXX] …`, corps listant les IDs + critères d'acceptation cochés ;
  la CI (« Test & SonarCloud ») s'exécute sur la PR.
- **Definition of Done** : voir [`docs/backlog/README.md`](docs/backlog/README.md).

## Décisions intentionnelles (ne pas « corriger »)

- **Package id `tir_sportif`** conservé (le branding NexTarget est au niveau UI).
- **Stockage Map + `toMap`/`fromMap`** pour la plupart des modèles (seul `Goal` en
  adapter généré) — choix assumé, ne pas tout migrer sans raison.
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
