# NexTarget — Plan de priorisation & sprints

> Vue de pilotage dérivée du [`backlog-unifie.md`](backlog-unifie.md), établie le
> 2026-07-13. Le backlog unifié reste la source de vérité produit ; ce document
> ordonne les items non livrés par valeur métier, dépendances et capacité à
> produire une version stable en fin de sprint.

> ✅ **Livrés depuis l'établissement de ce plan** : **NT-005** (photo de la cible)
> et **NT-007** (filtre historique par exercice) ont été implémentés et fusionnés
> dans `main` le 2026-07-17 (PR #12). Ils restent listés ci-dessous marqués `✅`
> pour préserver la lisibilité des dépendances (ex. NT-111 dépend de NT-005) ;
> ils ne sont plus à replanifier.

## Hypothèses

- Sprints de 2 semaines.
- Un sprint doit livrer une version utilisable en production, sans feature
  incomplète exposée.
- Les développements peuvent être parallélisés entre app Flutter et serveur
  FastAPI quand les contrats sont clairs.
- Les items `FAIT` ne sont pas replanifiés. Les items `Won't-now` restent en
  Icebox, sauf décision produit contraire.
- Le vieux plan S1-S6 dans le backlog unifié est considéré comme historique :
  plusieurs items y sont déjà livrés et les thèmes 10-13 ajoutés le 2026-07-13
  n'y sont pas encore ventilés.

## Méthode de tri

1. **Valeur métier** : priorité aux items qui rendent NexTarget plus utile pour
   progresser en discipline officielle, surtout TAR 25 m.
2. **Dépendances** : les socles structurants passent avant les écrans avancés
   qui les consomment.
3. **Stabilité livrable** : chaque sprint regroupe des features qui forment une
   version cohérente, testable et exploitable.
4. **Risque technique** : les migrations Hive, contrats coach structurés et
   endpoints serveur sont isolés dans des sprints où la recette peut absorber le
   risque.

## Backlog ordonné

| Rang | Items | Pourquoi maintenant | Dépendances clés | Portée |
|---|---|---|---|---|
| 1 | NT-100, NT-101 | Socle métier TAR : rend les sessions comparables et exploitables par stats/coach. | NT-001, NT-002 | app |
| 2 | NT-073, NT-130 | Réduit fortement la friction de saisie au stand ; prépare les templates par épreuve. | NT-001, NT-101 optionnel | app |
| 3 | NT-005 ✅, NT-110 | Photo cible exploitable : mémoire visuelle puis contexte fiable pour le coach. | NT-001, NT-100 | app |
| 4 | NT-104 | Restitution immédiate de la progression par discipline. | NT-100, NT-010 | app |
| 5 | NT-120, NT-121 | Donne un vrai écran Coach transverse, à forte valeur métier. | NT-101, NT-010, NT-030 | both |
| 6 | NT-122 | Socle serveur pour que le coach produise des entités validables. | NT-031 | server |
| 7 | NT-123, NT-124 | Le coach devient actionnable : exercices et objectifs proposés, validés par le tireur. | NT-122, NT-020, NT-012 | both |
| 8 | NT-102, NT-131, NT-074 | Usage terrain avancé : match blanc, session live, saisie rapide. | NT-101, NT-130, NT-002 | app |
| 9 | NT-111 | Analyse qualitative photo par IA, utile mais seulement après photos taguées et référentiel. | NT-005, NT-110, NT-100, NT-030 | both |
| 10 | NT-125, NT-126 | Boucle longue : suivi des recommandations puis plan d'entraînement. | NT-121, NT-123, NT-124 | both |
| 11 | NT-024, NT-015, NT-014, NT-016 | Raffinement stats/objectifs/exercices après les axes TAR et coach. | NT-022, NT-021, NT-010, NT-012 | app |
| 12 | NT-056, NT-057, NT-076 | Dette qualité/performance app, à caler dans un sprint de stabilisation. | — | app |
| 13 | NT-034, NT-025, NT-026, NT-007 ✅ | Améliorations utiles mais non structurantes ; NT-026 est de faible priorité mais reste planifié. | NT-032, NT-020, NT-022 | app/server |
| 14 | NT-044, NT-103, NT-132 | Opportunistes ou à instruire : Facebook, grilles FFTir, spike vocal. | sourcing/config terrain | both/app |
| Infra | NT-071 | À déclencher avant multi-instance ou montée de charge serveur, pas bloquant pour le cycle fonctionnel court. | — | server |

## Plan par sprint

### Sprint 1 — Socle TAR & saisie rapide

**Objectif livrable** : l'utilisateur peut créer des sessions typées discipline
TAR, avec calibres normalisés et création rapide depuis un setup favori.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-100 | Référentiel TAR 25 m versionné | seed YAML, services de lecture | — |
| 2 | NT-101 | Sessions et séries typées discipline | migrations Hive, formulaires, scoring essai/précision/vitesse/gongs | — |
| 3 | NT-073 | Normalisation calibres + dernier calibre | référentiel calibres, pré-remplissage | — |
| 4 | NT-130 | Templates de session | dernier setup, favoris, création en 2 taps | — |

**Version stable attendue** : aucun écran coach nouveau ; focus carnet. Les
sessions existantes restent lisibles après migration.

### Sprint 2 — Restitution TAR & photo cible

**Objectif livrable** : le tireur voit ses stats par discipline et peut conserver
des photos de cible correctement contextualisées.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-104 | Stats & records par discipline | filtres, records par épreuve, dashboard distinct | — |
| 2 | NT-005 ✅ | Photo de cible sur session (livré PR #12) | prise/sélection, stockage local, détail session | — |
| 3 | NT-110 | Métadonnées cible & photo par série | cible/distance/série associée | — |

**Version stable attendue** : photos seulement locales et taguées ; aucune
analyse IA photo encore exposée.

### Sprint 3 — Coach progression v1

**Objectif livrable** : remplacer le placeholder Coach par une analyse transverse
réelle, bornée en taille et exploitable par discipline.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-120 | Payload d'analyse transverse compact | agrégats locaux, N dernières sessions, fenêtre 90 j | contrat d'entrée validé |
| 2 | NT-121 | Écran Coach : analyse de progression | écran Coach, états loading/error, rendu analyse | endpoint analyse progression, prompt serveur |
| 3 | NT-034 | Affinage prompts personas | recette app des tons | prompts neutre/cool ajustés |

**Version stable attendue** : le coach conseille sur la progression, sans créer
automatiquement d'exercices ni d'objectifs.

### Sprint 4 — Coach actionnable

**Objectif livrable** : le coach propose des entités structurées, mais le tireur
garde toujours la main avant création.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-122 | Sortie coach structurée | alignement modèles Exercise/Goal | JSON schema versionné, validation, fallback |
| 2 | NT-123 | Coach propose des exercices | prévisualisation, édition, déduplication, insertion catalogue | génération structurée exercice |
| 3 | NT-124 | Coach propose des objectifs | prévisualisation, édition, lien exercices | génération structurée objectif |

**Version stable attendue** : aucune création sans validation explicite ; les
sorties invalides retombent proprement en analyse texte.

### Sprint 5 — Usage stand avancé

**Objectif livrable** : l'app devient utilisable pendant l'entraînement, pas
seulement après la séance.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-102 | Mode match blanc TAR | déroulé guidé 830/831/832, chronos, score /200 | — |
| 2 | NT-131 | Session live au stand | statut en cours, saisie série par série, chrono repos | — |
| 3 | NT-074 | Saisie séries plein écran | navigation rapide, numpad/swipe | — |

**Version stable attendue** : les sessions live se clôturent en sessions standard
et restent compatibles avec stats, historique et coach.

### Sprint 6 — Analyse photo qualitative

**Objectif livrable** : le coach enrichit son diagnostic avec la photo de cible,
sans prétendre remplacer la saisie manuelle.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-111 | Analyse qualitative photo par coach multimodal | envoi photo taguée, rendu analyse, cas photo inexploitable | endpoint multimodal JWT, rate limit, prompt cible |
| 2 | NT-056 | Harmonisation erreurs réseau | messages homogènes auth/profil/coach/photo | contrats d'erreur stables |

**Version stable attendue** : analyse qualitative seulement ; NT-006 reste en
Icebox tant que l'extraction métrique n'a pas prouvé sa valeur.

### Sprint 7 — Boucle de progression

**Objectif livrable** : les recommandations du coach deviennent suivables et
mesurables dans le temps.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-125 | Suivi des recommandations | statut suivie/non suivie, consultation | réinjection dans contexte coach |
| 2 | NT-024 | Stats d'exécution exercices | usageCount, lastPerformedAt, fenêtres glissantes | — |
| 3 | NT-015 | Recos Objectifs ⇄ Exercices | suggestions locales selon objectifs en retard | — |
| 4 | NT-026 | Suppression d'un exercice | action UI avec confirmation ; sessions conservées ; retour sûr du filtre NT-007 à « Tous les exercices » | — |

**Version stable attendue** : le coach voit si ses conseils ont été appliqués,
mais aucun plan multi-semaines automatique.

### Sprint 8 — Plan d'entraînement & stats fines

**Objectif livrable** : générer un plan 2-4 semaines validé par le tireur, puis
compléter les raffinements statistiques.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-126 | Plan d'entraînement | prévisualisation, validation, création sessions/exercices/objectifs | génération plan structurée |
| 2 | NT-014 | Comparatif 30 j vs 60 j + sparkline | dashboard enrichi | — |
| 3 | NT-016 | Objectifs enrichis | statuts étendus, journal, vue détail, migration | — |

**Version stable attendue** : le plan est optionnel, validé avant création et
réversible par suppression des entités créées.

## Sprints de stabilisation ou opportunistes

| Déclencheur | Items | Recommandation |
|---|---|---|
| Avant ouverture publique plus large ou multi-instance Render | NT-071 | Migrer SQLite vers Postgres + Alembic avant de dépendre d'un rate-limit/state partagé. |
| Dette UI ou baisse de maintenabilité | NT-057, NT-076 | Planifier un sprint court de nettoyage/performance sans nouvelle feature métier. |
| Besoin login social autre que Google | NT-044 | Valider le flow Facebook contre une vraie app Facebook puis câbler le bouton app. |
| Besoin classement officiel fédéral | NT-103 | Sourcer les grilles RGS FFTir avant estimation définitive. |
| Hypothèse de saisie mains libres au stand | NT-132 | Spike timeboxé uniquement, avec go/no-go en conditions réelles. |
| Besoin de confort catalogue exercices | NT-025, NT-026, ~~NT-007~~ ✅ | NT-007 livré (PR #12) ; NT-026 est planifié à faible priorité en Sprint 7, avec recette des références de sessions orphelines. |

## Icebox

| Item | Raison |
|---|---|
| NT-006 | Analyse métrique CV coûteuse ; NT-111 doit d'abord valider la valeur de l'analyse photo. |
| NT-045 | Partage public sans demande métier actuelle. |
| NT-046 | Gamification large, risque de dispersion. |
| NT-047 | Apple Sign In à reconsidérer seulement avec stratégie iOS/App Store et logins sociaux. |
| NT-090 | Cosmétique. |
| NT-091 | À réouvrir seulement avec besoin réglementaire clair. |

## Points de cohérence à corriger

- `vue-serveur.md` indique encore NT-032 à faire alors que le backlog unifié le
  marque `FAIT`. La projection serveur doit être resynchronisée.
- Les "Prochaines actions serveur" de `vue-serveur.md` listent plusieurs items
  déjà `FAIT` dans le backlog unifié (`NT-048`, `NT-053`, `NT-054`, `NT-055`).
- Le bloc "Backlog priorisé" du backlog unifié est historique et mélange items
  livrés, anciens sprints et nouveaux thèmes. Il devrait être remplacé par un
  lien vers ce plan ou régénéré depuis celui-ci après validation produit.
