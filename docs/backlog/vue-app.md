# Vue APP — projection du backlog unifié

> **Projection, pas source.** Cette vue liste les items du
> [backlog unifié](backlog-unifie.md) dont la **portée** est `app` ou `both`,
> côté application Flutter. Toute évolution produit se fait **dans le backlog
> unifié**, puis se répercute ici. Aucune information produit ne doit exister
> uniquement dans cette vue (règle de sync : [README.md](README.md)).

**Repo** : NexTarget-app (Flutter/Dart, Hive, SonarCloud, dart_code_metrics)
**Dernière projection** : 2026-07-07 (état du code)

## Items app

| ID | Titre | Portée | Prio | Est | Statut | Note app |
|---|---|---|---|---|---|---|
| NT-001 | Enregistrer une session de tir | app | Must | M | FAIT | `ShootingSession`, `create_session_screen` |
| NT-002 | Saisir des séries détaillées | app | Must | M | FAIT | `Series`, `session_form` |
| NT-003 | Historique & détail des sessions | app | Must | M | FAIT | `sessions_history_screen`, `session_detail` |
| NT-004 | Synthèse libre du tireur | app | Should | S | FAIT | `ShootingSession.synthese` |
| NT-005 | Attacher une photo de la cible | app | Could | M | À FAIRE | — |
| NT-006 | Analyse d'image de la cible | both | Won't-now | L | À FAIRE | capture côté app, analyse côté serveur |
| NT-010 | Tableau de bord statistiques | app | Must | M | FAIT | `dashboard_service`, `widgets/dashboard` |
| NT-011 | Statistiques explicatives / évolution | app | Should | M | FAIT | `stats_service`, `evolution_chart` |
| NT-012 | Objectifs mesurables | app | Must | M | FAIT | `Goal`, `goal_service` |
| NT-013 | Hauts faits (records) | app | Should | S | FAIT | `GoalMetric` (best*) |
| NT-014 | Comparatif 30j vs 60j + sparkline | app | Could | M | À FAIRE | — |
| NT-015 | Recommandations Objectifs ⇄ Exercices | app | Could | M | À FAIRE | dépend NT-012, NT-021 |
| NT-020 | Gérer des exercices (CRUD) | app | Must | M | FAIT | `Exercise`, écrans list/form |
| NT-021 | Lier exercices ↔ objectifs | app | Should | S | FAIT | `Exercise.goalIds` |
| NT-022 | Lier exercices ↔ sessions | app | Should | S | FAIT | `ShootingSession.exercises` |
| NT-023 | Création d'exercice par le coach | both | Could | L | À FAIRE | consomme sortie coach (NT-030) |
| NT-024 | Stats d'exécution (fenêtres glissantes) | app | Could | M | À FAIRE | `usageCount` / `lastPerformedAt` |
| NT-025 | Niveau de difficulté d'exercice | app | Could | S | À FAIRE | — |
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT | `ServerCoachAnalysisService` (si connecté) |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | À FAIRE | envoi `prompt_variant` (scaffold prêt) |
| NT-033 | Écran "Coach" transverse | both | Should | L | À FAIRE | `coach_screen.dart` = placeholder |
| NT-040 | Authentification OAuth Google | both | Must | M | FAIT | `auth_service.dart`, `auth_provider` |
| NT-041 | Authentification optionnelle | app | Must | S | FAIT | mode déconnecté préservé |
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT | `profile_screen.dart` — édition à vérifier |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À FAIRE | serveur prêt ; bouton app non câblé (basse prio) |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE | — |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE | — |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE | — |
| NT-050 | SonarCloud + Quality Gate | app | Must | M | FAIT | `sonar-project.properties`, CI |
| NT-051 | dart_code_metrics / lint CI | app | Should | S | FAIT | `analysis_options.yaml` |
| NT-052 | Cahier de recette généré | app | Should | S | FAIT | `scripts/generate_cahier_recette.dart` |
| NT-061 | Coach connecté uniquement (retrait clé client) | both | Must | M | EN COURS | supprimer `CoachAnalysisService` direct + clé |
| NT-072 | Framework de migrations Hive | app | Should | M | FAIT | `lib/migrations/` (script cohérence : à faire) |
| NT-073 | Normalisation calibres + dernier calibre | app | Could | S | À FAIRE | — |
| NT-074 | Saisie séries plein écran + navigation | app | Could | M | À FAIRE | — |
| NT-075 | Onboarding + aide contextuelle | app | Could | M | À FAIRE | — |
| NT-076 | Cache stats + compactage Hive | app | Could | M | À FAIRE | — |
| NT-090 | Thème ASCII Art | app | Won't-now | M | À FAIRE | `docs/specs/ascii_art_theme.md` |
| NT-091 | Règles de sécurité FFTir | app | Won't-now | S | À FAIRE | — |
| NT-092 | Thèmes visuels (thème clair « France ») | app | Could | S | FAIT | — |

## Prochaines actions app (hors FAIT), par priorité

- **Must** — NT-061 (retrait clé Mistral client + bascule coach connecté uniquement).
- **Should** — NT-032 (multi-personas coach), NT-033 (écran Coach transverse), NT-042 (édition profil à confirmer).
- **Could** — NT-014, NT-015, NT-023, NT-024, NT-025, NT-044, NT-073, NT-074, NT-075, NT-076.
- **Won't-now** — NT-005/006, NT-045, NT-046, NT-047, NT-090, NT-091.
