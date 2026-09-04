# Vue SERVEUR — projection du backlog unifié

> **Projection, pas source.** Cette vue liste les items du
> [backlog unifié](backlog-unifie.md) dont la **portée** est `server` ou `both`,
> côté backend FastAPI. La source de vérité est le **backlog unifié** (dans le
> repo NexTarget-app) ; ce fichier en découle. Aucune information produit ne doit
> exister uniquement ici. Règle de sync : [README.md](README.md).
>
> Note : ce fichier est la **vue serveur canonique** et reste maintenu dans
> `NexTarget-app`. Le repo `NexTarget-server` pointe vers lui sans en maintenir
> de copie ; aucune synchronisation inverse n'est attendue (voir gouvernance).

**Repo** : NexTarget-server (FastAPI + SQLModel + PostgreSQL en production, SQLite en développement/tests, OAuth + proxy IA)
**Dernière projection** : 2026-09-04 (préparation de la release app v0.7.0 ; NT-048 et NT-061 restent `FAIT`, sans changement du contrat serveur v0.3.0)

> Important : **le serveur n'est plus « OAuth-only ».** Il expose aussi le **proxy Coach IA**
> (`/coach/analyze-session`). Les anciens statuts « M1/M2 supprimés/décalés » sont
> **périmés** et supprimés ; le proxy Coach est bien une responsabilité active du serveur.

## Items serveur

| ID | Titre | Portée | Prio | Est | Statut | Note serveur |
|---|---|---|---|---|---|---|
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT | `POST /coach/analyze-session` (`api/coach.py`) |
| NT-031 | Prompt d'analyse centralisé | server | Must | S | FAIT | `services/prompt_builder.py`, `prompts/coach_neutre.yaml` |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | FAIT | `coach_neutre.yaml` + `coach_cool.yaml`, sélection via `prompt_variant` |
| NT-033 | Écran "Coach" transverse (endpoint agrégé) | both | Should | L | À FAIRE | nécessitera un endpoint d'analyse multi-sessions |
| NT-034 | Affiner les prompts des personas coach | server | Could | S | À FAIRE | itération contenu `coach_neutre`/`coach_cool` (recette S2) |
| NT-111 | Analyse qualitative photo par le coach | both | Should | M | À FAIRE | endpoint proxy multimodal (ex. Pixtral), JWT + rate limit, specs cible dans le prompt |
| NT-121 | Écran Coach : analyse de progression | both | Should | L | À FAIRE | endpoint d'analyse multi-sessions (payload agrégé NT-120) — remplace NT-033 |
| NT-122 | Sortie coach structurée (JSON schema) | server | Must | M | À FAIRE | structured outputs conformes aux schémas `Exercise`/`Goal`, versionnés |
| NT-123 | Coach propose des exercices | both | Should | L | À FAIRE | génération via NT-122 (précise NT-023) |
| NT-124 | Coach propose des objectifs | both | Should | M | À FAIRE | génération via NT-122 |
| NT-125 | Suivi des recommandations du coach | both | Could | L | À FAIRE | recos réinjectées dans le contexte d'analyse |
| NT-126 | Plan d'entraînement | both | Could | L | À FAIRE | dépend NT-123/NT-124 |
| NT-040 | Authentification OAuth Google | both | Must | M | FAIT | `api/auth_google.py`, `/auth/token` |
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT | `models/user.py` (champs profil) |
| NT-043 | Endpoint `/users/me` | server | Must | S | FAIT | `api/users.py` |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À FAIRE | code `api/auth_facebook.py` présent, à valider (tests mockés seulement, non éprouvé contre une vraie app FB) ; côté app non câblé ; non prioritaire |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE | — |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE | — |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE | roadmap v0.2 |
| NT-048 | Refresh tokens + rotation | both | Should | M | FAIT | expiration glissante 30 j, `/refresh`, `/revoke`, rotation et détection de rejeu ; contrat vérifié conforme et inchangé lors de l'adoption app |
| NT-049 | Interface d’administration read-only des utilisateurs | server | Should | M | FAIT | `GET /app/admin/users` : page HTML admin protégée, consultation uniquement ; audit du login Google documenté |
| NT-053 | Logging structuré + tracing | server | Should | M | FAIT | logs JSON + corrélation X-Request-ID (sans OTel) |
| NT-054 | Tests OAuth mockés | server | Should | M | FAIT | `test_oauth_flows.py` : flows complets Google/Facebook mockés |
| NT-055 | CI serveur (tests + couverture) | server | Should | S | FAIT | `.github/workflows/ci.yml` (pytest + cov, Python 3.11) |
| NT-060 | Proxy Mistral (clé hors client) | server | Must | M | FAIT | `services/mistral_client.py`, `core/config.py` |
| NT-061 | Coach connecté uniquement + rotation clé | both | Must | M | FAIT | audit de clôture validé ; clé historique rotée ; proxy Mistral serveur conservé comme chemin légitime unique |
| NT-062 | Rate limiting endpoint coach | server | Must | S | FAIT | `services/rate_limiter.py` (10/5min) |
| NT-063 | State OAuth à usage unique (CSRF) | server | Must | S | FAIT | `services/oauth_state.py` |
| NT-064 | Vérification du type de token JWT | server | Must | S | FAIT | `core/security.py`, `api/deps.py` |
| NT-065 | Restreindre CORS par environnement | server | Should | S | FAIT | `CORS_ALLOW_ORIGINS` ; `*` en dev, aucune origine sinon |
| NT-066 | Vérification du nonce Google | server | Should | S | FAIT | nonce OIDC vérifié au callback (400 sinon) |
| NT-070 | Déploiement serveur (Render) | server | Must | S | FAIT | `render.yaml`, `docs/tech/render_setup.md` |
| NT-071 | Migration SQLite → Postgres Neon + Alembic | server | Must | M | FAIT | livré avec v0.6.0 (serveur v0.3.0) ; Neon Frankfurt, Alembic, URLs et rôles runtime/migration séparés |
| NT-006 | Analyse d'image de la cible | both | Won't-now | L | À FAIRE | vraisemblablement côté serveur |

## Prochaines actions serveur (hors FAIT), par priorité

- **Must** — NT-122 (sortie coach structurée).
- **Should** — NT-033 (voir NT-120/NT-121), NT-111, NT-121, NT-123, NT-124.
- **Could** — NT-034, NT-044, NT-125, NT-126.
- **Won't-now** — NT-045, NT-046, NT-047, NT-006.

NT-048 est désormais `FAIT` des deux côtés : le contrat serveur n'a pas eu
besoin d'évoluer pour l'adoption app (vérifié le 2026-09-02).

## Note de cohérence documentaire

L'`AGENTS.md` du serveur décrit désormais correctement le proxy Coach, le rate
limiting, le profil enrichi et PostgreSQL. Les anciennes specs conservées sous
Les anciens backlogs serveur ont été supprimés : ce document est l'unique vue
serveur locale et reste une projection du backlog unifié.
