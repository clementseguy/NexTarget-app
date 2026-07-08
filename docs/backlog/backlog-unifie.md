# NexTarget — Backlog unifié (source de vérité)

> **Ce fichier est l'unique source de vérité produit.** Les fichiers
> [`vue-app.md`](vue-app.md) et [`vue-serveur.md`](vue-serveur.md) en sont des
> **projections** : rien ne doit exister uniquement dans une vue. Règles de
> gouvernance dans [`README.md`](README.md), historique des arbitrages dans
> [`incoherences.md`](incoherences.md).

- **Statuts** : les statuts reflètent l'**état réel du code** au 2026-07-07, pas
  les intentions des anciens backlogs.
- **IDs** : `NT-XXX`, stables, jamais réutilisés. Les trous de numérotation sont
  volontaires (réservés à l'insertion future dans un thème).
- **Portée** : `app` | `server` | `both`.
- **Priorité (MoSCoW)** : Must / Should / Could / Won't-now.
- **Estimation** : S / M / L.

## Légende des statuts

| Statut | Sens |
|---|---|
| **FAIT** | Implémenté et présent dans le code |
| **EN COURS** | Partiellement implémenté, reste des sous-tâches identifiées |
| **À FAIRE** | Pas dans le code |
| **À VÉRIFIER** | Ambigu : présent partiellement / périmètre à confirmer |

## Vue d'ensemble

| Thème | Items |
|---|---|
| 1. Carnet de tir | NT-001 → NT-006 |
| 2. Statistiques & Objectifs | NT-010 → NT-015 |
| 3. Exercices | NT-020 → NT-025 |
| 4. Coach IA | NT-030 → NT-033 |
| 5. Auth & Compte | NT-040 → NT-048 |
| 6. Qualité & Observabilité | NT-050 → NT-055 |
| 7. Sécurité & Secrets | NT-060 → NT-066 |
| 8. Plateforme & Déploiement | NT-070 → NT-076 |
| 9. Idées / hors-scope | NT-090 → NT-092 |

---

## Thème 1 — Carnet de tir (Sessions & Séries)

*Cœur produit : enregistrer et consulter l'activité de tir. Fonctionne 100 % hors-ligne.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-001 | Enregistrer une session de tir | app | Must | M | FAIT |
| NT-002 | Saisir des séries détaillées | app | Must | M | FAIT |
| NT-003 | Historique & détail des sessions | app | Must | M | FAIT |
| NT-004 | Synthèse libre du tireur par session | app | Should | S | FAIT |
| NT-005 | Attacher une photo de la cible | app | Could | M | À FAIRE |
| NT-006 | Analyse d'image de la cible (dispersion/score) | both | Won't-now | L | À FAIRE |

### NT-001 — Enregistrer une session de tir
- **Thème** : Carnet de tir
- **Description** : Le tireur consigne une séance (arme, calibre, date, catégorie entraînement/match/test) pour construire son carnet.
- **Portée** : app · **Dépendances** : —
- **Critères d'acceptation** : créer une session avec arme, calibre, date, catégorie et statut (prévue/réalisée) ; la session est persistée en local (Hive) et relue après redémarrage.
- **Statut** : FAIT — `ShootingSession`, `session_service`, `create_session_screen`.

### NT-002 — Saisir des séries détaillées
- **Thème** : Carnet de tir
- **Description** : Chaque session contient des séries mesurées, base de toutes les stats et de l'analyse coach.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : par série — nombre de coups, distance, points, groupement (cm), prise (1/2 mains), commentaire ; ajout/suppression/édition de séries.
- **Statut** : FAIT — `Series` (enum `HandMethod`), `session_form`.

### NT-003 — Historique & détail des sessions
- **Thème** : Carnet de tir
- **Description** : Retrouver et rouvrir toute session passée.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : liste chronologique ; écran détail affichant séries, catégorie, synthèse et analyse coach éventuelle.
- **Statut** : FAIT — `sessions_history_screen`, `session_detail_screen`.

### NT-004 — Synthèse libre du tireur
- **Thème** : Carnet de tir
- **Description** : Champ texte libre où le tireur commente sa séance ; enrichit l'analyse du coach.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : `synthese` éditable et persistée ; transmise au coach lors de l'analyse.
- **Statut** : FAIT — `ShootingSession.synthese`.

### NT-005 — Attacher une photo de la cible
- **Thème** : Carnet de tir
- **Description** : Ajouter une photo de la cible en fin de session pour mémoire visuelle et future analyse.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : sélection/prise de photo, stockage local associé à la session, affichage dans le détail.
- **Statut** : À FAIRE. · **Notes** : préalable à NT-006.

### NT-006 — Analyse d'image de la cible
- **Thème** : Carnet de tir
- **Description** : Analyser la photo (dispersion, score total) pour confronter aux commentaires et enrichir l'analyse coach.
- **Portée** : both · **Dépendances** : NT-005, NT-030
- **Critères d'acceptation** : à définir — extraction dispersion/score ; résultat versé dans le contexte envoyé au coach.
- **Priorité** : Won't-now · **Statut** : À FAIRE. · **Notes** : vision par ordinateur, coûteux ; probablement côté serveur.

---

## Thème 2 — Statistiques & Objectifs

*Transformer les données en progression mesurable.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-010 | Tableau de bord statistiques | app | Must | M | FAIT |
| NT-011 | Statistiques explicatives / évolution | app | Should | M | FAIT |
| NT-012 | Objectifs mesurables | app | Must | M | FAIT |
| NT-013 | Hauts faits (records) | app | Should | S | FAIT |
| NT-014 | Comparatif glissant 30j vs 60j + sparkline | app | Could | M | À FAIRE |
| NT-015 | Recommandations croisées Objectifs ⇄ Exercices | app | Could | M | À FAIRE |

### NT-010 — Tableau de bord statistiques
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-002
- **Description** : Vue synthétique des indicateurs clés (moyennes, volumes, tendances) sur l'accueil.
- **Critères d'acceptation** : cartes de stats calculées à partir des sessions ; mise à jour à chaque nouvelle session.
- **Statut** : FAIT — `dashboard_service`, `stats_service`, `widgets/dashboard`.

### NT-011 — Statistiques explicatives / évolution
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Courbes/analyses expliquant l'évolution (cf. `docs/features/stats_explicatives.md`).
- **Critères d'acceptation** : évolution temporelle d'au moins une métrique clé ; lisible sur mobile.
- **Statut** : FAIT — `docs/features/statistiques.md`, `evolution_chart.md`.

### NT-012 — Objectifs mesurables
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Le tireur se fixe des objectifs chiffrés et suit leur atteinte.
- **Critères d'acceptation** : créer un objectif (métrique, comparateur ≥/≤, valeur cible, statut) ; progression calculée automatiquement.
- **Statut** : FAIT — `Goal` (`GoalMetric`, `GoalComparator`, `GoalStatus`), `goal_service`, écrans list/edit.

### NT-013 — Hauts faits (records)
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012
- **Description** : Mettre en avant les records personnels (meilleure série, meilleur score de session, meilleur groupement).
- **Critères d'acceptation** : métriques `bestSeriesPoints`, `bestSessionPoints`, `bestGroupSize` calculées et affichées.
- **Statut** : FAIT — enum `GoalMetric` (champs 5-7).

### NT-014 — Comparatif glissant 30j vs 60j + sparkline
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Delta % 30j vs 60j avec petite sparkline intégrée aux cartes existantes (ancien P7).
- **Critères d'acceptation** : delta calculé et affiché ; sparkline sur au moins une carte.
- **Priorité** : Could · **Statut** : À FAIRE.

### NT-015 — Recommandations croisées Objectifs ⇄ Exercices
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012, NT-021
- **Description** : Suggérer des exercices selon les objectifs en retard, et inversement.
- **Critères d'acceptation** : à définir — au moins une reco pertinente affichée selon l'état des objectifs.
- **Priorité** : Could · **Statut** : À FAIRE.

---

## Thème 3 — Exercices

*Catalogue d'exercices reliés aux objectifs et aux sessions.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-020 | Gérer des exercices (CRUD) | app | Must | M | FAIT |
| NT-021 | Lier exercices ↔ objectifs | app | Should | S | FAIT |
| NT-022 | Lier exercices ↔ sessions | app | Should | S | FAIT |
| NT-023 | Création d'exercice par le coach | both | Could | L | À FAIRE |
| NT-024 | Stats d'exécution (fenêtres glissantes) | app | Could | M | À FAIRE |
| NT-025 | Niveau de difficulté d'exercice | app | Could | S | À FAIRE |

### NT-020 — Gérer des exercices (CRUD)
- **Thème** : Exercices · **Portée** : app · **Dépendances** : —
- **Description** : Créer/éditer des exercices typés avec consignes détaillées.
- **Critères d'acceptation** : catégorie (`precision/group/speed/technique/mental/physical`), type (`stand/home`), description, durée, matériel, consignes ordonnées, priorité.
- **Statut** : FAIT — `Exercise`, `exercise_service`, écrans list/form.

### NT-021 — Lier exercices ↔ objectifs
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-012, NT-020
- **Description** : Rattacher un exercice aux objectifs qu'il sert.
- **Critères d'acceptation** : `goalIds` éditable ; navigation objectif → exercices liés.
- **Statut** : FAIT — `Exercise.goalIds`.

### NT-022 — Lier exercices ↔ sessions
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-001, NT-020
- **Description** : Associer des exercices pratiqués à une session.
- **Critères d'acceptation** : `ShootingSession.exercises` (IDs) éditable et affiché.
- **Statut** : FAIT — `ShootingSession.exercises`.

### NT-023 — Création d'exercice par le coach
- **Thème** : Exercices · **Portée** : both · **Dépendances** : NT-020, NT-030
- **Description** : À partir d'une analyse de session, le coach propose un exercice prêt à enregistrer.
- **Critères d'acceptation** : à définir — l'analyse coach peut retourner un exercice structuré ; l'app permet de l'ajouter au catalogue.
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : dépend du format de sortie structuré du coach.

### NT-024 — Stats d'exécution (fenêtres glissantes)
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-022
- **Description** : Compter l'usage des exercices (`usageCount`, `lastPerformedAt`) puis stats par fenêtres glissantes (ancien P4).
- **Critères d'acceptation** : incrément d'usage à chaque session liée ; date de dernière exécution ; stats sur fenêtre glissante.
- **Priorité** : Could · **Statut** : À FAIRE.

### NT-025 — Niveau de difficulté d'exercice
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-020
- **Description** : Classer les exercices par difficulté (beginner/advanced/expert).
- **Critères d'acceptation** : champ difficulté sur `Exercise` ; filtrable.
- **Priorité** : Could · **Statut** : À FAIRE.

---

## Thème 4 — Coach IA

*Analyse IA des séances via le serveur NexTarget. **Décision : coach connecté uniquement** (cf. NT-061, [incoherences.md](incoherences.md) I2).*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT |
| NT-031 | Prompt d'analyse centralisé côté serveur | server | Must | S | FAIT |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | FAIT |
| NT-033 | Écran "Coach" : analyse transverse multi-sessions | both | Should | L | À FAIRE |

### NT-030 — Analyse d'une session par le coach IA
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-002, NT-040, NT-060
- **Description** : Le tireur obtient une analyse rédigée de sa séance ; l'appel Mistral passe par le serveur (proxy), sans clé côté client.
- **Critères d'acceptation** : app envoie les données de session au serveur ; `POST /coach/analyze-session` (JWT requis) renvoie une analyse texte ; rendu markdown dans l'app.
- **Statut** : FAIT — serveur `api/coach.py` ; app `ServerCoachAnalysisService` (unique chemin d'analyse depuis NT-061).

### NT-031 — Prompt d'analyse centralisé côté serveur
- **Thème** : Coach IA · **Portée** : server · **Dépendances** : NT-030
- **Description** : Le template de prompt et l'assemblage vivent côté serveur (le client n'envoie plus le prompt).
- **Critères d'acceptation** : `build_prompt` assemble session + template ; template versionné (`prompts/coach_neutre.yaml`).
- **Statut** : FAIT — `services/prompt_builder.py`.

### NT-032 — Multi-personas coach (neutre / cool)
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-031
- **Description** : Proposer plusieurs tons de coach (neutre, cool…).
- **Critères d'acceptation** : ≥2 variantes de prompt côté serveur ; sélection du ton depuis l'app via `prompt_variant`.
- **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S2) — serveur : `coach_cool.yaml` + `_VARIANT_FILES` ; app : préférence `coach_persona` (Paramètres > Coach IA + chips dans la section Analyse Coach), envoyée en `prompt_variant`.

### NT-033 — Écran "Coach" : analyse transverse multi-sessions
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-030
- **Description** : Un écran dédié qui analyse l'ensemble de l'activité (plusieurs sessions, changements d'armes/calibres, régularité, comportements répétés) et propose des actions.
- **Critères d'acceptation** : à définir — agrégation multi-sessions ; analyse coach globale ; suggestions d'actions.
- **Priorité** : Should · **Statut** : À FAIRE.
- **Notes** : `coach_screen.dart` existe mais est un placeholder « Coming soon ».

---

## Thème 5 — Auth & Compte

*Compte optionnel : le carnet marche sans login ; le compte débloque le coach IA (proxy).*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-040 | Authentification OAuth Google | both | Must | M | FAIT |
| NT-041 | Authentification optionnelle | app | Must | S | FAIT |
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT |
| NT-043 | Endpoint `/users/me` | server | Must | S | FAIT |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À VÉRIFIER |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE |
| NT-048 | Refresh tokens + rotation | server | Should | M | À FAIRE |

### NT-040 — Authentification OAuth Google
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : —
- **Description** : Se connecter avec Google (flow mobile), pour accéder aux fonctions connectées.
- **Critères d'acceptation** : `/auth/google/login` + callback (vérif `id_token` via `google-auth`) ; redirect mobile `nextarget://callback?token=` ; échange callback→access ; app `signInWithGoogle`.
- **Statut** : FAIT — serveur `api/auth_google.py`, app `auth_service.dart`.

### NT-041 — Authentification optionnelle
- **Thème** : Auth & Compte · **Portée** : app · **Dépendances** : —
- **Description** : L'app est pleinement utilisable sans compte ; le login est facultatif.
- **Critères d'acceptation** : carnet, stats, exercices, objectifs fonctionnent hors connexion ; le login n'est requis que pour le coach IA connecté.
- **Statut** : FAIT — `auth_provider`, mode déconnecté préservé.

### NT-042 — Profil utilisateur (nom/avatar/niveau)
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Afficher nom/pseudo, avatar, niveau d'expérience (beginner/advanced/expert), date d'inscription.
- **Critères d'acceptation** : serveur stocke `display_name`, `display_name_custom`, `avatar_url`, `experience_level` ; app les affiche.
- **Statut** : FAIT — `models/user.py`, `profile_screen.dart`.
- **Notes** : l'**édition** dans l'app (choix du niveau, pseudo custom) reste **À VÉRIFIER** ; à confirmer/compléter si absente.

### NT-043 — Endpoint `/users/me`
- **Thème** : Auth & Compte · **Portée** : server · **Dépendances** : NT-040
- **Description** : Renvoyer le profil de l'utilisateur authentifié.
- **Critères d'acceptation** : `GET /users/me` protégé (JWT `access`) renvoie le profil.
- **Statut** : FAIT — `api/users.py`.

### NT-044 — Authentification OAuth Facebook
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Se connecter avec Facebook.
- **Critères d'acceptation** : serveur `/auth/facebook/*` fonctionnel ; **app : bouton Facebook câblé** (manquant aujourd'hui).
- **Priorité** : Could · **Statut** : À VÉRIFIER.
- **Notes** : **serveur = FAIT** (`api/auth_facebook.py`), **app = À FAIRE**, priorité basse (arbitrage 2026-07-07 : « plus tard, optionnelle »). Reste au backlog.

### NT-045 — Stats publiques / partage de profil
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Exposer (en option) des stats publiques du tireur.
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-046 — Gamification
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Système de gamification (badges, niveaux…).
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-047 — Apple Sign In
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Provider Apple (requis pour publication iOS si autres logins sociaux présents).
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE. · **Notes** : roadmap serveur v0.2.

### NT-048 — Refresh tokens + rotation
- **Thème** : Auth & Compte · **Portée** : server · **Dépendances** : NT-040
- **Description** : Sessions plus longues sans re-login (refresh + rotation).
- **Critères d'acceptation** : émission/rotation de refresh tokens ; révocation. · **Priorité** : Should · **Statut** : À FAIRE. · **Notes** : roadmap serveur v0.2.

---

## Thème 6 — Qualité & Observabilité

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-050 | SonarCloud + Quality Gate + couverture (app) | app | Must | M | FAIT |
| NT-051 | Analyse statique & lint (durcir) | app | Should | S | FAIT |
| NT-052 | Cahier de recette généré | app | Should | S | FAIT |
| NT-053 | Logging structuré + tracing (serveur) | server | Should | M | À FAIRE |
| NT-054 | Tests OAuth mockés (providers externes) | server | Should | M | À FAIRE |
| NT-055 | CI serveur (tests + couverture) | server | Should | S | À FAIRE |

### NT-050 — SonarCloud + Quality Gate + couverture (app)
- **Portée** : app · **Dépendances** : — · **Description** : Qualité continue mesurée sur l'app.
- **Critères d'acceptation** : analyse SonarCloud sur push `dev` et PR `main` ; import couverture LCOV ; badges README ; Quality Gate ≥ B.
- **Statut** : FAIT — `.github`, `sonar-project.properties`, CHANGELOG T1.

### NT-051 — Analyse statique & lint (durcir)
- **Portée** : app · **Dépendances** : NT-050 · **Description** : Renforcer l'analyse statique pour tenir le niveau de qualité visé.
- **Critères d'acceptation** : un ruleset de lint actif (ex. `flutter_lints` ou `very_good_analysis`) ; `flutter analyze` sans warning ; job d'analyse en CI.
- **Statut** : FAIT (2026-07-07, sprint S1) — `flutter_lints` activé (`analysis_options.yaml`), 138 issues corrigées (dont un vrai bug : route `/settings` jamais résolue, `unrelated_type_equality_checks`), step CI `flutter analyze --fatal-infos` ajouté au workflow SonarCloud.
- **Notes** : `dart_code_metrics` non retenu (payant/archivé) ; `flutter_lints` + Sonar suffisent.

### NT-052 — Cahier de recette généré
- **Portée** : app · **Dépendances** : — · **Description** : Tests manuels reproductibles avant chaque MR vers `main`.
- **Critères d'acceptation** : source YAML → génération markdown (`scripts/generate_cahier_recette.dart`) ; joué avant MR.
- **Statut** : FAIT — `docs/tests/cahier_recette.*`.

### NT-053 — Logging structuré + tracing (serveur)
- **Portée** : server · **Dépendances** : — · **Description** : Observabilité serveur (JSON + OpenTelemetry).
- **Critères d'acceptation** : logs structurés ; corrélation des requêtes. · **Priorité** : Should · **Statut** : À FAIRE. · **Notes** : roadmap v0.2.

### NT-054 — Tests OAuth mockés
- **Portée** : server · **Dépendances** : NT-040 · **Description** : Tester le flow OAuth complet avec providers externes mockés.
- **Critères d'acceptation** : Google/Facebook mockés ; cas nominal + erreurs. · **Priorité** : Should · **Statut** : À FAIRE.
- **Notes** : `tests/test_auth.py` et `tests/test_coach.py` existent (tests basiques) ; mocks providers manquants.

### NT-055 — CI serveur (tests + couverture)
- **Portée** : server · **Dépendances** : — · **Description** : Le serveur n'a pas de pipeline CI.
- **Critères d'acceptation** : workflow CI lançant `pytest` (+ couverture) sur push/PR.
- **Priorité** : Should · **Statut** : À FAIRE. · **Notes** : aucun `.github/` côté serveur aujourd'hui.

---

## Thème 7 — Sécurité & Secrets

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-060 | Proxy Mistral côté serveur (clé hors client) | server | Must | M | FAIT |
| NT-061 | Coach « connecté uniquement » : retrait clé Mistral client + rotation | both | Must | M | FAIT |
| NT-062 | Rate limiting de l'endpoint coach | server | Must | S | FAIT |
| NT-063 | State OAuth à usage unique (CSRF) | server | Must | S | FAIT |
| NT-064 | Vérification du type de token JWT | server | Must | S | FAIT |
| NT-065 | Restreindre CORS par environnement | server | Should | S | FAIT |
| NT-066 | Vérification du nonce Google | server | Should | S | FAIT |

### NT-060 — Proxy Mistral côté serveur
- **Portée** : server · **Dépendances** : NT-030 · **Description** : Centraliser l'appel Mistral côté serveur pour retirer la clé du client (ancien P2).
- **Critères d'acceptation** : `POST /coach/analyze-session` appelle Mistral ; clé lue depuis l'env serveur (`MISTRAL_API_KEY`) ; ni clé ni prompt complet côté client.
- **Statut** : FAIT — `api/coach.py`, `services/mistral_client.py`, `core/config.py`.

### NT-061 — Coach « connecté uniquement » : retrait clé Mistral client + rotation
- **Portée** : both · **Dépendances** : NT-030, NT-060 · **Description** : Rendre le coach accessible **uniquement connecté**, supprimer le chemin Mistral direct et la clé embarquée dans le client, puis faire tourner la clé (arbitrage 2026-07-07).
- **Critères d'acceptation** :
  - le chemin `CoachAnalysisService` direct (Mistral) et la clé côté client sont supprimés ;
  - l'analyse coach exige un utilisateur authentifié (message clair sinon) ;
  - la clé Mistral historique est révoquée/rotée ;
  - le carnet de tir reste utilisable hors-ligne (le coach seul devient online-only).
- **Priorité** : Must · **Statut** : FAIT (code, 2026-07-07, sprint S1) — `CoachAnalysisService` direct supprimé, plus aucune clé/config Mistral côté client (`AppConfig`, `config.yaml`, `build_apk.sh` purgés), analyse gated par l'auth avec message clair + CTA login.
- **Notes** : ⚠️ la **rotation de la clé Mistral historique** est une action manuelle (console Mistral + env Render) à réaliser par le mainteneur — hors code. Voir [incoherences.md](incoherences.md) I2.

### NT-062 — Rate limiting de l'endpoint coach
- **Portée** : server · **Dépendances** : NT-060 · **Description** : Empêcher l'abus qui viderait le quota Mistral.
- **Critères d'acceptation** : limite par utilisateur (10 requêtes / 5 min) ; réponse 429 au-delà.
- **Statut** : FAIT — `services/rate_limiter.py` (in-memory). · **Notes** : Redis si multi-instance (lié à NT-071).

### NT-063 — State OAuth à usage unique (CSRF)
- **Portée** : server · **Dépendances** : NT-040 · **Critères d'acceptation** : state créé puis consommé une seule fois ; TTL ; non rejouable.
- **Statut** : FAIT — `services/oauth_state.py`. · **Notes** : en mémoire (single-instance).

### NT-064 — Vérification du type de token JWT
- **Portée** : server · **Dépendances** : NT-040 · **Critères d'acceptation** : `payload["type"]` vérifié (`access` vs `callback`) ; un callback token ne donne jamais accès à l'API.
- **Statut** : FAIT — `core/security.py`, `api/deps.py`.

### NT-065 — Restreindre CORS par environnement
- **Portée** : server · **Dépendances** : — · **Description** : `allow_origins=["*"]` est un TODO connu.
- **Critères d'acceptation** : origines restreintes en prod via configuration. · **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S1) — `CORS_ALLOW_ORIGINS` (défaut : `*` en dev, aucune origine sinon), tests `tests/test_cors.py`.

### NT-066 — Vérification du nonce Google
- **Portée** : server · **Dépendances** : NT-040 · **Description** : Nonce généré mais non vérifié dans le callback (identifié dans `SECURITY_ANALYSIS.md`).
- **Critères d'acceptation** : nonce vérifié à la réception du callback. · **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S1) — claim `nonce` comparé au state stocké (400 sinon), tests mockés `tests/test_auth_google_nonce.py`.

---

## Thème 8 — Plateforme & Déploiement

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-070 | Déploiement serveur (Render) | server | Must | S | FAIT |
| NT-071 | Migration SQLite → Postgres + Alembic | server | Should | M | À FAIRE |
| NT-072 | Framework de migrations Hive | app | Should | M | FAIT |
| NT-073 | Normalisation calibres + dernier calibre utilisé | app | Could | S | À FAIRE |
| NT-074 | Saisie séries plein écran + navigation rapide | app | Could | M | À FAIRE |
| NT-075 | Onboarding + aide contextuelle | app | Could | M | FAIT |
| NT-076 | Cache stats + compactage Hive | app | Could | M | À FAIRE |

### NT-070 — Déploiement serveur (Render)
- **Portée** : server · **Dépendances** : — · **Critères d'acceptation** : déploiement via `render.yaml` ; variables d'env (JWT, OAuth, `MISTRAL_API_KEY`) documentées.
- **Statut** : FAIT — `render.yaml`, `docs/tech/render_setup.md`.

### NT-071 — Migration SQLite → Postgres + Alembic
- **Portée** : server · **Dépendances** : — · **Critères d'acceptation** : moteur Postgres ; migrations Alembic. · **Priorité** : Should · **Statut** : À FAIRE. · **Notes** : débloque aussi rate-limit/state multi-instance (NT-062/063).

### NT-072 — Framework de migrations Hive
- **Portée** : app · **Dépendances** : — · **Description** : Runner générique de migrations de schéma local (ancien P5).
- **Critères d'acceptation** : `MigrationRunner` applique les migrations par version croissante ; version stockée.
- **Statut** : FAIT — `lib/migrations/` (`MigrationRunner`, `SchemaVersionStore`, migrations 2 & 3).
- **Notes** : le **script de vérification de cohérence de schéma** (part du P5) reste À FAIRE — le tracer comme sous-tâche si besoin.

### NT-073 — Normalisation calibres + dernier calibre utilisé
- **Portée** : app · **Dépendances** : NT-001 · **Description** : Hygiène de données (ancien P10) : normaliser les calibres, persister le dernier utilisé.
- **Critères d'acceptation** : liste de calibres normalisée ; pré-remplissage du dernier calibre. · **Priorité** : Could · **Statut** : À FAIRE.

### NT-074 — Saisie séries plein écran + navigation rapide
- **Portée** : app · **Dépendances** : NT-002 · **Description** : Mode plein écran + next/prev pour réduire la friction de saisie (ancien P6).
- **Critères d'acceptation** : saisie plein écran ; navigation rapide entre séries. · **Priorité** : Could · **Statut** : À FAIRE.

### NT-075 — Onboarding + aide contextuelle
- **Portée** : app · **Dépendances** : — · **Description** : Mini-onboarding (3 écrans) + bouton « ? » contextuel (ancien P9).
- **Critères d'acceptation** : onboarding au 1er lancement ; aide sur Objectifs/Exercices/Sessions. · **Priorité** : Could · **Statut** : FAIT (2026-07-07, sprint S2) — `OnboardingScreen`/`OnboardingGate` (3 écrans, flag `onboarding_seen`, ré-accès via Paramètres > Aide), `HelpButton` sur Sessions, Objectifs, Exercices (+ hub Exercices & Objectifs).

### NT-076 — Cache stats + compactage Hive
- **Portée** : app · **Dépendances** : NT-010 · **Description** : Cache mémoire des stats (TTL courte) + compactage Hive périodique (ancien P8).
- **Critères d'acceptation** : stats mises en cache ; compactage déclenché sur seuil. · **Priorité** : Could · **Statut** : À FAIRE.

---

## Thème 9 — Idées / hors-scope

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-090 | Thème ASCII Art | app | Won't-now | M | À FAIRE |
| NT-091 | Revoir les règles de sécurité FFTir | app | Won't-now | S | À FAIRE |
| NT-092 | Thèmes visuels (thème clair « France ») | app | Could | S | FAIT |

### NT-090 — Thème ASCII Art
- **Portée** : app · **Description** : Thème visuel ASCII Art (cf. `docs/specs/ascii_art_theme.md`). · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-091 — Revoir les règles de sécurité FFTir
- **Portée** : app · **Description** : Intégrer/mettre à jour les règles de sécurité FFTir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-092 — Thèmes visuels (thème clair « France »)
- **Portée** : app · **Description** : Thématisation de l'app, dont le thème clair « France ». · **Priorité** : Could · **Statut** : FAIT — commit `feat: thème clair France`. · **Notes** : d'autres thèmes possibles (voir NT-090).

---

## Backlog priorisé

> **Dernière mise à jour** : 2026-07-07.
> Découpage en sprints de 2 semaines. Chaque sprint livre un produit (app +
> serveur) cohérent, fonctionnel, sans régression. Les items FAIT ne figurent pas
> ici. Les Won't-now sont en Icebox.
>
> **Contexte** : dev solo (Senior + agentic dev Claude Code), vélocité élevée.
> **Contrainte** : beta demo à la FFTir début août 2026 — S1 et S2 doivent être
> livrés avant cette date.

### Vue synthétique

| Sprint | Thème | Items | Portée | Deadline |
|---|---|---|---|---|
| **S1** | Sécurité & Qualité | NT-061, NT-065, NT-066, NT-051 | both | **Pré-demo** |
| **S2** | Demo-ready | NT-075, NT-032 | both | **Pré-demo** |
| **S3** | Robustesse serveur | NT-055, NT-054, NT-048, NT-053 | server | Post-demo |
| **S4** | Enrichissement fonctionnel | NT-005, NT-025, NT-073, NT-014 | app | — |
| **S5** | UX & Performance | NT-074, NT-076 | app | — |
| **S6** | Fonctionnalités avancées | NT-033, NT-023, NT-024, NT-015, NT-044 | both | — |
| **Icebox** | Won't-now / pas prioritaire | NT-006, NT-045, NT-046, NT-047, NT-071, NT-090, NT-091 | — | — |

---

### Sprint 1 — Sécurité & Qualité ⚡ PRÉ-DEMO

*Objectif : éliminer la dette sécurité (le seul Must restant) et poser la base
qualité. Prérequis à la beta demo FFTir.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-061 | Coach connecté uniquement — retrait clé Mistral client + rotation | both | Must | M |
| 2 | NT-065 | Restreindre CORS par environnement | server | Should | S |
| 3 | NT-066 | Vérification du nonce Google | server | Should | S |
| 4 | NT-051 | Analyse statique & lint (durcir) | app | Should | S |

**Justification** :
- NT-061 est le seul item **Must** non terminé ; il ferme la faille clé Mistral
  côté client. **Bloquant** pour la demo.
- NT-065 et NT-066 sont des quick-wins sécurité (S) identifiés dans l'audit.
- NT-051 stabilise la qualité statique avant d'empiler des features.

**Critère de fin de sprint** : `flutter analyze` zéro warning, coach
inaccessible sans authentification (message clair), CORS restreint en prod,
nonce Google vérifié, clé Mistral historique rotée.

### Sprint 2 — Demo-ready ⚡ PRÉ-DEMO

*Objectif : rendre l'app prête pour la demo FFTir — première impression soignée
et coach différenciant.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-075 | Onboarding + aide contextuelle | app | Could → **Must** (demo) | M |
| 2 | NT-032 | Multi-personas coach (neutre / cool) | both | Should | M |

**Justification** :
- NT-075 est **critique pour la demo** : les membres FFTir découvriront l'app
  pour la première fois. Un mini-onboarding (3 écrans) + aide contextuelle sur
  Objectifs/Exercices/Sessions guide la prise en main.
- NT-032 a du scaffolding existant (`prompt_variant`, `_VARIANT_FILES`) et rend
  le coach plus vivant en demo. Le ton « cool » est un atout marketing.

**Critère de fin de sprint** : onboarding au 1er lancement, aide « ? »
contextuelle, ≥ 2 tons de coach sélectionnables. **App buildée en APK de demo.**

### Sprint 3 — Robustesse serveur

*Objectif : rendre le serveur production-ready (CI, tests, auth durable,
observabilité). Fondation avant d'ajouter des features serveur post-demo.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-055 | CI serveur (tests + couverture) | server | Should | S |
| 2 | NT-054 | Tests OAuth mockés (providers externes) | server | Should | M |
| 3 | NT-048 | Refresh tokens + rotation | server | Should | M |
| 4 | NT-053 | Logging structuré + tracing | server | Should | M |

**Justification** :
- NT-055 (CI) est la fondation : sans CI, aucune PR serveur n'est fiable.
- NT-054 sécurise l'auth qui est le point d'entrée de tout le coach.
- NT-048 améliore l'UX (sessions longues sans re-login) — retour probable de la
  demo FFTir.
- NT-053 donne de la visibilité en production, d'autant plus utile si la demo
  génère du trafic.

**Critère de fin de sprint** : pipeline CI vert, providers OAuth mockés, refresh
tokens fonctionnels, logs structurés en JSON.

### Sprint 4 — Enrichissement fonctionnel

*Objectif : améliorer le carnet de tir au quotidien.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-005 | Attacher une photo de la cible | app | Could | M |
| 2 | NT-025 | Niveau de difficulté d'exercice | app | Could | S |
| 3 | NT-073 | Normalisation calibres + dernier calibre utilisé | app | Could | S |
| 4 | NT-014 | Comparatif glissant 30j vs 60j + sparkline | app | Could | M |

**Justification** :
- NT-005 enrichit visuellement le carnet (photo = mémoire visuelle) et prépare
  NT-006 (analyse image, Icebox).
- NT-025 et NT-073 sont des quick-wins (S) qui améliorent l'hygiène de données.
- NT-014 apporte de la profondeur aux statistiques existantes.

**Critère de fin de sprint** : photos attachées aux sessions, exercices
filtrables par difficulté, calibres normalisés avec pré-remplissage, sparklines
sur le dashboard.

### Sprint 5 — UX & Performance

*Objectif : réduire la friction utilisateur et préparer la montée en volumétrie.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-074 | Saisie séries plein écran + navigation rapide | app | Could | M |
| 2 | NT-076 | Cache stats + compactage Hive | app | Could | M |

**Justification** :
- NT-074 réduit la friction du cœur de métier (saisie de tir).
- NT-076 anticipe la dégradation de performance avec la volumétrie.

**Critère de fin de sprint** : saisie séries plein écran, stats cachées avec
TTL, compactage Hive automatique.

### Sprint 6 — Fonctionnalités avancées

*Objectif : boucler les features avancées. NT-033 pourra être affiné entre-temps
(scope, UX, prompts).*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-033 | Écran Coach : analyse transverse multi-sessions | both | Should | L |
| 2 | NT-023 | Création d'exercice par le coach | both | Could | L |
| 3 | NT-024 | Stats d'exécution exercices (fenêtres glissantes) | app | Could | M |
| 4 | NT-015 | Recommandations croisées Objectifs ⇄ Exercices | app | Could | M |
| 5 | NT-044 | Authentification OAuth Facebook (partie app) | both | Could | M |

**Justification** :
- NT-033 est repoussée ici volontairement : le scope et les prompts ne sont pas
  encore définis. Le temps post-demo permet de mûrir la vision.
- NT-023 dépend du format de sortie structuré du coach (à définir avec NT-033).
- NT-024 et NT-015 exploitent les liens exercices ↔ sessions/objectifs déjà en
  place.
- NT-044 a une valeur marginale (serveur déjà prêt, seul le bouton app manque).

**Critère de fin de sprint** : écran Coach multi-sessions fonctionnel, coach
proposant des exercices structurés, stats d'usage, recommandations croisées,
login Facebook disponible.

### Icebox (Won't-now / pas prioritaire)

*Items explicitement écartés pour le moment. À réexaminer lors d'un futur cycle
de planification.*

| ID | Titre | Raison |
|---|---|---|
| NT-006 | Analyse d'image de la cible | Coûteux (vision par ordinateur), dépend de NT-005 |
| NT-045 | Stats publiques / partage de profil | Pas de demande utilisateur identifiée |
| NT-046 | Gamification | Scope large, pas prioritaire |
| NT-047 | Apple Sign In | Requis uniquement pour publication iOS avec login social |
| NT-071 | Migration SQLite → Postgres | Montée en charge non prévue à court/moyen terme |
| NT-090 | Thème ASCII Art | Cosmétique, pas de valeur métier |
| NT-091 | Règles de sécurité FFTir | À instruire quand le besoin se précise |

### Décisions prises (2026-07-07)

| Sujet | Décision |
|---|---|
| NT-071 (Postgres) | **Icebox** — SQLite single-instance suffit à moyen terme. |
| NT-033 (Coach multi-sessions) | **Repoussé en S6** — nice-to-have, scope et prompts pas encore définis. |
| Cadence | Senior + agentic dev (Claude Code), sprints de 2 semaines. |
| Demo FFTir | **Début août 2026** — S1 (sécurité) et S2 (onboarding + multi-personas) sont bloquants. |
| NT-075 (Onboarding) | **Remonté en S2** — critique pour la première impression en demo FFTir. |
