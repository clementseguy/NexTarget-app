# Changelog

Toutes les modifications notables de ce projet seront listées ici.

## [Non publié]

### Added
- NT-014 : comparatif global glissant 30 j / 90 j des points et groupements moyens par série, avec deltas absolus/relatifs et sparklines par session à partir de cinq sessions exploitables.
    - Fenêtres emboîtées à bornes calendaires déterministes et horloge injectable ; sessions prévues/libres exclues, scores nuls conservés et groupements non strictement positifs ou non finis ignorés uniquement pour cette métrique.
    - Présentation compacte à deux lignes, états explicites pour population insuffisante et division par zéro, lisible dans les thèmes sombre et France sans dépendre uniquement de la couleur.
    - Ajustements de recette : titre « Dynamique des performances · 30 j vs 90 j », précision accrue lorsque l'arrondi masque un écart, sparklines sans ligne de référence ambiguë avec valeurs ancienne/récente, deltas placés à droite des moyennes, carte Progression compacte alignée sur les pourcentages score/groupement du comparatif, et aide contextuelle dédiée.
    - Suppression de la limite silencieuse des 1 000 dernières séries dans les agrégats globaux concernés ; l'ancien calcul legacy 30/60 par total de session est clarifié comme distinct et reste non affiché.
- NT-133 : sessions libres réalisées sans séries, score, groupement ni analyse Coach.
    - Modèle polymorphe `ShootingSession` avec sous-types détaillé et libre, discriminant JSON stable et migration Hive additive rétrocompatible.
    - Action flottante dédiée dans l'onglet Réalisées, formulaire court, cartes et détail identifiés « Libre », photo, synthèse et exercices facultatifs.
    - Statistiques d'assiduité, objectifs, filtres, volumes et compteurs de tirs par arme adaptés sans contaminer les métriques fondées sur les séries.
    - Import de sauvegardes mixtes prévalidé et écrit atomiquement ; un type inconnu ne modifie aucune session locale.
- NT-048 : adoption app des refresh tokens (rotation) — le serveur était déjà livré.
    - `AuthService` stocke access token, refresh token et expirations dans `flutter_secure_storage` sous une clé unique (remplacement atomique de la paire à chaque rotation) ; migration transparente depuis l'ancien stockage (accès + email seuls) vers une reconnexion Google unique.
    - Renouvellement proactif de l'access token juste avant expiration, et unique renouvellement + rejeu de la requête après un `401` (`AuthenticatedHttpClient`), sans boucle ; mécanisme single-flight partagé entre appels concurrents pour ne jamais consommer deux fois le même refresh token.
    - Requêtes rejouées depuis une copie neuve (jamais l'objet `BaseRequest` déjà finalisé), y compris pour un corps initialement streamé.
    - Profil et Coach IA passent par le même mécanisme authentifié ; un refresh invalide/expiré/révoqué/rejoué termine la session (reconnexion Google requise) alors qu'une panne réseau préserve les tokens et ne déconnecte jamais (carnet, statistiques, objectifs et exercices restent utilisables hors ligne ; le Coach signale clairement son indisponibilité réseau).
    - Déconnexion : révocation serveur (`/auth/token/revoke`) en best effort puis nettoyage local systématique, y compris hors ligne.
- NT-073 : calibre par défaut facultatif, sélectionné parmi le référentiel configuré et appliqué uniquement aux nouvelles sessions réalisées ou prévues.
- NT-073 : autocomplétion commune aux formulaires et au wizard, sans autoremplacement, ainsi qu'une répartition statistique par calibre reconnu regroupant les alias 9 mm.

### Changed
- NT-133 : cartes de sessions compactées avec badges thématiques, indicateur dédié aux sessions libres, présence d'une analyse Coach et métriques visuelles ; formulaire libre aligné sur le formulaire détaillé et moyenne de séries corrigée pour exclure les sessions libres.
- NT-133 : bloc date/type centré verticalement dans les cartes et libellés de catégories affichés avec une majuscule initiale dans toute l'application, sans modifier leur valeur persistée.
- NT-133 : les nouvelles distances saisies dans une session détaillée doivent être des entiers strictement positifs ; les anciennes distances décimales restent lisibles et ne sont jamais réécrites automatiquement.
- NT-073 : suppression de l'entrée générique `Autre` ; les calibres inconnus restent saisis et persistés librement, participent aux statistiques globales et sont exclus des seules répartitions par calibre.

### Documentation
- Cadrage détaillé du lot NT-014/NT-048/NT-073/NT-133 et alignement des vues app/serveur et du plan de sprints.
- NT-061 : clôture documentaire après confirmation de la rotation de la clé Mistral et audit du client ; aucun appel Mistral direct, prompt, secret ou fallback local ne subsiste dans l'app. Les notes des anciennes versions restent conservées comme historique.
- Cahier de recette : ajout de AUTH-01 à AUTH-04 (persistance longue durée, déconnexion, résilience réseau, migration installation historique) et précision de COACH-03 (message distinct session expirée / réseau indisponible).

## [0.6.0] - 2026-09-02

### Added
- NT-008/NT-009/NT-017 : râtelier d'armes personnel.
    - `Weapon`/`WeaponService`/`HiveWeaponRepository` (box Hive `weapons`, `migration_5_create_weapons_box`) : CRUD simple (ajout, renommage, suppression) dans `Paramètres > Préférences Tir` (`WeaponRackSection`), noms obligatoires et uniques après normalisation (espaces/casse ignorés).
    - Renommage confirmé, propagé aux sessions prévues et réalisées dont le nom d'arme correspond exactement après normalisation, avec rollback complet en cas d'échec ; la suppression ne modifie jamais les sessions existantes.
    - `utils/weapon_autocomplete.dart` centralise la normalisation et l'autocomplétion, réutilisées par `WeaponAutocompleteField` dans le formulaire de session (`SessionForm`) et le wizard de conversion (`WizardIntroStep`) : la saisie libre reste toujours prioritaire.
    - Export JSON inclut le râtelier ; import rétrocompatible avec les anciens fichiers sans râtelier, fusionné sans effacer le râtelier local (`BackupService`).
    - `DashboardService.generateWeaponShotCounts` + `WeaponShotCountsCard` : compteur de tirs par arme du râtelier en toute dernière section de `Statistiques > Avancé`, calculé depuis les seules sessions réalisées (essais compris), sans graphe.
- NT-071 : migration de la production de SQLite éphémère vers PostgreSQL Neon avec Alembic, livrée dans la release produit v0.6.0 via NexTarget-server v0.3.0 ; connexions et rôles runtime/migration séparés, migrations avant démarrage et procédures de sauvegarde/restauration/rollback documentées, sans changement du contrat d'API mobile.

### Quality
- NT-058 : fakes de repository partagés pour les tests (`test/support/`).
    - `FakeSessionRepository` clone chaque session lue (comme `HiveSessionRepository`), évitant qu'une mutation en mémoire avant un `update()` en échec ne « persiste » silencieusement (bug détecté lors du développement de NT-008 — rollback du renommage d'arme).
    - `captureError()` (`test/support/async_test_helpers.dart`) pour tester une exception async sans le piège `expect(() => asyncFn(), throwsA(...))` non awaité.
    - `test/goal_service_lot_a_test.dart` migré vers le fake partagé à titre d'exemple ; convention documentée dans `AGENTS.md`.

### Documentation
- Ajout de NT-049, interface d'administration serveur read-only des utilisateurs destinée au diagnostic OAuth, et planification dans un lot serveur autonome prioritaire.
- Passage de NT-049 à `FAIT` après livraison de la page read-only `GET /app/admin/users`, actualisation de la vue serveur et clarification de la gouvernance : le backlog et sa vue serveur canonique sont maintenus uniquement dans `NexTarget-app`.

## [0.5.0] - 2026-07-09

### Sprint S2 (Demo-ready)
### Changed (retours recette 2026-07-09)
- NT-075: texte de l'écran 3 de l'onboarding simplifié (« L'utilisation du coach nécessite la création d'un compte. »).
- NT-075: l'aide « Tendance des objectifs » suit désormais le thème actif (fonds sombres en dur retirés — thème France respecté).
- NT-032: le ton du coach se choisit uniquement dans Paramètres > Coach IA — chips Neutre/Cool retirés de l'écran Session.
- Nouvel item backlog NT-034 : affinage du contenu des prompts personas (évolution future, serveur).
### Fixed (retours recette 2026-07-09)
- Mes sessions : le bouton + crée une session du même type que l'onglet actif (Réalisées → réalisée, Prévues → prévue) ; l'appui long (non fonctionnel) est supprimé, aide contextuelle alignée.
### Added
- NT-075: Onboarding + aide contextuelle.
    - `OnboardingScreen`/`OnboardingGate` : 3 écrans (carnet de tir, stats & objectifs, coach IA) au premier lancement, flag Hive `onboarding_seen`, boutons Passer/Suivant/Commencer.
    - Ré-accès via Paramètres > Aide > « Revoir l'introduction ».
    - `HelpButton` (« ? » → bottom sheet) sur : Mes sessions, hub Exercices & Objectifs, liste Objectifs, liste Exercices.
- NT-032: Multi-personas coach (partie app).
    - Préférence `coach_persona` (Hive) exposée par `SettingsProvider` (défaut `coach_neutre`, valeurs validées).
    - Sélecteur « Ton du coach » dans Paramètres > Coach IA (unique point de réglage après retour de recette, cf. Changed).
    - `prompt_variant` transmis au serveur (`ServerCoachAnalysisService`).

### Sprint S1 (Sécurité & Qualité)
### Quality
- NT-051: Analyse statique durcie.
    - `flutter_lints` activé (dev_dependency + include dans `analysis_options.yaml`) ; 138 issues corrigées, `flutter analyze` à zéro issue.
    - Correction d'un vrai bug détecté par le lint : la route nommée `/settings` ne résolvait jamais (comparaison `String == RouteSettings`, paramètre masquant la constante) — `app_router.dart`.
    - 8 usages de `BuildContext` après `await` sécurisés (`context.mounted`).
    - Prints remplacés par `AppLogger` (auth, Hive, deep links) ; plus aucun `print` hors utilitaire CLI justifié.
    - `uuid` promu en dépendance directe (importé par `models/goal.dart`, était transitif).
    - CI : step `flutter analyze --fatal-infos` ajouté au workflow SonarCloud.
### Security
- NT-061: Coach « connecté uniquement » — suppression du chemin Mistral direct côté client.
    - `CoachAnalysisService` (appel Mistral direct) supprimé ; `ServerCoachAnalysisService` devient l'unique chemin d'analyse.
    - Plus aucune clé/config Mistral côté client : `AppConfig` (sélection de clé), `assets/config.yaml`, `config.example.yaml` et `scripts/build_apk.sh` purgés ; assets `coach_prompt*.yaml` retirés (le prompt vit côté serveur, NT-031).
    - Section « Analyse Coach » : sans compte, message clair + bouton « Se connecter » (route `/login`) ; le carnet de tir reste 100 % hors-ligne.
    - Prints `[DEBUG]` hérités retirés des fichiers coach.
    - ⚠️ Rotation de la clé Mistral historique : action manuelle (console Mistral + env Render), hors code.

## [0.4.0] - Unreleased
### Technical
- T1: Intégration SonarCloud (acceptation: badge visible, Quality Gate ≥ B, couverture ≥ 20%).
    - CI GitHub Actions: analyse automatique à chaque push sur `dev` et sur chaque PR vers `main`.
    - Import de la couverture via LCOV (`flutter test --coverage` → `coverage/lcov.info`).
    - Badges SonarCloud ajoutés au README (Quality Gate, Coverage, Maintainability, Reliability, Security).
    - Anti‑doublons: garde qui évite les exécutions redondantes (push vs PR) et `concurrency` par ref.
    - Analyse de `main` sans push direct: triggers `workflow_dispatch` (manuel) et `schedule` quotidien.

### Docs
- T2: Cahier de recette (tests manuels)
    - Générateur: `scripts/generate_cahier_recette.dart`
    - Source: `docs/specs/cahier_recette.yaml`
    - Sortie: `docs/cahier_recette.md`
    - Politique: jouer le cahier de recette avant toute MR vers `main`; mettre à jour le YAML + régénérer si comportement modifié.

### Technical (en cours)
- T5: Déport des appels Mistral vers NexTarget-server
    - Nouveau `ServerCoachAnalysisService` : utilisé quand l'utilisateur est connecté (aucune clé Mistral côté client).
    - Utilisateur non connecté : ancien appel Mistral direct conservé (mode déconnecté du carnet de tir préservé).
    - Serveur : nouvel endpoint `POST /coach/analyze-session` (JWT requis, rate limiting, cf. NexTarget-server).
    - À faire ensuite : validation en usage réel puis retrait de la clé Mistral côté client + rotation.

## [0.3.0] - 2025-09-29
### Added
- Sessions :
    - Sessions prévues: statut 'prévue', filtre dédié, en-tête stats spécifiques.
    - Wizard conversion session prévue → réalisée (intro + séries + synthèse).
    - Consignes → génération séries placeholder; prise (1M/2M) éditable par série.
    - Champs supplémentaires séries dans le wizard: Coups, Distance, Points, Groupement, Commentaire (validations obligatoires).
- Objectifs :
    - Carte récap Top3 + compteurs (F3, F4, F14) remplaçant l'ancienne carte prioritaire.
    - Section statistiques macro (6 indicateurs: réalisés total, actifs, réalisés 7/30/60/90j) (F5, F6).
    - Carte multi‑objectif affichant tous les objectifs actifs triés par progression (F5).
    - Formulaire création/édition séparé avec icône sauvegarde + champ Période déplacé en bas (F7, F8, F9).
    - Aide tendance (modal + doc) avec classification En hausse / Stable / En baisse (F10, F11).
    - Documentation détaillée du calcul de tendance (objectifs_tendance.md) incluant seuil neutralité.
- Exercices :
    - Exercices: création, description, durée, matériel, consignes (0..n).
    - Association sessions ↔ exercices; planification de session depuis un exercice.
	- EX1/EX2/EX14: Enums Catégorie & Type + migration rétrocompat.
	- EX3: Règle planification limitée aux exercices Stand.
	- EX4/EX5: Cartes statistiques total exercices (écran combiné & écran dédié).
	- EX6: Icône d'exercice planifié (sessions prévues liées).
	- EX7/EX8: Filtres multi-catégories & par type (chips togglables + panneau repliable).
	- EX9: Modes de tri (nom asc/desc, catégorie, type, récent).
	- EX10: Nettoyage UI (suppression bouton + topbar redondant).
	- EX11–EX13: Actions planifier depuis card, retrait planifier du formulaire, sauvegarde dans AppBar.
	- EX15–EX17: Carte récap Exercices cohérente, stats par type (chips), suppression TODO list combiné.
- Tableau de bord (ex accueil) :
    - Stats: moyennes glissantes (30/60j) + delta de progression (affichage amélioré).
    - Stats: helpers et tests pour pipeline séries (verrouillage ordre ASC et sélection des N dernières).
    - Scatter: modes alternatifs (last10, window30Cap, adaptive) + utilitaires publics (`scatter_mode.dart`, `scatter_utils.dart`).
    - Tests: `scatter_modes_test.dart` (modes + downsampling), renforts sur filtres/ordre (Lot C).
    - Avancé: graphes "1 main" et "2 mains" combinés (points + groupement) en mode brut, sur les 30 dernières séries. [F29][F30]
    - Calibres: liste configurable (config.yaml avec override local), autocomplétion avec autoremplacement (match unique), préférence "calibre par défaut" (préremplissage formulaires).

### Changed
- Différenciation visuelle sessions prévues (couleurs cartes, chips, header).
- FAB: appui long / clic droit (web) pour créer directement une session prévue.
- Refonte UI état vide historique (suppression bouton central redondant).
- Synthèse: préremplie depuis l'exercice + insertion newline pour édition.
- Objectifs: Suppression de la legacy `GoalsSummaryCard` et lien redondant "Tous les objectifs" au profit des nouveaux blocs.
- Objectifs: Carte stats tendance plus compacte + refresh global.
- Accueil → Tableau de bord (libellés UI et tests) [Lot D].
- Titres des tableaux/graphes centrés [Lot D].
- Graphes “Évolution points” et “Évolution groupement” affichent désormais les 30 dernières séries (ancien → récent).
- Graphe “Corrélation Points/Groupement” affiche les 30 dernières séries.
- Documentation `docs/statistiques.md` alignée (sélection des 30 dernières séries; clarifications).

### Fixed
- Perte séries placeholder lors planification (valeurs minimales persistées).
- Overflow éditeur consignes + overflow wizard séries (scroll + layout fix).
- Defaults Coups / Distance séries suivantes hérités correctement (plus de 1).
- Préremplissage indésirable champs (Points, Groupement, Commentaire) supprimé.
- Bug d’ordre: les graphes pouvaient afficher les séries récentes à gauche. Pipeline corrigé pour garantir “récentes à droite” et SMA3 alignée sur les points visibles.
- Flakiness tests temporels: `StatsService` accepte un `now` injecté pour figer le temps dans les tests.
- Calibre (saisie): liste complète affichée au focus (création/édition), suppression de caractères sans autoremplacement bloquant, préremplissage vide si préférence vide.

### Removed
- Section “Mes dernières sessions” obsolète retirée [Lot C].

### Technical
- Service conversion `convertPlannedToRealized` + persistance incrémentale séries.
- Tests: ajout planned_session_conversion_test & validations post-wizard.
- Script build APK: renommage versionné (réutilisé pour debug 0.3.0).
- Sélecteur prise: réutilisation préférence utilisateur (Hive app_preferences).
- Objectifs: Wrapper `macroAchievementStats()` (agrégation unique) + helper tendance (delta normalisé).
- Objectifs: Réorganisation GoalsListScreen (extraction GoalEditScreen, refresh via GlobalKeys).
- Objectifs: Doc interne `objectifs_tendance.md` (fenêtres, delta, epsilon=0.001).
 - Exercices: Tests de migration, tri, filtres, planification, carte stats; widget test écran combiné.
 - Filtre centralisé statut sessions (exclusion `prévue`) appliqué dans `StatsService` et `RollingStatsService` [Lot C].
- Tri strict ASC des séries (date session puis ordre intra-session) [Lot C].
- Refactor pipeline Scatter et introduction du downsampling stride.
- Mise à jour et durcissement des tests (ordre, filtres, progression/consistency edge cases).

---

## [0.2.0] - 2025-09-28
### Added
- Bottom sheet "Rappels Essentiels" (Accueil) avec onglets Sécurité / Tir.
- Lien informatif vers des règles générales de sécurité (source externe).
- Export des sessions dans un dossier utilisateur (File Picker).
- Suppression des objectifs atteints (icône poubelle activée quand status = atteint).
- Animation splash overlay personnalisée (remplace l'ancien splash natif visuellement).
- Script de build unique `build_apk.sh` avec support debug + renommage versionné.

### Changed
- Branding global: application renommée NexTarget (icônes / libellés).
- Renommage APK: format `NexTarget-v<version>-<mode>-<timestamp>.apk`.
- Splash natif neutralisé (android/iOS) pour éviter double affichage.
- Amélioration messages d'erreur réseau (distinction SocketException / Timeout).

### Fixed
- Overflow layout sur la liste des objectifs.
- Échecs réseau sur Android release (ajout permission INTERNET).

### Technical
- Injection clé Mistral via `--dart-define` + fallback config/local/env.
- Stats améliorées (moyennes 30j, progression, distribution catégories, distances...).

## [0.1.0] - 2025-09-XX
- Version initiale (sessions, séries, objectifs de base, stats simples, export JSON initial).

---
Format inspiré de Keep a Changelog.
