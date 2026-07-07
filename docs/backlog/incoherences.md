# Journal des incohérences & décisions

> Écarts détectés entre les **deux anciens backlogs** et l'**état réel du code**
> (audit du 2026-07-07), avec la résolution retenue. Principe directeur :
> **le code fait foi** ; les intentions des anciens backlogs ne priment jamais
> sur l'implémentation observée.

## Anciens backlogs audités
- App : `NexTarget-app/docs/specs/backlog.md`
- Serveur : `NexTarget-server/docs/specs/Backlog v0.1.md`

## Tableau de synthèse

| # | Écart | Résolution | Décideur | Impact |
|---|---|---|---|---|
| I1 | Proxy Coach : « à faire » (app) vs « supprimé/OAuth-only » (serveur) — alors qu'il est **implémenté des deux côtés** | Acter « Coach IA = proxy serveur » comme vérité produit ; le serveur est « OAuth **+ proxy IA** » | Utilisateur (2026-07-07) | NT-030/031/060 = FAIT ; docs serveur à corriger |
| I2 | Double chemin coach (proxy connecté **+** Mistral direct hors-ligne, clé dans le client) | **Coach connecté uniquement** : retrait du chemin direct + clé client + rotation | Utilisateur (2026-07-07) | NT-061 = Must / EN COURS |
| I3 | User « minimal (email+provider) » (docs) vs **profil enrichi** (code) | Le code fait foi : profil enrichi acté | Claude (auto) | NT-042 = FAIT ; AGENTS.md/backlog serveur à corriger |
| I4 | Facebook : **serveur prêt**, **app non câblée** | App = À FAIRE, priorité **basse**, reste au backlog | Utilisateur (2026-07-07) | NT-044 (serveur FAIT / app À FAIRE, Could) |
| I5 | « Plusieurs coachs (neutre/cool) » annoncé, **un seul livré** | Item À FAIRE ; scaffold multi-variant conservé | Claude (auto) | NT-032 = À FAIRE, Should |
| I6 | `AGENTS.md` serveur **périmé** (dit « aucune IA », « pas de rate limiting », « User minimal ») | À réécrire pour refléter le code | Claude (auto) | Tâche doc (voir plus bas) |

---

## Détail des écarts

### I1 — Le proxy Coach est implémenté, pas « supprimé »
- **Constat.** L'ancien backlog app (`backlog.md`) liste « Utiliser le serveur NexTarget-server en tant que Proxy pour les requêtes au Coach » comme *à faire*. L'ancien backlog serveur (`Backlog v0.1.md`) déclare au contraire M1/M2 « ❌ DÉCALÉ » avec la note « supprimées suite à la décision de créer un backend OAuth-only sans fonctionnalités IA ».
- **Réalité du code.** Le serveur expose `POST /coach/analyze-session` (`app/api/coach.py`), avec `mistral_client`, `prompt_builder`, `rate_limiter`. L'app appelle ce endpoint via `ServerCoachAnalysisService`. Commits `feat(coach)` du 2026-07-07, **postérieurs** aux deux backlogs.
- **Résolution (utilisateur, 2026-07-07).** Le proxy Coach est la **vérité produit**. Le serveur n'est plus « OAuth-only » : il est « OAuth **+ proxy IA** ».
- **Impact.** NT-030, NT-031, NT-060, NT-062 = **FAIT**. Les mentions « OAuth-only / no AI » dans les docs serveur sont périmées (voir I3, I6).

### I2 — Double chemin coach → « connecté uniquement »
- **Constat.** L'app conserve deux chemins : `ServerCoachAnalysisService` (proxy, si connecté) et `CoachAnalysisService` (Mistral **direct**, hors-ligne, avec clé embarquée dans le client). Cf. `session_detail_components.dart:154` et CHANGELOG app T5 (« à faire ensuite : retrait clé Mistral côté client + rotation »).
- **Enjeu.** Architecture + sécurité : la clé Mistral dans le client est une surface de fuite ; deux chemins à maintenir.
- **Résolution (utilisateur, 2026-07-07).** **Coach connecté uniquement.** Supprimer le chemin Mistral direct et la clé côté client, puis roter la clé. Le **carnet de tir reste hors-ligne** ; seul le coach devient online-only.
- **Impact.** NT-061 = **Must / EN COURS** (proxy déjà livré ; reste retrait client + rotation).

### I3 — Modèle User : « minimal » vs enrichi
- **Constat.** Le backlog serveur v0.1 insiste : « Aucune info de profil superflue : seulement email + provider ». Le code (`models/user.py`) porte `display_name`, `display_name_custom`, `avatar_url`, `experience_level`.
- **Résolution (Claude, auto — le code fait foi).** Profil enrichi acté (NT-042 = FAIT). Le backlog v0.1 est périmé sur ce point.
- **Impact.** NT-042 = FAIT ; `AGENTS.md` serveur + backlog serveur à corriger (I6).

### I4 — Facebook : serveur prêt, app absente
- **Constat.** Serveur : `api/auth_facebook.py` fonctionnel. App : seul `signInWithGoogle` est câblé (`auth_service.dart`).
- **Résolution (utilisateur, 2026-07-07).** « Facebook plus tard, optionnelle » : reste au backlog en **priorité basse**.
- **Impact.** NT-044 : serveur = FAIT, app = À FAIRE (Could). Statut global À VÉRIFIER tant que l'app n'est pas alignée.

### I5 — Multi-personas coach : annoncé, non livré
- **Constat.** L'ancien backlog app prévoit « coach neutre / coach cool ». Le code n'a qu'un `coach_neutre.yaml`, mais le paramètre `prompt_variant` et le mapping `_VARIANT_FILES` sont déjà en place (app + serveur).
- **Résolution (Claude, auto).** NT-032 = **À FAIRE** (Should), scaffolding conservé.

### I6 — `AGENTS.md` serveur périmé
- **Constat.** Le fichier décrit un serveur « OAuth-only », « sans fonctionnalités IA », « Pas de rate limiting (prévu v0.2) », « User(id, email, provider, is_active, created_at) ». Les quatre sont contredits par le code (proxy coach, rate limiter actif, profil enrichi).
- **Résolution (Claude, auto).** Réécrire l'`AGENTS.md` serveur pour refléter l'état réel (proxy IA, rate limiting, profil enrichi), **sans toucher aux règles de sécurité non négociables** qui, elles, restent valides.
- **Impact.** Tâche documentaire (hors item produit) — à réaliser lors du nettoyage du repo serveur. Voir aussi la note dans [vue-serveur.md](vue-serveur.md).

---

## Écarts tranchés par défaut (le code fait foi) — récap
- Statuts alignés sur le code, pas sur les backlogs (I1, I3, I5).
- Docs serveur (`AGENTS.md`, `Backlog v0.1.md`) reconnues périmées et à corriger (I3, I6).

## Décisions qui engageaient l'architecture — récap
- **I2 (coach connecté uniquement)** — tranché par l'utilisateur, impacte sécurité + suppression de code client.
- **I4 (Facebook app)** — tranché par l'utilisateur (basse priorité).

## Points encore ouverts (à confirmer plus tard, non bloquants)
- **NT-042** : l'**édition** du profil dans l'app (choix du niveau d'expérience, pseudo custom) est-elle présente ? (affichage confirmé). → statut À VÉRIFIER sur ce sous-périmètre.
- **NT-072** : le **script de vérification de cohérence de schéma** (part de l'ancien P5) reste à faire — le runner, lui, est FAIT.
