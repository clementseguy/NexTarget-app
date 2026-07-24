# Vue APP — projection du backlog unifié

> **Projection, pas source.** Cette vue liste les items du
> [backlog unifié](backlog-unifie.md) dont la **portée** est `app` ou `both`,
> côté application Flutter. Toute évolution produit se fait **dans le backlog
> unifié**, puis se répercute ici. Aucune information produit ne doit exister
> uniquement dans cette vue (règle de sync : [README.md](README.md)).

**Repo** : NexTarget-app (Flutter/Dart, Hive, SonarCloud, dart_code_metrics)
**Dernière projection** : 2026-07-24 (ajout NT-026 à la suite de la recette NT-007)

## Items app

| ID | Titre | Portée | Prio | Est | Statut | Note app |
|---|---|---|---|---|---|---|
| NT-001 | Enregistrer une session de tir | app | Must | M | FAIT | `ShootingSession`, `create_session_screen` |
| NT-002 | Saisir des séries détaillées | app | Must | M | FAIT | `Series`, `session_form` |
| NT-003 | Historique & détail des sessions | app | Must | M | FAIT | `sessions_history_screen`, `session_detail` |
| NT-004 | Synthèse libre du tireur | app | Should | S | FAIT | `ShootingSession.synthese` |
| NT-005 | Attacher une photo de la cible | app | Must | M | À FAIRE | Could → Must (2026-07-13), socle thème 11 |
| NT-006 | Analyse d'image de la cible | both | Won't-now | L | À FAIRE | capture côté app, analyse côté serveur |
| NT-007 | Filtrer l'historique des sessions par exercice | app | Could | S | À FAIRE | issue #5 |
| NT-010 | Tableau de bord statistiques | app | Must | M | FAIT | `dashboard_service`, `widgets/dashboard` |
| NT-011 | Statistiques explicatives / évolution | app | Should | M | FAIT | `stats_service`, `evolution_chart` |
| NT-012 | Objectifs mesurables | app | Must | M | FAIT | `Goal`, `goal_service` |
| NT-013 | Hauts faits (records) | app | Should | S | FAIT | `GoalMetric` (best*) |
| NT-014 | Comparatif 30j vs 60j + sparkline | app | Could | M | À FAIRE | — |
| NT-015 | Recommandations Objectifs ⇄ Exercices | app | Could | M | À FAIRE | dépend NT-012, NT-021 |
| NT-016 | Objectifs enrichis : statuts étendus, journal, vue détail | app | Could | M | À FAIRE | issue #5 |
| NT-020 | Gérer des exercices (CRUD) | app | Must | M | FAIT | `Exercise`, écrans list/form |
| NT-021 | Lier exercices ↔ objectifs | app | Should | S | FAIT | `Exercise.goalIds` |
| NT-022 | Lier exercices ↔ sessions | app | Should | S | FAIT | `ShootingSession.exercises` |
| NT-023 | Création d'exercice par le coach | both | Could | L | À FAIRE | consomme sortie coach (NT-030) |
| NT-024 | Stats d'exécution (fenêtres glissantes) | app | Could | M | À FAIRE | `usageCount` / `lastPerformedAt` |
| NT-025 | Niveau de difficulté d'exercice | app | Could | S | À FAIRE | — |
| NT-026 | Supprimer un exercice depuis l'interface | app | Could | S | À FAIRE | confirmation ; sessions conservées ; recette du filtre NT-007 après suppression |
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT | `ServerCoachAnalysisService` (si connecté) |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | FAIT | préférence `coach_persona` (Paramètres uniquement), envoi `prompt_variant` |
| NT-033 | Écran "Coach" transverse | both | Should | L | À FAIRE | `coach_screen.dart` = placeholder |
| NT-040 | Authentification OAuth Google | both | Must | M | FAIT | `auth_service.dart`, `auth_provider` |
| NT-041 | Authentification optionnelle | app | Must | S | FAIT | mode déconnecté préservé |
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT | `profile_screen.dart` — édition à vérifier |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À FAIRE | serveur : code présent, à valider (tests mockés) ; bouton app non câblé ; non prioritaire |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE | — |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE | — |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE | — |
| NT-050 | SonarCloud + Quality Gate | app | Must | M | FAIT | `sonar-project.properties`, CI |
| NT-051 | Analyse statique & lint (durcir) | app | Should | S | FAIT | `flutter_lints` actif, zéro issue, step CI `analyze --fatal-infos` |
| NT-052 | Cahier de recette généré | app | Should | S | FAIT | `scripts/generate_cahier_recette.dart` |
| NT-056 | Harmonisation des erreurs réseau | app | Could | S | À FAIRE | issue #5 ; coach déjà conforme |
| NT-057 | Nettoyage des widgets dupliqués | app | Could | S | À FAIRE | issue #5 ; MainNavigation déjà supprimé |
| NT-061 | Coach connecté uniquement (retrait clé client) | both | Must | M | FAIT | `CoachAnalysisService` direct supprimé ; rotation clé = action manuelle |
| NT-072 | Framework de migrations Hive | app | Should | M | FAIT | `lib/migrations/` (script cohérence : à faire) |
| NT-073 | Normalisation calibres + dernier calibre | app | Could | S | À FAIRE | — |
| NT-074 | Saisie séries plein écran + navigation | app | Could | M | À FAIRE | — |
| NT-075 | Onboarding + aide contextuelle | app | Could | M | FAIT | `OnboardingGate` (3 écrans) + `HelpButton` ; ajustements recette 2026-07-09 |
| NT-076 | Cache stats + compactage Hive | app | Could | M | À FAIRE | — |
| NT-090 | Thème ASCII Art | app | Won't-now | M | À FAIRE | `docs/specs/ascii_art_theme.md` |
| NT-091 | Règles de sécurité FFTir | app | Won't-now | S | À FAIRE | — |
| NT-092 | Thèmes visuels (thème clair « France ») | app | Could | S | FAIT | — |
| NT-100 | Référentiel des disciplines officielles (TAR 25 m) | app | Must | M | À FAIRE | seed `docs/specs/referentiel_tar_25m.md` |
| NT-101 | Sessions & séries typées discipline | app | Must | M | À FAIRE | ajouts Hive additifs (séquence, temps, gongs) |
| NT-102 | Mode « match blanc » TAR | app | Should | L | À FAIRE | déroulé guidé 830/831/832, chrono |
| NT-103 | Comparaison aux grilles de classement FFTir | app | Could | M | À FAIRE | sourcing RGS FFTir préalable |
| NT-104 | Stats & records par discipline | app | Should | M | À FAIRE | filtres/records par épreuve |
| NT-110 | Métadonnées cible & photo par série | app | Should | S | À FAIRE | type de cible, distance, série |
| NT-111 | Analyse qualitative photo par le coach | both | Should | M | À FAIRE | envoi photo au proxy multimodal |
| NT-120 | Payload d'analyse transverse compact | app | Must | M | À FAIRE | agrégats + N dernières sessions, par discipline |
| NT-121 | Écran Coach : analyse de progression | both | Should | L | À FAIRE | remplace le périmètre UX de NT-033 |
| NT-123 | Coach propose des exercices | both | Should | L | À FAIRE | préviz/édition + déduplication (précise NT-023) |
| NT-124 | Coach propose des objectifs | both | Should | M | À FAIRE | validation avant création |
| NT-125 | Suivi des recommandations du coach | both | Could | L | À FAIRE | — |
| NT-126 | Plan d'entraînement | both | Could | L | À FAIRE | dépend NT-123/NT-124 |
| NT-130 | Templates de session | app | Must | S | À FAIRE | quick win — dernier setup + favoris |
| NT-131 | Session live au stand | app | Should | M | À FAIRE | saisie au fil du tir + chrono repos |
| NT-132 | Spike — saisie vocale d'une série | app | Could | S | À FAIRE | go/no-go en environnement stand |

## Prochaines actions app (hors FAIT), par priorité

- **Must** — NT-005 (photo de cible), NT-100/NT-101 (socle disciplines TAR), NT-120 (socle coach), NT-130 (templates de session).
- **Should** — NT-042 (édition profil à confirmer), NT-102, NT-104, NT-110, NT-111, NT-121, NT-123, NT-124, NT-131. NT-033 : voir NT-120/NT-121.
- **Could** — NT-007, NT-014, NT-015, NT-016, NT-024, NT-025, NT-026, NT-044, NT-056, NT-057, NT-073, NT-074, NT-076, NT-103, NT-125, NT-126, NT-132. NT-023 : voir NT-122/NT-123.
- **Won't-now** — NT-006, NT-045, NT-046, NT-047, NT-090, NT-091.
