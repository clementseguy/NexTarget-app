# NexTarget — Plan de priorisation & sprints

> Vue de pilotage dérivée du [`backlog-unifie.md`](backlog-unifie.md), établie le
> 2026-07-13. Le backlog unifié reste la source de vérité produit ; ce document
> ordonne les items non livrés par valeur métier, dépendances et capacité à
> produire une version stable en fin de sprint.

> **Livrés depuis l'établissement de ce plan** : **NT-005** (photo de la cible)
> et **NT-007** (filtre historique par exercice) ont été implémentés et fusionnés
> dans `main` le 2026-07-17 (PR #12). Ils restent listés ci-dessous avec le statut `FAIT`
> pour préserver la lisibilité des dépendances (ex. NT-111 dépend de NT-005) ;
> ils ne sont plus à replanifier.

> **Lot serveur livré** : **NT-049** est implémenté sous la forme de la page
> d'administration read-only `GET /app/admin/users`. Il reste listé ci-dessous
> avec le statut `FAIT` pour conserver l'historique de la priorisation.

> **Prototype abandonné le 2026-07-24** : la branche regroupant NT-100,
> NT-101, NT-073 et NT-130 a été fermée sans fusion après échec de la recette UX.
> NT-100, NT-101 et NT-130 restent **À FAIRE** ; NT-073 a depuis été repris et
> livré (**FAIT**). Toute reprise du périmètre TAR/templates part de `dev` et
> commence
> par la validation des parcours du
> [REX TAR & saisie rapide](rex-tar-saisie-rapide-2026-07-24.md) ; aucun
> cherry-pick global du prototype `117ca83`.

> **Infrastructure livrée le 2026-09-02** : NT-071 est **FAIT** et livré dans
> la release produit v0.6.0 (composant serveur v0.3.0). La production utilise
> PostgreSQL Neon avec Alembic à la place du SQLite éphémère de Render.

> **Enrichissement app du 2026-09-02** : NT-133 ajoute les sessions libres et
> introduit le socle polymorphe commun aux sessions détaillées et simplifiées.
> Il a été fusionné sur `dev` le 2026-09-03 (PR #27).
>
> **Comparatif livré le 2026-09-03** : NT-014 est fusionné sur `dev` (PR #28).

> **Arbitrage produit du 2026-09-02**, complété le **2026-09-04** : le lot
> prioritaire regroupe NT-014, NT-048, NT-061, NT-073, NT-133 et NT-131. Il est
> découpé en trois incréments livrables, tous fusionnés sur `dev` et préparés
> pour la release v0.7.0.

> **Cadrage produit du 2026-09-04** : NT-131 ne dépend plus des templates
> NT-130. Il porte le parcours direct « au stand », de la préparation courte au
> brouillon reprenable puis à la session réalisée. Il a été fusionné sur `dev`
> par la PR #31. NT-134 réserve les graphiques
> score/groupement intra-session comme évolution facultative ultérieure.

> **Planification du 2026-09-05** : le prochain lot app regroupe **NT-059,
> NT-077, NT-056, NT-057, NT-025 et NT-144**, dans cet ordre recommandé. Il
> stabilise d'abord la qualité et la persistance, harmonise ensuite les erreurs
> réseau et la dette UI, puis livre l'évolution mineure des exercices et clôt
> la synchronisation documentaire. Les six items peuvent être développés sur
> une branche unique avec des commits séparés ; aucun changement serveur n'est
> attendu.

## Hypothèses

- Sprints de 2 semaines.
- Un sprint doit livrer une version utilisable en production, sans feature
  incomplète exposée.
- Les développements peuvent être parallélisés entre app Flutter et serveur
  FastAPI quand les contrats sont clairs.
- Les items `FAIT` ne sont pas replanifiés, sauf vérification documentaire de
  clôture explicitement identifiée comme NT-061. Les items `Won't-now` restent
  en Icebox, sauf décision produit contraire.
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
| 0 | NT-071 (FAIT) | Corrige la perte des comptes et refresh tokens à chaque veille/redémarrage Render ; livré avec la release produit v0.6.0 (serveur v0.3.0). | NT-070 | server |
| 0 | NT-049 (FAIT) | Diagnostic immédiat et sécurisé de la base utilisateurs et du comportement OAuth ; lot serveur autonome livré. | NT-040, NT-042 | server |
| 0 | NT-014, NT-048, NT-061, NT-073, NT-133 (FAIT) | Lot de finalisation livré sur `dev`. | NT-001, NT-003, NT-005, NT-010, NT-017, NT-022, NT-040 | both |
| 0 | NT-131 (FAIT) | Session guidée directement au stand sur le socle livré par NT-133 ; fusionnée sur `dev` par la PR #31. | NT-001, NT-002, NT-003, NT-004, NT-009, NT-022, NT-073, NT-133 | app |
| 1 | NT-059, NT-077, NT-056, NT-057, NT-025, NT-144 | Lot immédiat de stabilisation, qualité, évolution mineure des exercices et hygiène documentaire. | NT-020, NT-027, NT-040, NT-048, NT-051, NT-061, NT-072 | app |
| 2 | NT-100, NT-101 | Socle métier TAR : rend les sessions comparables et exploitables par stats/coach. | NT-001, NT-002 | app |
| 3 | NT-130 | Réduit fortement la friction de saisie au stand et prépare les templates par épreuve après stabilisation de NT-073/NT-133. | NT-001, NT-073, NT-101 optionnel, NT-133 | app |
| 4 | NT-005 (FAIT), NT-110 | Photo cible exploitable : mémoire visuelle puis contexte fiable pour le coach. | NT-001, NT-100 | app |
| 5 | NT-104 | Restitution immédiate de la progression par discipline. | NT-100, NT-010 | app |
| 6 | NT-120, NT-121 | Donne un vrai écran Coach transverse, à forte valeur métier. | NT-101, NT-010, NT-030 | both |
| 7 | NT-122 | Socle serveur pour que le coach produise des entités validables. | NT-031 | server |
| 8 | NT-123, NT-124 | Le coach devient actionnable : exercices et objectifs proposés, validés par le tireur. | NT-122, NT-020, NT-012 | both |
| 9 | NT-102, NT-074 | Usage terrain avancé restant après livraison prioritaire de NT-131 : match blanc et optimisations génériques de saisie. | NT-101, NT-002 | app |
| 10 | NT-134 | Lecture graphique score/groupement au fil d'une séance, après validation du récapitulatif NT-131. | NT-131, NT-011 | app |
| 11 | NT-111 | Analyse qualitative photo par IA, utile mais seulement après photos taguées et référentiel. | NT-005, NT-110, NT-100, NT-030 | both |
| 12 | NT-125, NT-126 | Boucle longue : suivi des recommandations puis plan d'entraînement. | NT-121, NT-123, NT-124 | both |
| 13 | NT-024, NT-015, NT-016 | Raffinement stats/objectifs/exercices après les axes TAR et coach. | NT-022, NT-021, NT-010, NT-012 | app |
| 14 | NT-076 | Dette de performance app restant à caler après le lot immédiat. | NT-010 | app |
| 15 | NT-034, NT-026, NT-007 (FAIT) | Améliorations utiles mais non structurantes ; NT-026 est de faible priorité mais reste planifié. | NT-032, NT-020, NT-022 | app/server |
| 16 | NT-044, NT-103, NT-132 | Opportunistes ou à instruire : Facebook, grilles FFTir, spike vocal. | sourcing/config terrain | both/app |

## Plan par sprint

### Lot immédiat — Stabilisation technique et évolutions mineures

**Objectif livrable** : repartir d'une base analysable sans tests masqués,
sécuriser les futures évolutions Hive, homogénéiser la reprise après erreur
réseau, réduire une dette UI démontrée, enrichir le catalogue d'exercices et
terminer avec des documents de pilotage cohérents. Le lot concerne uniquement
l'application Flutter et sa documentation.

| Ordre | Item | Livrable principal | Dépendances ou garde-fous |
|---|---|---|---|
| 1 | NT-059 | Résorber les 53 issues SonarCloud de référence et rendre déterministes les trois tests d'export actuellement ignorés ou auto-ignorés. | Conserver les comportements de NT-014, NT-048, NT-131 et NT-133. |
| 2 | NT-077 | Ajouter le registre et le contrôle automatique des migrations, `typeId` et index Hive, exécuté avant commit et en CI. | Complète NT-072 ; contrôle en lecture seule et tests avec cas invalides. |
| 3 | NT-056 | Unifier les erreurs Auth, Profil et Coach avec « Réessayer » ou « Se reconnecter » selon leur nature. | Sauvegardes locales exclues ; préserver jetons et mode local lors des erreurs transitoires. |
| 4 | NT-057 | Supprimer le code UI mort et factoriser uniquement les duplications actives dont le bénéfice est démontré. | Inventaire des usages avant suppression ; aucun changement fonctionnel. |
| 5 | NT-025 | Ajouter la difficulté facultative des exercices, son filtre et sa persistance rétrocompatible. | Migration additive ; reprise par NT-027 ; import/export couverts. |
| 6 | NT-144 | Synchroniser et alléger les documents de backlog après les cinq évolutions précédentes. | Conserver les identifiants et décisions durables ; aucun code produit modifié. |

**Organisation recommandée** : une branche app unique pour le lot, avec un
commit cohérent par item lorsque possible. Les validations ciblées sont jouées
à chaque incrément ; l'analyse, la suite complète et les contrôles documentaires
sont rejoués avant livraison.

**Version stable attendue** : aucune issue Sonar de la référence ni test ignoré,
schéma Hive contrôlé automatiquement, erreurs réseau actionnables sans
déconnexion abusive, aucun changement UX issu du nettoyage, difficulté des
exercices rétrocompatible et documents de pilotage synchronisés.

### Lot prioritaire — Finalisation du socle utilisateur

**Objectif livrable** : terminer les fonctionnalités déjà partielles qui
affectent la lecture des performances, la qualité des calibres et la durée de
connexion, clore la documentation de sécurité, puis permettre une consignation
rapide sans séries et une saisie détaillée guidée directement au stand. Le lot
forme un ensemble produit unique mais se livre en trois incréments afin d'isoler
la migration de sessions puis le nouveau parcours interactif.

#### Incrément A — Finalisations ciblées

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-061 (FAIT) | Clôture Coach connecté uniquement | aligner les documents actifs, confirmer l'absence de clé, prompt, appel direct ou fallback client | conserver le proxy Mistral légitime ; aucune réécriture historique |
| 2 | NT-073 (FAIT) | Calibre par défaut + normalisation statistique | préférence facultative, autocomplétion libre centralisée, alias 9 mm, exclusion des inconnus des seules stats par calibre | — |
| 3 | NT-014 (FAIT) | Comparatif 30 j vs 90 j | score et groupement indépendants, deltas absolus/relatifs, présentation mobile, sparklines à partir de cinq sessions | — |
| 4 | NT-048 (FAIT) | Sessions connectées durables | stockage sécurisé, refresh proactif, single-flight, retry unique, logout avec révocation best effort, mode hors ligne préservé | contrat existant réutilisé sans modification |

**Version stable attendue** : les indicateurs 30/90 sont compréhensibles sur
mobile dans les deux thèmes ; la saisie des calibres reste libre et cohérente ;
une expiration d'access token ne force plus un login ; une panne réseau ne
déconnecte pas l'utilisateur ; la situation NT-061 est documentée sans altérer
l'historique.

#### Incrément B — Session libre

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-133 (FAIT) | Sessions libres sans séries ni scores | modèle polymorphe et migration ; formulaire court ; arme/calibre obligatoires ; catégorie entraînement/match/test matériel ; distance entière ; synthèse/photo/exercices ; cartes, filtres, objectifs, stats, NT-017 et sauvegardes adaptés ; aucun Coach | — |

**Version stable attendue** : une ancienne base et une ancienne sauvegarde restent
lisibles ; le `+` actuel conserve son comportement ; l'action Libre reste
absente de l'onglet Prévues ; les volumes incluent les sessions libres alors que
les métriques de séries les ignorent ; aucune analyse Coach n'est proposée.

#### Incrément C — Session guidée au stand

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-131 (FAIT) | Session guidée au stand | action principale « Au stand », préparation courte, brouillon reprenable, saisie série par série, récapitulatif et clôture vers le détail | — |

**Version stable attendue** : depuis l'écran Sessions, l'utilisateur démarre une
séance détaillée sans session prévue, exercice obligatoire ni template. Le
brouillon survit aux interruptions, reste hors statistiques et Coach, puis se
clôture en session réalisée avant redirection vers son détail.

**État du lot** : les trois incréments sont fusionnés sur `dev`. Le lot complet
est candidat à la release v0.7.0, sous réserve de la Quality Gate, de la recette
manuelle de release et de la MR `dev` vers `main`.

### Lot serveur autonome — Diagnostic OAuth

**Objectif livré** : permettre à l'administrateur de vérifier rapidement et
en lecture seule les utilisateurs réellement inscrits, puis de documenter le
comportement actuel du login Google avant toute correction fonctionnelle.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-049 | Interface d'administration read-only des utilisateurs | — | `GET /app/admin/users`, page HTML sécurisée par secrets d'environnement, consultation sans mutation, protections de réponse, documentation locale/Render et audit Google |

**Version stable livrée** : NT-049 est implémenté et livré seul, sans être
couplé à un autre lot. L'interface ne révèle aucun secret et n'offre aucun chemin
de mutation ; les éventuelles corrections OAuth découvertes sont arbitrées et
planifiées séparément.

### Sprint suivant — Socle TAR & saisie rapide

**Objectif livrable** : l'utilisateur peut consigner une session libre ou créer
des sessions typées discipline TAR, avec calibres normalisés et création rapide
depuis un setup favori.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 0 | Design UX | Parcours détaillé, TAR, dernier réglage/favori et consultation des différents types | wireframes/prototype validés avant code | — |
| 1 | NT-100 | Référentiel TAR 25 m versionné | seed YAML, services de lecture | — |
| 2 | NT-101 | Sessions et séries typées discipline | migrations Hive, formulaires, scoring essai/précision/vitesse/gongs | — |
| 3 | NT-130 | Templates de session | dernier setup, favoris, création en 2 taps | — |

**Version stable attendue** : aucun écran coach nouveau ; focus carnet. Les
sessions existantes restent lisibles après migration. Le parcours classique
n'ajoute aucune étape ; le bouton de session libre n'apparaît pas dans l'onglet
Prévues ; les informations TAR sont explicites en saisie comme en consultation.
Le développement ne commence qu'après validation de l'ordre 0.

### Sprint 2 — Restitution TAR & photo cible

**Objectif livrable** : le tireur voit ses stats par discipline et peut conserver
des photos de cible correctement contextualisées.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-104 | Stats & records par discipline | filtres, records par épreuve, dashboard distinct | — |
| 2 | NT-005 (FAIT) | Photo de cible sur session (livré PR #12) | prise/sélection, stockage local, détail session | — |
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

### Sprint 5 — Usage stand avancé complémentaire

**Objectif livrable** : compléter le parcours au stand déjà livré par NT-131
avec le mode match blanc et les optimisations génériques de saisie.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-102 | Mode match blanc TAR | déroulé guidé 830/831/832, chronos, score /200 | — |
| 2 | NT-074 | Saisie séries plein écran | navigation rapide, numpad/swipe | — |

**Version stable attendue** : les parcours spécialisés et les optimisations de
clavier/navigation complètent NT-131 sans modifier son chemin nominal.

### Évolution ultérieure — Lecture intra-session

**Objectif livrable** : rendre visibles les tendances internes d'une séance sans
alourdir la première version du parcours au stand.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-134 | Graphiques d'évolution intra-session | cadrage UX puis évolution du score et du groupement par série dans le récapitulatif et le détail | — |

**Version stable attendue** : les deux métriques restent lisibles malgré leurs
unités différentes, les états partiels sont gérés et NT-131 reste utilisable
indépendamment de cette visualisation.

### Sprint 6 — Analyse photo qualitative

**Objectif livrable** : le coach enrichit son diagnostic avec la photo de cible,
sans prétendre remplacer la saisie manuelle.

| Ordre | Item | Feature | App | Serveur |
|---|---|---|---|---|
| 1 | NT-111 | Analyse qualitative photo par coach multimodal | envoi photo taguée, rendu analyse, cas photo inexploitable | endpoint multimodal JWT, rate limit, prompt cible |

**Version stable attendue** : analyse qualitative seulement ; NT-006 reste en
Icebox tant que l'extraction métrique n'a pas prouvé sa valeur. Les erreurs de
ce parcours réutilisent le vocabulaire app livré par NT-056 sans replanifier
l'item.

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
| 2 | NT-016 | Objectifs enrichis | statuts étendus, journal, vue détail, migration | — |

**Version stable attendue** : le plan est optionnel, validé avant création et
réversible par suppression des entités créées.

## Sprints de stabilisation ou opportunistes

| Déclencheur | Items | Recommandation |
|---|---|---|
| Lot immédiat décidé le 2026-09-05 | NT-059, NT-077, NT-056, NT-057, NT-025, NT-144 | Livrer dans cet ordre sur une branche app unique ; ne plus traiter ces items comme opportunistes. |
| Baisse de performance avec la volumétrie | NT-076 | Mesurer avant de planifier le cache et le compactage Hive. |
| Besoin login social autre que Google | NT-044 | Valider le flow Facebook contre une vraie app Facebook puis câbler le bouton app. |
| Besoin classement officiel fédéral | NT-103 | Sourcer les grilles RGS FFTir avant estimation définitive. |
| Hypothèse de saisie mains libres au stand | NT-132 | Spike timeboxé uniquement, avec go/no-go en conditions réelles. |
| Besoin de confort catalogue exercices | NT-026, NT-007 (FAIT) | NT-025 rejoint le lot immédiat ; NT-007 est livré (PR #12) et NT-026 reste planifié à faible priorité en Sprint 7, avec recette des références de sessions orphelines. |

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

- **Ouvert — NT-144** : retirer la concurrence résiduelle entre le bloc
  historique « Backlog priorisé » et ce plan, compléter l'index des thèmes,
  clarifier les items précisés ou remplacés et synchroniser les métadonnées des
  vues app et serveur.

- **Résolu (2026-09-02)** : le bloc "Backlog priorisé" du backlog unifié
  mélangeait items livrés, anciens sprints et nouveaux thèmes. Un bandeau
  « Plan historique » a été ajouté en tête de ce bloc dans
  `backlog-unifie.md`, indiquant que ce plan (`plan-sprints.md`) est la
  source courante de priorisation métier, dépendances et sprints livrables.
