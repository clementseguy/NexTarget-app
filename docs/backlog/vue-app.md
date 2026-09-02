# Vue APP — projection du backlog unifié

> **Projection, pas source.** Cette vue liste les items du
> [backlog unifié](backlog-unifie.md) dont la **portée** est `app` ou `both`,
> côté application Flutter. Toute évolution produit se fait **dans le backlog
> unifié**, puis se répercute ici. Aucune information produit ne doit exister
> uniquement dans cette vue (règle de sync : [README.md](README.md)).

**Repo** : NexTarget-app (Flutter/Dart, Hive, SonarCloud, dart_code_metrics)
**Dernière projection** : 2026-09-02 (cadrage détaillé NT-014, NT-048, NT-073 et NT-133 ; clôture NT-061 clarifiée)

## Items app

| ID | Titre | Portée | Prio | Est | Statut | Note app |
|---|---|---|---|---|---|---|
| NT-001 | Enregistrer une session de tir | app | Must | M | FAIT | `ShootingSession`, `create_session_screen` |
| NT-002 | Saisir des séries détaillées | app | Must | M | FAIT | `Series`, `session_form` |
| NT-003 | Historique & détail des sessions | app | Must | M | FAIT | `sessions_history_screen`, `session_detail` |
| NT-004 | Synthèse libre du tireur | app | Should | S | FAIT | `ShootingSession.synthese` |
| NT-005 | Attacher une photo de la cible | app | Must | M | FAIT | livré par la PR #12 le 2026-07-17 |
| NT-006 | Analyse d'image de la cible | both | Won't-now | L | À FAIRE | capture côté app, analyse côté serveur |
| NT-007 | Filtrer l'historique des sessions par exercice | app | Could | S | FAIT | livré par la PR #12 le 2026-07-17 |
| NT-008 | Gérer son râtelier d'armes | app | Must | M | FAIT | livré en v0.6.0 ; CRUD textuel dans Paramètres ; renommage propagé atomiquement aux sessions correspondantes ; export/import rétrocompatible |
| NT-009 | Autocompléter l'arme d'une session depuis le râtelier | app | Must | M | FAIT | livré en v0.6.0 ; saisie libre prioritaire ; création/édition, prévue/réalisée et wizard |
| NT-010 | Tableau de bord statistiques | app | Must | M | FAIT | `dashboard_service`, `widgets/dashboard` |
| NT-011 | Statistiques explicatives / évolution | app | Should | M | FAIT | `stats_service`, `evolution_chart` |
| NT-012 | Objectifs mesurables | app | Must | M | FAIT | `Goal`, `goal_service` |
| NT-013 | Hauts faits (records) | app | Should | S | FAIT | `GoalMetric` (best*) |
| NT-014 | Comparatif 30j vs 90j + sparkline | app | Could | M | EN COURS | score et groupement indépendants ; deltas absolu/relatif ; un point par session, sparkline à partir de 5 sessions exploitables ; UI mobile et deux thèmes |
| NT-015 | Recommandations Objectifs ⇄ Exercices | app | Could | M | À FAIRE | dépend NT-012, NT-021 |
| NT-016 | Objectifs enrichis : statuts étendus, journal, vue détail | app | Could | M | À FAIRE | issue #5 |
| NT-017 | Compteur de tirs par arme du râtelier | app | Should | S | FAIT | livré en v0.6.0 ; compteurs simples en bas de Statistiques > Avancé ; étendu par NT-133 aux tirs des sessions libres réalisées |
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
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT | affichage du profil et édition du niveau ; édition du pseudo explicitement hors périmètre |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À FAIRE | serveur : code présent, à valider (tests mockés) ; bouton app non câblé ; non prioritaire |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE | — |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE | — |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE | — |
| NT-048 | Refresh tokens + rotation | both | Should | M | EN COURS | serveur livré ; stockage sécurisé, renouvellement proactif, single-flight, retry unique et résilience hors ligne à câbler dans l'app |
| NT-050 | SonarCloud + Quality Gate | app | Must | M | FAIT | `sonar-project.properties`, CI |
| NT-051 | Analyse statique & lint (durcir) | app | Should | S | FAIT | `flutter_lints` actif, zéro issue, step CI `analyze --fatal-infos` |
| NT-052 | Cahier de recette généré | app | Should | S | FAIT | `scripts/generate_cahier_recette.dart` |
| NT-056 | Harmonisation des erreurs réseau | app | Could | S | À FAIRE | issue #5 ; coach déjà conforme |
| NT-057 | Nettoyage des widgets dupliqués | app | Could | S | À FAIRE | issue #5 ; MainNavigation déjà supprimé |
| NT-058 | Fakes de repository partagés pour les tests | app | Should | S | FAIT | `test/support/` (`FakeSessionRepository`, `captureError`) ; déclenché par NT-008 |
| NT-061 | Coach connecté uniquement (retrait clé client) | both | Must | M | FAIT | audit de clôture validé : chemin serveur unique, aucun fallback client, clé historique rotée et docs actives clarifiées |
| NT-072 | Framework de migrations Hive | app | Should | M | FAIT | `lib/migrations/` (script cohérence : à faire) |
| NT-073 | Calibre par défaut + normalisation statistique | app | Could | S | EN COURS | préférence facultative parmi les calibres connus ; saisie libre sans autoremplacement ; alias connus regroupés sans réécriture |
| NT-074 | Saisie séries plein écran + navigation | app | Could | M | À FAIRE | — |
| NT-075 | Onboarding + aide contextuelle | app | Could | M | FAIT | `OnboardingGate` (3 écrans) + `HelpButton` ; ajustements recette 2026-07-09 |
| NT-076 | Cache stats + compactage Hive | app | Could | M | À FAIRE | — |
| NT-090 | Thème ASCII Art | app | Won't-now | M | À FAIRE | `docs/specs/ascii_art_theme.md` |
| NT-091 | Règles de sécurité FFTir | app | Won't-now | S | À FAIRE | — |
| NT-092 | Thèmes visuels (thème clair « France ») | app | Could | S | FAIT | — |
| NT-100 | Référentiel des disciplines officielles (TAR 25 m) | app | Must | M | À FAIRE | seed existant ; prototype non fusionné abandonné, design préalable requis |
| NT-101 | Sessions & séries typées discipline | app | Must | M | À FAIRE | prototype non fusionné abandonné ; parcours TAR à concevoir avant reprise |
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
| NT-130 | Templates de session | app | Must | S | À FAIRE | prototype abandonné : ne pas ajouter d'étape au parcours classique |
| NT-131 | Session live au stand | app | Should | M | À FAIRE | saisie au fil du tir + chrono repos |
| NT-132 | Spike — saisie vocale d'une série | app | Could | S | À FAIRE | go/no-go en environnement stand |
| NT-133 | Sessions libres sans séries ni scores | app | Must | L | À FAIRE | arme/calibre obligatoires, catégorie entraînement/match/test matériel, distance entière, synthèse/photo/exercices facultatifs, sans Coach |

## Prochaines actions app (hors FAIT), par priorité

- **En cours** — NT-014, NT-048, NT-073.
- **Must** — NT-100/NT-101 (socle disciplines TAR), NT-120 (socle coach), NT-130 (templates de session), NT-133 (sessions libres).
- **Should** — NT-102, NT-104, NT-110, NT-111, NT-121, NT-123, NT-124, NT-131. NT-033 : voir NT-120/NT-121. NT-048 conserve cette priorité mais est déjà en cours.
- **Could** — NT-015, NT-016, NT-024, NT-025, NT-026, NT-044, NT-056, NT-057, NT-074, NT-076, NT-103, NT-125, NT-126, NT-132. NT-023 : voir NT-122/NT-123. NT-014 et NT-073 conservent cette priorité mais sont déjà en cours.
- **Won't-now** — NT-006, NT-045, NT-046, NT-047, NT-090, NT-091.
