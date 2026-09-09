# NexTarget — Backlog unifié

> **Prochain ID disponible : NT-159**

Ce fichier inventorie les US actives de l'application et du serveur. Il est
l'unique source de vérité pour leur statut. Les descriptions sont dans
[`descriptions.md`](descriptions.md) et l'ordre de traitement dans
[`priorites.md`](priorites.md).

- **Statuts** : `À FAIRE`, `EN COURS`, `FAIT`, `ANNULÉ`.
- **MoSCoW** et **estimation** sont facultatifs ; `—` signifie « non évalué ».
- Une US absente de `priorites.md` est simplement non priorisée.
- Les US livrées ou annulées sont déplacées périodiquement dans [`archive/`](archive/).

## Thème 1 — Carnet de tir (Sessions & Séries)

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-006](descriptions.md#NT-006) | Analyse d'image de la cible (dispersion/score) | both | À FAIRE | Won't-now | L | — |

## Thème 2 — Statistiques & Objectifs

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-015](descriptions.md#NT-015) | Recommandations croisées Objectifs ⇄ Exercices | app | À FAIRE | Could | M | — |
| [NT-016](descriptions.md#NT-016) | Objectifs enrichis : statuts étendus, journal, vue détail | app | À FAIRE | Could | M | — |

## Thème 3 — Exercices

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-024](descriptions.md#NT-024) | Stats d'exécution (fenêtres glissantes) | app | À FAIRE | Could | M | — |

## Thème 4 — Coach IA

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-034](descriptions.md#NT-034) | Affiner les prompts des personas coach | server | À FAIRE | Could | S | — |

## Thème 5 — Auth & Compte

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-044](descriptions.md#NT-044) | Authentification OAuth Facebook | both | À FAIRE | Could | M | — |
| [NT-045](descriptions.md#NT-045) | Stats publiques / partage de profil | both | À FAIRE | Won't-now | M | — |
| [NT-046](descriptions.md#NT-046) | Gamification | both | À FAIRE | Won't-now | L | — |
| [NT-047](descriptions.md#NT-047) | Apple Sign In | both | À FAIRE | Won't-now | M | — |

## Thème 8 — Plateforme & Déploiement

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-074](descriptions.md#NT-074) | Saisie séries plein écran + navigation rapide | app | À FAIRE | Could | M | — |
| [NT-076](descriptions.md#NT-076) | Cache stats + compactage Hive | app | À FAIRE | Could | M | — |

## Thème 9 — Idées / hors-scope

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-090](descriptions.md#NT-090) | Thème ASCII Art | app | À FAIRE | Won't-now | M | — |
| [NT-091](descriptions.md#NT-091) | Revoir les règles de sécurité FFTir | app | À FAIRE | Won't-now | S | — |

## Thème 10 — Disciplines officielles & TAR

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-100](descriptions.md#NT-100) | Référentiel des disciplines officielles (TAR 25 m) | app | À FAIRE | Must | M | — |
| [NT-101](descriptions.md#NT-101) | Sessions & séries typées discipline | app | À FAIRE | Must | M | — |
| [NT-102](descriptions.md#NT-102) | Mode « match blanc » TAR | app | À FAIRE | Should | L | — |
| [NT-103](descriptions.md#NT-103) | Comparaison aux grilles de classement FFTir | app | À FAIRE | Could | M | — |
| [NT-104](descriptions.md#NT-104) | Stats & records par discipline | app | À FAIRE | Should | M | — |

## Thème 11 — Analyse de cible (photo)

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-110](descriptions.md#NT-110) | Métadonnées cible & photo par série | app | À FAIRE | Should | S | — |
| [NT-111](descriptions.md#NT-111) | Analyse qualitative de la photo par le coach (multimodal) | both | À FAIRE | Should | M | — |

## Thème 12 — Coach : progression & génération

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-120](descriptions.md#NT-120) | Payload d'analyse transverse compact | app | ANNULÉ | Won't-now | M | NT-121, NT-153, NT-156 |
| [NT-121](descriptions.md#NT-121) | MVP Coach de progression transverse | both | À FAIRE | Should | L | — |
| [NT-122](descriptions.md#NT-122) | Sortie coach structurée (JSON schema) | server | À FAIRE | Must (socle) | M | — |
| [NT-123](descriptions.md#NT-123) | Coach de progression : sélectionner un exercice | both | À FAIRE | Should | L | — |
| [NT-124](descriptions.md#NT-124) | Coach de progression : proposer un objectif | both | À FAIRE | Should | M | — |
| [NT-125](descriptions.md#NT-125) | Suivi des prescriptions et tentatives | both | À FAIRE | Could | L | — |
| [NT-126](descriptions.md#NT-126) | Plan d'entraînement | both | À FAIRE | Could | L | — |

## Thème 13 — Saisie au stand

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-130](descriptions.md#NT-130) | Templates de session | app | À FAIRE | Must | S | — |
| [NT-132](descriptions.md#NT-132) | Spike — saisie vocale d'une série | app | À FAIRE | Could | S | — |
| [NT-134](descriptions.md#NT-134) | Graphiques d'évolution intra-session | app | À FAIRE | Could | M | — |

## Thème 14 — Finitions UX

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-151](descriptions.md#NT-151) | Harmoniser et densifier les cartes d'exercice | app | À FAIRE | Could | M | — |

## Thème 15 — Socle Coach transverse

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-152](descriptions.md#NT-152) | Limiter une session à un exercice principal | both | À FAIRE | Must | M | — |
| [NT-153](descriptions.md#NT-153) | Consentement à l'utilisation des coachs | both | À FAIRE | Must | S | — |
| [NT-154](descriptions.md#NT-154) | Qualifier l'exercice lors de la réalisation d'une session prévue | both | À FAIRE | Must | M | — |
| [NT-155](descriptions.md#NT-155) | Déplacer le niveau d'expérience dans les préférences Coach | app | À FAIRE | Must | S | — |
| [NT-156](descriptions.md#NT-156) | Recentrer le Coach de session sur le débrief | both | À FAIRE | Must | L | — |
| [NT-157](descriptions.md#NT-157) | Séparer décision et ton du Coach de session | server | À FAIRE | Must | M | — |
| [NT-158](descriptions.md#NT-158) | Supprimer les données transmises aux coachs | both | À FAIRE | Won't-now | — | — |
