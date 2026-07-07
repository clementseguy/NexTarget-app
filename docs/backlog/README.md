# Backlog NexTarget — Gouvernance

Ce dossier contient la **source de vérité produit** de NexTarget (app + serveur)
et ses vues dérivées. Il pilote le développement, y compris depuis Claude Code.

## Vision produit

> NexTarget est le carnet de tir sportif numérique du tireur solo : il enregistre
> chaque session (armes, calibres, séries, groupements), en dégage des
> statistiques et des objectifs mesurables, et s'appuie sur un coach IA pour
> transformer ces données en conseils et exercices concrets — le tout utilisable
> hors-ligne, avec un compte optionnel qui sécurise les appels IA côté serveur.

## Fichiers

| Fichier | Rôle |
|---|---|
| [`backlog-unifie.md`](backlog-unifie.md) | **LA source de vérité.** Tous les items produit (NT-XXX), groupés par thème. |
| [`vue-app.md`](vue-app.md) | Projection des items de portée `app`/`both`. |
| [`vue-serveur.md`](vue-serveur.md) | Projection des items de portée `server`/`both`. À copier dans le repo serveur. |
| [`incoherences.md`](incoherences.md) | Journal des écarts backlogs ⇄ code et des décisions. |

## Règle de synchronisation (impérative)

1. **`backlog-unifie.md` est la seule source de vérité.** Aucune information
   produit ne doit exister *uniquement* dans une vue.
2. **Les vues sont des projections.** Chaque item unifié se projette en **0 ou 1**
   sous-item app **et** **0 ou 1** sous-item serveur, reliés par l'**ID unifié**.
3. **Sens de mise à jour** : on modifie **toujours** le backlog unifié d'abord,
   puis on répercute dans la ou les vues concernées. Jamais l'inverse.
4. **Cohérence des statuts** : un même ID a le **même statut global** partout ; une
   vue peut préciser un statut *par côté* en note (ex. NT-044 : serveur FAIT / app
   À FAIRE) mais ne le contredit pas.
5. **IDs stables, jamais réutilisés.** Un item abandonné passe en `Won't-now` ou est
   marqué obsolète — son ID n'est pas recyclé. Les trous de numérotation par thème
   sont volontaires (réservés à l'insertion).

## Format d'un item

```
- ID            : NT-XXX (stable)
- Titre
- Thème / Epic
- Description   : la valeur pour l'utilisateur (le « pourquoi »)
- Portée        : app | server | both
- Dépendances   : IDs d'autres items
- Critères d'acceptation : liste vérifiable
- Priorité      : Must | Should | Could | Won't-now (MoSCoW)
- Estimation    : S | M | L
- Statut        : FAIT | EN COURS | À FAIRE | À VÉRIFIER
- Notes         : décisions, risques, liens
```

**Règle de statut** : le statut reflète l'**état réel du code**, jamais l'intention.
En cas d'ambiguïté → `À VÉRIFIER` (ne pas inventer un statut).

## Thèmes / Epics

1. Carnet de tir · 2. Statistiques & Objectifs · 3. Exercices · 4. Coach IA ·
5. Auth & Compte · 6. Qualité & Observabilité · 7. Sécurité & Secrets ·
8. Plateforme & Déploiement · 9. Idées / hors-scope.

## Convention d'usage dans Claude Code

Référencer l'**ID d'item** partout pour tracer le travail au produit :

- **Branches** : `type/NT-XXX-slug-court`
  (ex. `feat/NT-061-coach-connecte-uniquement`, `fix/NT-065-cors-prod`).
- **Commits** : préfixer le sujet par l'ID —
  `feat(coach): NT-032 ajout persona coach cool`.
- **PRs** : titre `[NT-XXX] …` ; corps qui **liste les IDs traités** et coche les
  critères d'acceptation correspondants ; à la fusion, **mettre à jour le statut**
  de l'item dans `backlog-unifie.md` (et la/les vue(s)).
- **Multi-repo** : un item `both` (ex. NT-030, NT-061) peut donner une PR par repo ;
  les deux référencent le **même ID**.

## Definition of Done (DoD)

Un item passe **FAIT** quand **tous** les points ci-dessous sont vrais :

1. **Critères d'acceptation** de l'item tous vérifiés.
2. **Code mergé** sur la branche par défaut du/des repo(s) concerné(s).
3. **Tests** : au moins un test couvrant le cas nominal + un cas d'erreur pour toute
   nouvelle logique (serveur : `pytest` ; app : `flutter test`).
4. **Qualité** : app → Quality Gate SonarCloud OK ; serveur → `pytest -q` vert.
5. **Cahier de recette** (app) rejoué/mis à jour si le comportement visible change.
6. **Docs à jour** : `backlog-unifie.md` (statut) + vue(s) + CHANGELOG du repo ;
   `AGENTS.md` si une convention/architecture change.
7. **Sécurité** : aucune régression sur les règles non négociables du serveur
   (OAuth-only côté auth, state à usage unique, type de token JWT, secrets en env,
   pas d'info interne dans les erreurs).

## Cohérence avec les `AGENTS.md`

- **App** — `NexTarget-app/AGENTS.md` est **vide** aujourd'hui. À initialiser ; il
  doit référencer ce dossier comme source de vérité et rappeler la convention d'IDs
  (branches/commits/PRs) et la DoD ci-dessus.
- **Serveur** — `NexTarget-server/AGENTS.md` est **périmé** (décrit un serveur
  « OAuth-only sans IA, sans rate limiting, User minimal »). À réécrire pour refléter
  le code (proxy IA, rate limiting, profil enrichi) **sans** modifier les règles de
  sécurité non négociables, qui restent valides. Suivi : [incoherences.md](incoherences.md) I6.
- En cas de conflit entre un `AGENTS.md` et ce backlog sur le **quoi/pourquoi
  produit**, **ce backlog prime** ; les `AGENTS.md` restent la référence sur le
  **comment** (conventions de code, architecture, sécurité).

## Provenance & archivage

Ce backlog unifie et remplace deux backlogs qui avaient divergé :
- `NexTarget-app/docs/specs/backlog.md`
- `NexTarget-server/docs/specs/Backlog v0.1.md`

**Proposition** (à exécuter après validation, non fait automatiquement) :
- **Archiver** (ne pas supprimer) les anciens backlogs sous `docs/specs/_archive/`
  dans chaque repo, avec un en-tête « Obsolète — voir docs/backlog/ ».
- **Copier** `vue-serveur.md` dans le repo serveur (ex. `docs/specs/vue-serveur.md`)
  et y laisser un pointeur vers le backlog unifié (le serveur ne maintient plus de
  backlog propre).

*Dernier audit du code : 2026-07-07.*
