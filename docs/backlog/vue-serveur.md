# Vue SERVEUR — projection du backlog unifié

> **Projection, pas source.** Cette vue liste les items du
> [backlog unifié](backlog-unifie.md) dont la **portée** est `server` ou `both`,
> côté backend FastAPI. La source de vérité est le **backlog unifié** (dans le
> repo NexTarget-app) ; ce fichier en découle. Aucune information produit ne doit
> exister uniquement ici. Règle de sync : [README.md](README.md).
>
> ℹ️ Ce fichier est destiné à être **copié dans le repo NexTarget-server**
> (ex. `docs/specs/vue-serveur.md`) ; le backlog du serveur ne fait plus que
> pointer vers lui (voir gouvernance).

**Repo** : NexTarget-server (FastAPI + SQLModel + SQLite, OAuth + proxy IA)
**Dernière projection** : 2026-07-13 (enrichissement thèmes 11–12 ; état du code : 2026-07-07)

> ⚠️ **Le serveur n'est plus « OAuth-only ».** Il expose aussi le **proxy Coach IA**
> (`/coach/analyze-session`). Les anciens statuts « M1/M2 supprimés/décalés » sont
> **périmés** — voir [incoherences.md](incoherences.md) I1.

## Items serveur

| ID | Titre | Portée | Prio | Est | Statut | Note serveur |
|---|---|---|---|---|---|---|
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT | `POST /coach/analyze-session` (`api/coach.py`) |
| NT-031 | Prompt d'analyse centralisé | server | Must | S | FAIT | `services/prompt_builder.py`, `prompts/coach_neutre.yaml` |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | À FAIRE | `_VARIANT_FILES` prêt ; 1 seule variante livrée |
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
| NT-048 | Refresh tokens + rotation | server | Should | M | FAIT | `/auth/token/refresh` + `/revoke`, rotation + détection de rejeu |
| NT-053 | Logging structuré + tracing | server | Should | M | FAIT | logs JSON + corrélation X-Request-ID (sans OTel) |
| NT-054 | Tests OAuth mockés | server | Should | M | FAIT | `test_oauth_flows.py` : flows complets Google/Facebook mockés |
| NT-055 | CI serveur (tests + couverture) | server | Should | S | FAIT | `.github/workflows/ci.yml` (pytest + cov, Python 3.11) |
| NT-060 | Proxy Mistral (clé hors client) | server | Must | M | FAIT | `services/mistral_client.py`, `core/config.py` |
| NT-061 | Coach connecté uniquement + rotation clé | both | Must | M | FAIT | code livré (S1) ; rotation clé = action manuelle |
| NT-062 | Rate limiting endpoint coach | server | Must | S | FAIT | `services/rate_limiter.py` (10/5min) |
| NT-063 | State OAuth à usage unique (CSRF) | server | Must | S | FAIT | `services/oauth_state.py` |
| NT-064 | Vérification du type de token JWT | server | Must | S | FAIT | `core/security.py`, `api/deps.py` |
| NT-065 | Restreindre CORS par environnement | server | Should | S | FAIT | `CORS_ALLOW_ORIGINS` ; `*` en dev, aucune origine sinon |
| NT-066 | Vérification du nonce Google | server | Should | S | FAIT | nonce OIDC vérifié au callback (400 sinon) |
| NT-070 | Déploiement serveur (Render) | server | Must | S | FAIT | `render.yaml`, `docs/tech/render_setup.md` |
| NT-071 | Migration SQLite → Postgres + Alembic | server | Should | M | À FAIRE | débloque multi-instance (NT-062/063) |
| NT-006 | Analyse d'image de la cible | both | Won't-now | L | À FAIRE | vraisemblablement côté serveur |

## Prochaines actions serveur (hors FAIT), par priorité

- **Must** — (aucun ; la rotation manuelle de la clé Mistral reste à faire côté ops, cf. NT-061).
- **Should** — NT-048 (refresh tokens), NT-053 (logging/tracing), NT-054 (tests OAuth mockés), NT-055 (CI serveur), NT-071 (Postgres/Alembic), NT-032/NT-033 (coach avancé).
- **Won't-now** — NT-045, NT-046, NT-047, NT-006.

## Note de cohérence documentaire

L'`AGENTS.md` du serveur est **périmé** sur 3 points (il décrit un état antérieur) :
« aucune fonctionnalité IA », « pas de rate limiting », « User minimal (email + provider) ».
Le code contredit les trois (proxy coach, rate limiter, profil enrichi). À corriger —
suivi dans [incoherences.md](incoherences.md) I3/I6.
