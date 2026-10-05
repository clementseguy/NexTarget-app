# NexTarget — Backlog unifié

> **Prochain ID disponible : NT-177**

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
| [NT-170](descriptions.md#NT-170) | Sauvegarder les données de sessions dans le cloud | both | À FAIRE | — | — | — |

## Thème 2 — Statistiques & Objectifs

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-015](descriptions.md#NT-015) | Recommandations croisées Objectifs ⇄ Exercices | app | À FAIRE | Could | M | — |
| [NT-016](descriptions.md#NT-016) | Objectifs enrichis : statuts étendus, journal, vue détail | app | À FAIRE | Could | M | — |
| [NT-165](descriptions.md#NT-165) | Refondre les Objectifs pour le coaching de progression | both | À FAIRE | Must (socle) | L | — |
| [NT-166](descriptions.md#NT-166) | Afficher la synthèse des indicateurs d'une session | app | À FAIRE | Could | M | — |

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
| [NT-172](descriptions.md#NT-172) | Ne plus forcer le consentement Google à chaque connexion | server | À FAIRE | — | — | — |

## Thème 8 — Plateforme & Déploiement

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-074](descriptions.md#NT-074) | Saisie séries plein écran + navigation rapide | app | À FAIRE | Could | M | — |
| [NT-076](descriptions.md#NT-076) | Cache stats + compactage Hive | app | À FAIRE | Could | M | — |
| [NT-173](descriptions.md#NT-173) | Réveiller le serveur Render aux moments utiles | app | À FAIRE | — | — | — |

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
| [NT-152](descriptions.md#NT-152) | Limiter une session à un exercice principal | both | FAIT | Must | M | — |
| [NT-153](descriptions.md#NT-153) | Consentement à l'utilisation des coachs | app | FAIT | Must | S | — |
| [NT-154](descriptions.md#NT-154) | Qualifier l'exercice lors de la réalisation d'une session prévue | app | FAIT | Must | M | — |
| [NT-155](descriptions.md#NT-155) | Déplacer le niveau d'expérience dans les préférences Coach | app | FAIT | Must | M | — |
| [NT-156](descriptions.md#NT-156) | Recentrer le Coach de session sur le débrief | both | FAIT | Must | L | — |
| [NT-157](descriptions.md#NT-157) | Séparer décision et ton du Coach de session | server | À FAIRE | Must | M | — |
| [NT-158](descriptions.md#NT-158) | Supprimer les données transmises aux coachs | both | À FAIRE | Won't-now | — | — |
| [NT-159](descriptions.md#NT-159) | Créer le modèle Exercise partagé et sa provenance | both | FAIT | Must | M | — |
| [NT-160](descriptions.md#NT-160) | Récupérer à la demande les exercices du catalogue Coach | both | FAIT | Must | M | — |
| [NT-161](descriptions.md#NT-161) | Analyser un exercice personnel sans le cataloguer | both | FAIT | Must | M | — |
| [NT-162](descriptions.md#NT-162) | Auditer et enrichir le modèle métier Exercise | both | À FAIRE | Should | L | — |
| [NT-163](descriptions.md#NT-163) | Déterminer la réussite et la suite du Coach de session | both | À FAIRE | Must | L | — |
| [NT-164](descriptions.md#NT-164) | Gérer l'attente du Coach de progression | app | À FAIRE | Should | S | — |

## Thème 16 — Produit, qualité & exploitation

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-167](descriptions.md#NT-167) | Internationaliser l'app et les Coachs en anglais | both | À FAIRE | — | — | — |
| [NT-168](descriptions.md#NT-168) | Faire exécuter la recette de l'app par un agent | app | À FAIRE | — | — | — |
| [NT-169](descriptions.md#NT-169) | Réaliser une revue générale qualité et sécurité | both | À FAIRE | — | — | — |
| [NT-171](descriptions.md#NT-171) | Cadrer les offres gratuite, payante et premium | both | À FAIRE | — | — | — |

## Thème 17 — Chronométrer les tirs

| ID | Titre | Portée | Statut | MoSCoW | Est. | Remplacée par |
|---|---|---|---|---|---|---|
| [NT-174](descriptions.md#NT-174) | Qualifier la détection des tirs avec la Garmin vívoactive HR | app | À FAIRE | Must (POC) | S | — |
| [NT-175](descriptions.md#NT-175) | Détecter et transmettre automatiquement une série de 5 tirs | app | À FAIRE | Must (POC) | M | — |
| [NT-176](descriptions.md#NT-176) | Ajouter la page prototype Garmin dans NexTarget | app | À FAIRE | Must (POC) | M | — |
