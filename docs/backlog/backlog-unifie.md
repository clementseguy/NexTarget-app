# NexTarget — Backlog unifié (source de vérité)

> **Ce fichier est l'unique source de vérité produit.** Les fichiers
> [`vue-app.md`](vue-app.md) et [`vue-serveur.md`](vue-serveur.md) en sont des
> **projections** : rien ne doit exister uniquement dans une vue. Règles de
> gouvernance dans [`README.md`](README.md). Les arbitrages durables sont
> consignés dans les items concernés, sans journal parallèle.

- **Statuts** : les statuts reflètent l'**état réel du code** au 2026-09-03, pas
  les intentions des anciens backlogs.
- **IDs** : `NT-XXX`, stables, jamais réutilisés. Les trous de numérotation sont
  volontaires (réservés à l'insertion future dans un thème).
- **Portée** : `app` | `server` | `both`.
- **Priorité (MoSCoW)** : Must / Should / Could / Won't-now.
- **Estimation** : S / M / L.
- **Valeur métier (VM)** : 1–5, renseignée sur les thèmes 10+ (5 = impact
  direct et mesurable sur la progression en discipline officielle ; 3 =
  friction / qualité des données ; 1 = confort).

> Enrichissement fonctionnel du **2026-07-13** (thèmes 10–13 : disciplines
> TAR, analyse de cible, coach avancé, saisie au stand). Statuts code inchangés.
>
> Enrichissement fonctionnel du **2026-09-02** : râtelier personnel,
> autocomplétion de l'arme des sessions et compteur de tirs par arme
> (NT-008, NT-009, NT-017). Statuts code inchangés.
>
> Livraison produit **v0.6.0** du **2026-09-02** : NT-008, NT-009, NT-017 et
> NT-071 passent à FAIT (`WeaponService`, `WeaponRackSection`,
> `WeaponAutocompleteField`, `DashboardService.generateWeaponShotCounts`,
> PostgreSQL Neon + Alembic). Le composant serveur correspondant est versionné
> v0.3.0.
>
> Enrichissement fonctionnel du **2026-09-02** : sessions libres sans séries,
> score ni groupement (NT-133), livré et fusionné sur `dev` le 2026-09-03.
>
> Livraison prévue dans **v0.7.0** : NT-014, NT-048, NT-061, NT-073, NT-131 et
> NT-133 sont fusionnés sur `dev` et marqués `FAIT`. La release regroupe le
> comparatif 30/90 jours, les sessions libres et guidées au stand, l'hygiène des
> calibres et la finalisation de l'authentification durable et du Coach connecté.
>
> Cadrage produit du **2026-09-04** : NT-131 a été recentré sur un parcours direct
> « au stand » avec préparation courte, brouillon reprenable et saisie guidée
> série par série, sans dépendre d'une session prévue ni d'un template. NT-134
> réserve l'évolution graphique intra-session, à affiner avant développement.
> Le parcours a été fusionné sur `dev` par la PR #31 le 2026-09-04.
>
> Cadrage produit du **2026-09-02** : critères détaillés de NT-014, NT-073,
> NT-048 et NT-133 validés. NT-048 est passé `both / FAIT` le **2026-09-02**
> après livraison de l'adoption app des refresh tokens (stockage sécurisé,
> renouvellement proactif, single-flight, retry unique, résilience hors ligne,
> logout best effort) sur la même branche que ce cadrage. L'audit de clôture
> de NT-061 confirme l'absence de chemin Mistral direct côté client et la
> rotation de la clé historique.
>
> Livraison du **2026-09-03** : NT-014 et NT-133 sont fusionnés sur `dev`
> (PR #28 et #27) et passent à `FAIT` conformément à l'état du code.

## Légende des statuts

| Statut | Sens |
|---|---|
| **FAIT** | Implémenté et présent dans le code |
| **EN COURS** | Partiellement implémenté, reste des sous-tâches identifiées |
| **À FAIRE** | Pas dans le code |
| **À VÉRIFIER** | Ambigu : présent partiellement / périmètre à confirmer |

## Vue d'ensemble

| Thème | Items |
|---|---|
| 1. Carnet de tir | NT-001 → NT-009 |
| 2. Statistiques & Objectifs | NT-010 → NT-017 |
| 3. Exercices | NT-020 → NT-026 |
| 4. Coach IA | NT-030 → NT-034 |
| 5. Auth & Compte | NT-040 → NT-049 |
| 6. Qualité & Observabilité | NT-050 → NT-058 |
| 7. Sécurité & Secrets | NT-060 → NT-066 |
| 8. Plateforme & Déploiement | NT-070 → NT-076 |
| 9. Idées / hors-scope | NT-090 → NT-092 |
| 10. Disciplines officielles & TAR | NT-100 → NT-104 |
| 11. Analyse de cible (photo) | NT-110 → NT-111 |
| 12. Coach : progression & génération | NT-120 → NT-126 |
| 13. Saisie au stand | NT-130 → NT-134 |

---

## Thème 1 — Carnet de tir (Sessions & Séries)

*Cœur produit : enregistrer et consulter l'activité de tir. Fonctionne 100 % hors-ligne.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-001 | Enregistrer une session de tir | app | Must | M | FAIT |
| NT-002 | Saisir des séries détaillées | app | Must | M | FAIT |
| NT-003 | Historique & détail des sessions | app | Must | M | FAIT |
| NT-004 | Synthèse libre du tireur par session | app | Should | S | FAIT |
| NT-005 | Attacher une photo de la cible | app | Must | M | FAIT |
| NT-006 | Analyse d'image de la cible (dispersion/score) | both | Won't-now | L | À FAIRE |
| NT-007 | Filtrer l'historique des sessions par exercice | app | Could | S | FAIT |
| NT-008 | Gérer son râtelier d'armes | app | Must | M | FAIT |
| NT-009 | Autocompléter l'arme d'une session depuis le râtelier | app | Must | M | FAIT |

### NT-001 — Enregistrer une session de tir
- **Thème** : Carnet de tir
- **Description** : Le tireur consigne une séance (arme, calibre, date, catégorie entraînement/match/test) pour construire son carnet.
- **Portée** : app · **Dépendances** : —
- **Critères d'acceptation** : créer une session avec arme, calibre, date, catégorie et statut (prévue/réalisée) ; la session est persistée en local (Hive) et relue après redémarrage.
- **Statut** : FAIT — `ShootingSession`, `session_service`, `create_session_screen`.

### NT-002 — Saisir des séries détaillées
- **Thème** : Carnet de tir
- **Description** : Chaque session contient des séries mesurées, base de toutes les stats et de l'analyse coach.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : par série — nombre de coups, distance, points, groupement (cm), prise (1/2 mains), commentaire ; ajout/suppression/édition de séries.
- **Statut** : FAIT — `Series` (enum `HandMethod`), `session_form`.

### NT-003 — Historique & détail des sessions
- **Thème** : Carnet de tir
- **Description** : Retrouver et rouvrir toute session passée.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : liste chronologique ; écran détail affichant séries, catégorie, synthèse et analyse coach éventuelle.
- **Statut** : FAIT — `sessions_history_screen`, `session_detail_screen`.

### NT-004 — Synthèse libre du tireur
- **Thème** : Carnet de tir
- **Description** : Champ texte libre où le tireur commente sa séance ; enrichit l'analyse du coach.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : `synthese` éditable et persistée ; transmise au coach lors de l'analyse.
- **Statut** : FAIT — `ShootingSession.synthese`.

### NT-005 — Attacher une photo de la cible
- **Thème** : Carnet de tir
- **Description** : Ajouter une photo de la cible en fin de session pour mémoire visuelle et future analyse.
- **Portée** : app · **Dépendances** : NT-001
- **Critères d'acceptation** : sélection/prise de photo, stockage local associé à la session, affichage dans le détail.
- **Priorité** : Must (Could → Must, décision 2026-07-13 : socle du thème 11) · **Statut** : FAIT (PR #12, 2026-07-17) — `SessionPhotoService`, `migration_4_add_photo_path_field`, `ShootingSession.photoPath`, `SessionPhotoField` (formulaire) & `SessionPhotoSection` (détail). · **Notes** : préalable à NT-110/NT-111 (et NT-006, Icebox).

### NT-006 — Analyse d'image de la cible
- **Thème** : Carnet de tir
- **Description** : Analyser la photo (dispersion, score total) pour confronter aux commentaires et enrichir l'analyse coach.
- **Portée** : both · **Dépendances** : NT-005, NT-030
- **Critères d'acceptation** : à définir — extraction dispersion/score ; résultat versé dans le contexte envoyé au coach.
- **Priorité** : Won't-now · **Statut** : À FAIRE. · **Notes** : vision par ordinateur, coûteux ; probablement côté serveur. Décision 2026-07-13 : l'analyse **qualitative multimodale** (NT-111) est retenue en premier ; NT-006 reste en Icebox, à réévaluer après retour d'usage de NT-111.

### NT-007 — Filtrer l'historique des sessions par exercice
- **Thème** : Carnet de tir · **Portée** : app · **Dépendances** : NT-003, NT-022
- **Description** : Retrouver dans l'historique les sessions où un exercice donné a été travaillé.
- **Critères d'acceptation** : filtre par exercice dans l'historique ; combinable avec le filtre réalisées/prévues.
- **Priorité** : Could · **Statut** : FAIT (PR #12, 2026-07-17) — `SessionFilters.byExercise`, sélecteur d'exercice dans `sessions_history_screen` (combinable avec le filtre réalisées/prévues). · **Notes** : repris de l'issue GitHub #5 (tracking v0.3), 2026-07-09.

### NT-008 — Gérer son râtelier d'armes
- **Thème** : Carnet de tir · **Portée** : app · **Dépendances** : —
- **Description** : Dans `Paramètres > Préférences Tir`, le tireur gère rapidement son râtelier personnel afin de réutiliser les noms de ses armes sans ressaisie. Une arme reste volontairement un simple nom textuel : aucune gestion de marque, modèle, calibre, photo ou autre métadonnée.
- **Critères d'acceptation** : ajout rapide, renommage et suppression depuis une interface mobile simple et immédiatement compréhensible ; nom obligatoire après suppression des espaces en début et fin ; unicité contrôlée sans tenir compte de la casse ni des espaces en début et fin ; persistance locale et fonctionnement hors-ligne ; confirmation explicite avant suppression ; supprimer une arme ne modifie ni ne supprime aucune session existante ; renommer une arme demande confirmation puis remplace aussi son nom dans toutes les sessions prévues et réalisées dont le champ `weapon` correspond exactement à l'ancien nom après normalisation (espaces en début/fin ignorés, casse ignorée), sans modifier les saisies seulement proches ; le renommage du râtelier et des sessions est atomique du point de vue utilisateur (aucun état partiellement mis à jour en cas d'échec) ; l'export JSON inclut le râtelier ; l'import accepte les anciens exports dépourvus de râtelier sans erreur et sans effacer le râtelier local existant ; les armes importées respectent les mêmes règles de validation et de déduplication normalisée.
- **Priorité** : Must · **Estimation** : M · **Statut** : FAIT — livré en v0.6.0 ; `Weapon`, `HiveWeaponRepository` (box `weapons`), `WeaponService` (CRUD, renommage propagé avec rollback), `WeaponRackSection` (`Paramètres > Préférences Tir`), export/import JSON (`BackupService`), `migration_5_create_weapons_box`.
- **Notes** : conserver un modèle textuel simple, sans identifiant d'arme ni relation persistée session → arme. Le renommage propagé est le compromis retenu pour préserver les statistiques historiques sans complexifier le modèle de données. Tests de persistance, validation/déduplication, rollback du renommage et rétrocompatibilité import/export couverts.

### NT-009 — Autocompléter l'arme d'une session depuis le râtelier
- **Thème** : Carnet de tir · **Portée** : app · **Dépendances** : NT-001, NT-008
- **Description** : Lorsqu'il crée ou modifie une session, le tireur retrouve rapidement une arme de son râtelier grâce à l'autocomplétion, tout en conservant la liberté de saisir n'importe quel nom.
- **Critères d'acceptation** : le champ `weapon` de `ShootingSession` reste textuel et accepte toujours une saisie libre ; pendant la frappe, les noms correspondants du râtelier sont proposés sans tenir compte de la casse ; sélectionner une proposition remplit le champ avec son nom complet ; aucune proposition ni complétion automatique ne doit écraser ou bloquer la saisie de l'utilisateur — s'il continue à taper une autre valeur, son texte est prioritaire ; comportement disponible pour la création et la modification des sessions prévues comme réalisées, y compris dans le wizard de session ; une valeur saisie librement qui correspond exactement à une arme après normalisation est traitée comme cette arme pour les usages dépendants, sans imposer sa sélection dans la liste ; UX utilisable au clavier et au toucher, sans ajouter d'étape au parcours standard.
- **Priorité** : Must · **Estimation** : M · **Statut** : FAIT — livré en v0.6.0 ; `utils/weapon_autocomplete.dart` (normalisation + suggestions partagées), `WeaponAutocompleteField` réutilisé dans `SessionForm` et le wizard (`WizardIntroStep`).
- **Notes** : logique commune d'autocomplétion centralisée dans `utils/weapon_autocomplete.dart`, réutilisée par tous les parcours de session pour éviter des comportements divergents. Exemple attendu : saisir `CZ` peut proposer `CZ 75 SP-01 Shadow` ; poursuivre avec `CZ 09` conserve `CZ 09`.

---

## Thème 2 — Statistiques & Objectifs

*Transformer les données en progression mesurable.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-010 | Tableau de bord statistiques | app | Must | M | FAIT |
| NT-011 | Statistiques explicatives / évolution | app | Should | M | FAIT |
| NT-012 | Objectifs mesurables | app | Must | M | FAIT |
| NT-013 | Hauts faits (records) | app | Should | S | FAIT |
| NT-014 | Comparatif glissant 30j vs 90j + sparkline | app | Could | M | FAIT |
| NT-015 | Recommandations croisées Objectifs ⇄ Exercices | app | Could | M | À FAIRE |
| NT-016 | Objectifs enrichis : statuts étendus, journal, vue détail | app | Could | M | À FAIRE |
| NT-017 | Compteur de tirs par arme du râtelier | app | Should | S | FAIT |

### NT-010 — Tableau de bord statistiques
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-002
- **Description** : Vue synthétique des indicateurs clés (moyennes, volumes, tendances) sur l'accueil.
- **Critères d'acceptation** : cartes de stats calculées à partir des sessions ; mise à jour à chaque nouvelle session.
- **Statut** : FAIT — `dashboard_service`, `stats_service`, `widgets/dashboard`.

### NT-011 — Statistiques explicatives / évolution
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Courbes et analyses expliquant l'évolution ; règles courantes dans [`docs/features/statistiques.md`](../features/statistiques.md).
- **Critères d'acceptation** : évolution temporelle d'au moins une métrique clé ; lisible sur mobile.
- **Statut** : FAIT — `docs/features/statistiques.md`, `DashboardService`, `EvolutionChart`.

### NT-012 — Objectifs mesurables
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Le tireur se fixe des objectifs chiffrés et suit leur atteinte.
- **Critères d'acceptation** : créer un objectif (métrique, comparateur ≥/≤, valeur cible, statut) ; progression calculée automatiquement.
- **Statut** : FAIT — `Goal` (`GoalMetric`, `GoalComparator`, `GoalStatus`), `goal_service`, écrans list/edit.

### NT-013 — Hauts faits (records)
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012
- **Description** : Mettre en avant les records personnels (meilleure série, meilleur score de session, meilleur groupement).
- **Critères d'acceptation** : métriques `bestSeriesPoints`, `bestSessionPoints`, `bestGroupSize` calculées et affichées.
- **Statut** : FAIT — enum `GoalMetric` (champs 5-7).

### NT-014 — Comparatif glissant 30j vs 90j + sparkline
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-010
- **Description** : Comparer globalement les performances récentes aux 90 derniers jours au moyen de deux métriques indépendantes : moyenne des points par série et moyenne du groupement par série. La fenêtre 90 jours inclut les 30 derniers jours. Présenter pour chaque métrique les deux moyennes, le delta absolu, le delta relatif et une sparkline mobile lisible (ancien P7).
- **Critères d'acceptation** :
  - seules les sessions réalisées et détaillées contribuent aux calculs ; les sessions prévues et les sessions libres NT-133 sont exclues ;
  - la fenêtre récente couvre les 30 derniers jours et la fenêtre de référence les 90 derniers jours, 30 derniers jours inclus ; les bornes temporelles sont explicites, déterministes et identiques entre service, UI, documentation et tests ;
  - le comparatif n'est affiché que s'il existe au moins une série dans les 30 derniers jours et au moins une autre série entre J-90 et J-31 ;
  - le score est la moyenne des points par série ; une série réalisée à zéro point reste une donnée valide ;
  - le groupement est la moyenne des groupements par série ; une série sans groupement cohérent et strictement positif est ignorée uniquement pour cette métrique, mais reste prise en compte pour le score et les autres statistiques ;
  - score et groupement sont présentés séparément, sans statut synthétique ni règle d'interdépendance ; une baisse du groupement est affichée comme une amélioration, par exemple `-4 cm · +14 % d'amélioration`, en conservant l'unité actuelle de l'app ;
  - chaque métrique affiche les valeurs 30 j et 90 j, le delta absolu et le pourcentage calculé par rapport à la moyenne 90 j ; les divisions par zéro et données insuffisantes produisent un état explicite, jamais une valeur trompeuse ;
  - chaque sparkline utilise un point par session réalisée, représentant la moyenne des séries exploitables de cette session pour la métrique concernée ; elle est masquée tant que moins de cinq sessions sont exploitables pour cette métrique ;
  - l'interface reprend la structure validée à deux lignes, reste compacte sur mobile et lisible dans les deux thèmes, sans dépendre uniquement de la couleur ;
  - aucun libellé automatique « amélioration », « baisse » ou « stagnation » n'est déduit de seuils métier : les courbes, signes, unités et deltas restent factuels ;
  - les calculs utilisent une horloge injectable, ne reposent pas sur une limite silencieuse de séries et sont couverts par des tests déterministes des bornes, populations, valeurs nulles et scénarios divergents.
- **Priorité** : Could · **Statut** : FAIT — fusionné sur `dev` par la PR #28 le 2026-09-03 ; populations score/groupement indépendantes, fenêtres emboîtées et bornées, deltas absolus/relatifs, carte Progression alignée, états insuffisants, sparklines par session, UI mobile et aide contextuelle.

### NT-015 — Recommandations croisées Objectifs ⇄ Exercices
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012, NT-021
- **Description** : Suggérer des exercices selon les objectifs en retard, et inversement.
- **Critères d'acceptation** : à définir — au moins une reco pertinente affichée selon l'état des objectifs.
- **Priorité** : Could · **Statut** : À FAIRE.

### NT-016 — Objectifs enrichis : statuts étendus, journal, vue détail
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012
- **Description** : Cycle de vie d'objectif plus riche que l'actuel `active/achieved/failed` : statuts étendus (ex. planned/in_progress/achieved/abandoned), journal des changements de statut (avec dates), vue détail dédiée.
- **Critères d'acceptation** : statuts étendus persistés (migration Hive + adapters régénérés) ; historique des transitions consultable ; écran détail d'un objectif.
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : repris de l'issue GitHub #5 (tracking v0.3), 2026-07-09. Attention : champ Hive additif uniquement (typeIds/index stables).

### NT-017 — Compteur de tirs par arme du râtelier
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-002, NT-008, NT-009
- **Description** : Le tireur visualise le volume total de tirs réalisé avec chacune des armes actuellement présentes dans son râtelier.
- **Critères d'acceptation** : dans `Statistiques > Avancé`, une section placée en toute dernière position affiche un simple compteur par arme du râtelier, sans graphe ; toutes les armes du râtelier sont affichées, y compris avec un compteur à zéro ; pour chaque arme, le total est la somme des `shotCount` de toutes les séries des sessions détaillées réalisées dont le champ `weapon` correspond exactement au nom de l'arme après normalisation (espaces en début/fin ignorés, casse ignorée) ; les sessions prévues sont exclues ; tous les tirs des séries correspondantes sont comptés, essais compris, indépendamment des points ou scores ; le compteur est recalculé après ajout, modification ou suppression d'une session et après ajout, renommage ou suppression d'une arme ; supprimer une arme retire son compteur sans altérer les sessions. Ce total inclut également le `shotCount` porté directement par chaque session libre de la même arme.
- **Priorité** : Should · **Estimation** : S · **Statut** : FAIT — livré en v0.6.0 ; `DashboardService.generateWeaponShotCounts`, `WeaponShotCountsCard` (dernière section de `Statistiques > Avancé`).
- **Notes** : calcul local à partir des sessions, sans graphe ni relation persistée session → arme. Exemple : deux sessions réalisées de 10 séries de 5 coups associées à `CZ 75 SP-01 Shadow` affichent `100 tirs`.

---

## Thème 3 — Exercices

*Catalogue d'exercices reliés aux objectifs et aux sessions.*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-020 | Gérer des exercices (CRUD) | app | Must | M | FAIT |
| NT-021 | Lier exercices ↔ objectifs | app | Should | S | FAIT |
| NT-022 | Lier exercices ↔ sessions | app | Should | S | FAIT |
| NT-023 | Création d'exercice par le coach | both | Could | L | À FAIRE |
| NT-024 | Stats d'exécution (fenêtres glissantes) | app | Could | M | À FAIRE |
| NT-025 | Niveau de difficulté d'exercice | app | Could | S | À FAIRE |
| NT-026 | Supprimer un exercice depuis l'interface | app | Could | S | À FAIRE |

### NT-020 — Gérer des exercices (CRUD)
- **Thème** : Exercices · **Portée** : app · **Dépendances** : —
- **Description** : Créer/éditer des exercices typés avec consignes détaillées.
- **Critères d'acceptation** : catégorie (`precision/group/speed/technique/mental/physical`), type (`stand/home`), description, durée, matériel, consignes ordonnées, priorité.
- **Statut** : FAIT — `Exercise`, `exercise_service`, écrans list/form.

### NT-021 — Lier exercices ↔ objectifs
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-012, NT-020
- **Description** : Rattacher un exercice aux objectifs qu'il sert.
- **Critères d'acceptation** : `goalIds` éditable ; navigation objectif → exercices liés.
- **Statut** : FAIT — `Exercise.goalIds`.

### NT-022 — Lier exercices ↔ sessions
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-001, NT-020
- **Description** : Associer des exercices pratiqués à une session.
- **Critères d'acceptation** : `ShootingSession.exercises` (IDs) éditable et affiché.
- **Statut** : FAIT — `ShootingSession.exercises`.

### NT-023 — Création d'exercice par le coach
- **Thème** : Exercices · **Portée** : both · **Dépendances** : NT-020, NT-030
- **Description** : À partir d'une analyse de session, le coach propose un exercice prêt à enregistrer.
- **Critères d'acceptation** : à définir — l'analyse coach peut retourner un exercice structuré ; l'app permet de l'ajouter au catalogue.
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : dépend du format de sortie structuré du coach. **Précisé/décomposé par NT-122 + NT-123** (thème 12), qui font référence.

### NT-024 — Stats d'exécution (fenêtres glissantes)
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-022
- **Description** : Compter l'usage des exercices (`usageCount`, `lastPerformedAt`) puis stats par fenêtres glissantes (ancien P4).
- **Critères d'acceptation** : incrément d'usage à chaque session liée ; date de dernière exécution ; stats sur fenêtre glissante.
- **Priorité** : Could · **Statut** : À FAIRE.

### NT-025 — Niveau de difficulté d'exercice
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-020
- **Description** : Classer les exercices par difficulté (beginner/advanced/expert).
- **Critères d'acceptation** : champ difficulté sur `Exercise` ; filtrable.
- **Priorité** : Could · **Statut** : À FAIRE.

### NT-026 — Supprimer un exercice depuis l'interface
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-020, NT-022
- **Description** : Permettre au tireur de supprimer depuis la liste un exercice devenu inutile, sans supprimer ni rendre inaccessibles les sessions qui y étaient associées.
- **Critères d'acceptation** : action « Supprimer » accessible depuis l'interface des exercices ; confirmation explicite avant suppression ; suppression effective du catalogue ; les sessions existantes ne sont pas supprimées ; **test manuel obligatoire : supprimer un exercice utilisé par des sessions, puis vérifier que l'historique revient proprement à « Tous les exercices », sans erreur**.
- **Priorité** : Could (faible, mais planifié) · **Estimation** : S · **Statut** : À FAIRE.
- **Notes** : créé à la suite de la recette NT-007 du 2026-07-24. La suppression existe déjà dans `ExerciseService` et le repository Hive, mais aucune action ne l'expose dans l'UI. Ce manque n'est pas bloquant pour la validation de NT-007.

---

## Thème 4 — Coach IA

*Analyse IA des séances via le serveur NexTarget. **Décision : coach connecté uniquement** (voir NT-061).*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-030 | Analyse d'une session par le coach IA | both | Must | M | FAIT |
| NT-031 | Prompt d'analyse centralisé côté serveur | server | Must | S | FAIT |
| NT-032 | Multi-personas coach (neutre / cool) | both | Should | M | FAIT |
| NT-033 | Écran "Coach" : analyse transverse multi-sessions | both | Should | L | À FAIRE |
| NT-034 | Affiner les prompts des personas coach | server | Could | S | À FAIRE |

### NT-030 — Analyse d'une session par le coach IA
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-002, NT-040, NT-060
- **Description** : Le tireur obtient une analyse rédigée de sa séance ; l'appel Mistral passe par le serveur (proxy), sans clé côté client.
- **Critères d'acceptation** : app envoie les données de session au serveur ; `POST /coach/analyze-session` (JWT requis) renvoie une analyse texte ; rendu markdown dans l'app.
- **Statut** : FAIT — serveur `api/coach.py` ; app `ServerCoachAnalysisService` (unique chemin d'analyse depuis NT-061).

### NT-031 — Prompt d'analyse centralisé côté serveur
- **Thème** : Coach IA · **Portée** : server · **Dépendances** : NT-030
- **Description** : Le template de prompt et l'assemblage vivent côté serveur (le client n'envoie plus le prompt).
- **Critères d'acceptation** : `build_prompt` assemble session + template ; template versionné (`prompts/coach_neutre.yaml`).
- **Statut** : FAIT — `services/prompt_builder.py`.

### NT-032 — Multi-personas coach (neutre / cool)
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-031
- **Description** : Proposer plusieurs tons de coach (neutre, cool…).
- **Critères d'acceptation** : ≥2 variantes de prompt côté serveur ; sélection du ton depuis l'app via `prompt_variant`.
- **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S2) — serveur : `coach_cool.yaml` + `_VARIANT_FILES` ; app : préférence `coach_persona` (Paramètres > Coach IA), envoyée en `prompt_variant`.
- **Notes** : retour de recette S2 (2026-07-09) — le ton se choisit **uniquement dans Paramètres** (le sélecteur initialement présent dans l'écran Session a été retiré). L'affinage du contenu des prompts est tracé dans NT-034.

### NT-033 — Écran "Coach" : analyse transverse multi-sessions
- **Thème** : Coach IA · **Portée** : both · **Dépendances** : NT-030
- **Description** : Un écran dédié qui analyse l'ensemble de l'activité (plusieurs sessions, changements d'armes/calibres, régularité, comportements répétés) et propose des actions.
- **Critères d'acceptation** : à définir — agrégation multi-sessions ; analyse coach globale ; suggestions d'actions.
- **Priorité** : Should · **Statut** : À FAIRE.
- **Notes** : `coach_screen.dart` existe mais est un placeholder « Coming soon ». **Précisé/décomposé par NT-120 + NT-121** (thème 12), qui font référence.

### NT-034 — Affiner les prompts des personas coach
- **Thème** : Coach IA · **Portée** : server · **Dépendances** : NT-032
- **Description** : Itérer sur le contenu des templates `coach_neutre.yaml` / `coach_cool.yaml` (qualité, différenciation des tons, format de sortie) à partir des retours d'usage réels.
- **Critères d'acceptation** : à définir — prompts revus et validés en recette sur des sessions réelles ; différence de ton nette entre personas ; règles de mesurabilité conservées.
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : créé suite à la recette S2 (2026-07-09). Aucun changement de contrat d'API.

---

## Thème 5 — Auth & Compte

*Compte optionnel : le carnet marche sans login ; le compte débloque le coach IA (proxy).*

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-040 | Authentification OAuth Google | both | Must | M | FAIT |
| NT-041 | Authentification optionnelle | app | Must | S | FAIT |
| NT-042 | Profil utilisateur (nom/avatar/niveau) | both | Should | M | FAIT |
| NT-043 | Endpoint `/users/me` | server | Must | S | FAIT |
| NT-044 | Authentification OAuth Facebook | both | Could | M | À FAIRE |
| NT-045 | Stats publiques / partage de profil | both | Won't-now | M | À FAIRE |
| NT-046 | Gamification | both | Won't-now | L | À FAIRE |
| NT-047 | Apple Sign In | both | Won't-now | M | À FAIRE |
| NT-048 | Refresh tokens + rotation | both | Should | M | FAIT |
| NT-049 | Interface d’administration read-only des utilisateurs | server | Should | M | FAIT |

### NT-040 — Authentification OAuth Google
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : —
- **Description** : Se connecter avec Google (flow mobile), pour accéder aux fonctions connectées.
- **Critères d'acceptation** : `/auth/google/login` + callback (vérif `id_token` via `google-auth`) ; redirect mobile `nextarget://callback?token=` ; échange callback→access ; app `signInWithGoogle`.
- **Statut** : FAIT — serveur `api/auth_google.py`, app `auth_service.dart`.

### NT-041 — Authentification optionnelle
- **Thème** : Auth & Compte · **Portée** : app · **Dépendances** : —
- **Description** : L'app est pleinement utilisable sans compte ; le login est facultatif.
- **Critères d'acceptation** : carnet, stats, exercices, objectifs fonctionnent hors connexion ; le login n'est requis que pour le coach IA connecté.
- **Statut** : FAIT — `auth_provider`, mode déconnecté préservé.

### NT-042 — Profil utilisateur (nom/avatar/niveau)
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Afficher nom/pseudo, avatar, niveau d'expérience (beginner/advanced/expert), date d'inscription.
- **Critères d'acceptation** : serveur stocke `display_name`, `display_name_custom`, `avatar_url`, `experience_level` ; app les affiche.
- **Statut** : FAIT — `models/user.py`, `profile_screen.dart`.
- **Notes** : l'app permet l'édition du niveau d'expérience. L'édition d'un pseudo personnalisé est explicitement exclue de NT-042 ; elle devra recevoir un item distinct si elle devient souhaitée.

### NT-043 — Endpoint `/users/me`
- **Thème** : Auth & Compte · **Portée** : server · **Dépendances** : NT-040
- **Description** : Renvoyer le profil de l'utilisateur authentifié.
- **Critères d'acceptation** : `GET /users/me` protégé (JWT `access`) renvoie le profil.
- **Statut** : FAIT — `api/users.py`.

### NT-044 — Authentification OAuth Facebook
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Se connecter avec Facebook.
- **Critères d'acceptation** : serveur `/auth/facebook/*` **validé de bout en bout** contre une vraie app Facebook (au-delà des tests mockés) ; **app : bouton Facebook câblé** (manquant aujourd'hui).
- **Priorité** : Could · **Statut** : À FAIRE.
- **Notes** : **non prioritaire**. Côté serveur, le **code est présent** (`api/auth_facebook.py` : `/start` + `/callback`, échange de code, Graph API) mais **reste à valider** de bout en bout : couvert uniquement par des tests mockés (`tests/test_oauth_flows.py`), pas encore éprouvé contre une vraie app Facebook (credentials non configurés). Côté app, aucun bouton Facebook. Statut global **À FAIRE** tant que le flow n'est pas câblé (app) et validé (serveur). Arbitrage 2026-07-07 : « plus tard, optionnelle ».

### NT-045 — Stats publiques / partage de profil
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Exposer (en option) des stats publiques du tireur.
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-046 — Gamification
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Système de gamification (badges, niveaux…).
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-047 — Apple Sign In
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Provider Apple (requis pour publication iOS si autres logins sociaux présents).
- **Critères d'acceptation** : à définir. · **Priorité** : Won't-now · **Statut** : À FAIRE. · **Notes** : roadmap serveur v0.2.

### NT-048 — Refresh tokens + rotation
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Maintenir la connexion aux fonctionnalités avancées sans imposer un nouveau login à l'expiration de l'access token, tout en préservant la promesse hors ligne du carnet et en détectant le rejeu d'un refresh token.
- **Critères d'acceptation** :
  - le serveur émet un refresh token opaque lors de l'échange OAuth, ne persiste que son hash SHA-256, applique une expiration glissante de 30 jours et une rotation à usage unique ;
  - le rejeu d'un refresh token consommé révoque toute sa famille ; `/auth/token/revoke` reste idempotent et ne révèle pas l'existence d'un token ;
  - l'app stocke access token, refresh token et informations d'expiration dans `flutter_secure_storage`, sans jamais les journaliser ; chaque paire issue d'une rotation remplace atomiquement la précédente ;
  - l'app renouvelle proactivement l'access token juste avant son expiration ; après un `401`, elle peut effectuer un unique renouvellement et rejouer une seule fois la requête, sans boucle ;
  - un mécanisme single-flight empêche deux requêtes concurrentes de consommer simultanément le même refresh token ;
  - un refresh invalide, expiré, révoqué ou rejoué termine la session connectée et demande une reconnexion Google ; les installations existantes sans refresh token suivent cette même reconnexion unique ;
  - une panne réseau ne supprime pas les tokens et ne déconnecte pas l'utilisateur : le carnet, les statistiques, objectifs et exercices restent disponibles hors ligne, tandis que le Coach indique clairement son indisponibilité ;
  - le logout tente la révocation serveur en best effort, puis efface systématiquement tous les tokens et données d'authentification locales, même si le serveur est indisponible ;
  - tous les appels authentifiés, notamment Coach et profil, utilisent le même mécanisme ; les erreurs temporaires restent distinguées d'une session réellement expirée ;
  - les tests couvrent rotation, renouvellement proactif, retry unique, concurrence, rejeu, expiration, indisponibilité réseau, logout et migration depuis le stockage historique sans refresh token.
- **Priorité** : Should · **Estimation** : M · **Statut** : FAIT.
- **Notes** : côté serveur, livré et testé (`/auth/token/exchange`, `/auth/token/refresh`,
  `/auth/token/revoke`, rotation, détection de rejeu, révocation de famille) ;
  aucune modification serveur n'a été nécessaire lors de l'adoption app (contrat
  vérifié conforme). Côté app (2026-09-02, branche
  `feat/NT-048-refresh-tokens-rotation`) : `AuthService` stocke la paire
  access/refresh + expirations dans `flutter_secure_storage` sous une clé unique
  (remplacement atomique) ; `AuthenticatedHttpClient` assure le renouvellement
  proactif, le single-flight, le retry unique après `401` et le rejeu sûr des
  requêtes (jamais de `BaseRequest` déjà finalisé, y compris pour un corps
  streamed) ; Coach et profil partagent ce même mécanisme ; les installations
  historiques sans refresh token déclenchent une reconnexion Google unique ;
  une panne réseau préserve les tokens sans déconnecter l'utilisateur (carnet,
  stats, objectifs, exercices utilisables hors ligne). Tests ajoutés :
  `test/services/auth_service_test.dart`, `auth_service_refresh_test.dart`,
  `authenticated_http_client_test.dart`.

### NT-049 — Interface d’administration read-only des utilisateurs
- **Thème** : Auth & Compte · **Portée** : server · **Dépendances** : NT-040, NT-042
- **Description** : En tant qu'administrateur NexTarget, consulter dans une page d'administration légère et sécurisée les utilisateurs inscrits afin de diagnostiquer les authentifications OAuth, sans exposer de secret ni permettre de mutation des données.
- **Critères d'acceptation** :
  - [x] une route d'administration dédiée affiche une page HTML serveur simple ;
  - [x] toutes les routes d'administration sont protégées par des identifiants administrateur fournis exclusivement par variables d'environnement ;
  - [x] aucun identifiant administrateur, mot de passe ou secret n'est codé en dur, persisté en base, inclus dans le HTML ou écrit dans les logs ;
  - [x] l'interface affiche uniquement les champs utilisateur réellement présents et utiles au diagnostic : ID interne, email, provider, nom affiché, statut, avatar et date de création ;
  - [x] aucun champ inexistant n'est ajouté uniquement pour l'affichage ;
  - [x] aucun access token, refresh token, secret OAuth, mot de passe, hash ou clé API n'est exposé ;
  - [x] l'interface et ses routes ne proposent aucune insertion, modification, suppression ni autre action métier ;
  - [x] les réponses administrateur empêchent raisonnablement la mise en cache et l'indexation et utilisent des en-têtes de sécurité adaptés ;
  - [x] l'accès sans authentification ou avec de mauvais identifiants est refusé ;
  - [x] l'accès avec les bons identifiants permet de consulter les utilisateurs ;
  - [x] aucune méthode ni route susceptible de muter les données n'est disponible sous le préfixe d'administration ;
  - [x] la configuration locale et Render ainsi que la procédure d'accès sont documentées ;
  - [x] le fonctionnement actuel du login Google est audité et les constats sont documentés.
- **Priorité** : Should · **Estimation** : M · **Statut** : FAIT.
- **Notes** : développement livré côté `NexTarget-server` sous la forme d'une page d'administration read-only exposée par `GET /app/admin/users`. Toute correction fonctionnelle du login Google identifiée pendant l'audit reste hors périmètre et doit faire l'objet d'une validation explicite.

---

## Thème 6 — Qualité & Observabilité

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-050 | SonarCloud + Quality Gate + couverture (app) | app | Must | M | FAIT |
| NT-051 | Analyse statique & lint (durcir) | app | Should | S | FAIT |
| NT-052 | Cahier de recette généré | app | Should | S | FAIT |
| NT-053 | Logging structuré + tracing (serveur) | server | Should | M | FAIT |
| NT-054 | Tests OAuth mockés (providers externes) | server | Should | M | FAIT |
| NT-055 | CI serveur (tests + couverture) | server | Should | S | FAIT |
| NT-056 | Harmonisation des erreurs réseau (app) | app | Could | S | À FAIRE |
| NT-057 | Nettoyage des widgets dupliqués (app) | app | Could | S | À FAIRE |
| NT-058 | Fakes de repository partagés pour les tests (app) | app | Should | S | FAIT |

### NT-050 — SonarCloud + Quality Gate + couverture (app)
- **Portée** : app · **Dépendances** : — · **Description** : Qualité continue mesurée sur l'app.
- **Critères d'acceptation** : analyse SonarCloud sur push `dev` et PR `main` ; import couverture LCOV ; badges README ; Quality Gate ≥ B.
- **Statut** : FAIT — `.github`, `sonar-project.properties`, CHANGELOG T1.

### NT-051 — Analyse statique & lint (durcir)
- **Portée** : app · **Dépendances** : NT-050 · **Description** : Renforcer l'analyse statique pour tenir le niveau de qualité visé.
- **Critères d'acceptation** : un ruleset de lint actif (ex. `flutter_lints` ou `very_good_analysis`) ; `flutter analyze` sans warning ; job d'analyse en CI.
- **Statut** : FAIT (2026-07-07, sprint S1) — `flutter_lints` activé (`analysis_options.yaml`), 138 issues corrigées (dont un vrai bug : route `/settings` jamais résolue, `unrelated_type_equality_checks`), step CI `flutter analyze --fatal-infos` ajouté au workflow SonarCloud.
- **Notes** : `dart_code_metrics` non retenu (payant/archivé) ; `flutter_lints` + Sonar suffisent.

### NT-052 — Cahier de recette généré
- **Portée** : app · **Dépendances** : — · **Description** : Tests manuels reproductibles avant chaque MR vers `main`.
- **Critères d'acceptation** : source YAML → génération markdown (`scripts/generate_cahier_recette.dart`) ; joué avant MR.
- **Statut** : FAIT — `docs/tests/cahier_recette.*`.

### NT-053 — Logging structuré + tracing (serveur)
- **Portée** : server · **Dépendances** : — · **Description** : Observabilité serveur (JSON + OpenTelemetry).
- **Critères d'acceptation** : logs structurés ; corrélation des requêtes. · **Priorité** : Should · **Statut** : FAIT (2026-07-09, sprint S3) — logs JSON (stdlib) + middleware X-Request-ID (une ligne par requête : method/path/status/durée). OpenTelemetry écarté en single-instance (décision documentée AGENTS serveur).

### NT-054 — Tests OAuth mockés
- **Portée** : server · **Dépendances** : NT-040 · **Description** : Tester le flow OAuth complet avec providers externes mockés.
- **Critères d'acceptation** : Google/Facebook mockés ; cas nominal + erreurs. · **Priorité** : Should · **Statut** : FAIT (2026-07-09, sprint S3) — `tests/test_oauth_flows.py` (flows complets Google/Facebook mockés, nominal + erreurs), fixtures partagées `tests/conftest.py`, migration ASGITransport.

### NT-055 — CI serveur (tests + couverture)
- **Portée** : server · **Dépendances** : — · **Description** : Le serveur n'a pas de pipeline CI.
- **Critères d'acceptation** : workflow CI lançant `pytest` (+ couverture) sur push/PR.
- **Priorité** : Should · **Statut** : FAIT (2026-07-09, sprint S3) — `.github/workflows/ci.yml` (pytest + pytest-cov, Python 3.11, push/PR).

### NT-056 — Harmonisation des erreurs réseau (app)
- **Portée** : app · **Dépendances** : — · **Description** : Unifier la présentation des erreurs réseau (timeout, DNS, HTTP) sur tous les flux (auth, profil, backup) sur le modèle du coach (messages user-friendly via exception dédiée).
- **Critères d'acceptation** : mêmes familles de messages partout ; aucun message technique brut à l'écran.
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : repris de l'issue #5 ; le flux coach est déjà conforme (v0.5.0).

### NT-057 — Nettoyage des widgets dupliqués (app)
- **Portée** : app · **Dépendances** : — · **Description** : Chasse aux widgets/écrans dupliqués ou morts et factorisation.
- **Critères d'acceptation** : inventaire fait ; doublons supprimés ou factorisés ; aucune régression (tests verts).
- **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : repris de l'issue #5 ; `MainNavigation` (doublon d'`AppNavigator`) déjà supprimé en v0.5.0.

### NT-058 — Fakes de repository partagés pour les tests (app)
- **Thème** : Qualité & Observabilité · **Portée** : app · **Dépendances** : —
- **Description** : Chaque fichier de test réinventait son propre « fake » en mémoire de `SessionRepository` (une dizaine d'implémentations ad hoc). Certains faisaient `getAll() => List.of(sessions)` — une copie de liste mais pas des objets — alors que `HiveSessionRepository.getAll()` reconstruit toujours des objets frais depuis les maps sérialisées. Une logique qui mute un champ avant un `update()` qui échoue (ex. rollback de renommage, NT-008) pouvait alors laisser un fake dans un état incohérent tout en donnant l'impression d'un bug côté code de production, générant des diagnostics longs et trompeurs.
- **Critères d'acceptation** : `test/support/fake_session_repository.dart` clone chaque session lue (comme le ferait Hive) ; `test/support/async_test_helpers.dart` fournit `captureError()` pour tester proprement une exception async (évite le piège `expect(() => asyncFn(), throwsA(...))` non awaité) ; les deux ont un test nominal + un cas d'erreur ; au moins un fake ad hoc préexistant migré vers le fake partagé à titre d'exemple.
- **Priorité** : Should · **Estimation** : S · **Statut** : FAIT — `test/support/fake_session_repository.dart`, `test/support/async_test_helpers.dart` (+ tests dédiés) ; `test/goal_service_lot_a_test.dart` migré. Convention documentée dans `AGENTS.md`.
- **Notes** : tâche de fond (boy scout rule), déclenchée par un débogage long lors de NT-008 (rollback du renommage d'arme). Les autres fakes ad hoc préexistants (stubs en lecture seule, mocks spécialisés) n'ont pas été touchés : risque de régression non justifié pour des fakes qui n'exposent pas ce défaut. Migration plus large possible en tâche future si souhaité.

---

## Thème 7 — Sécurité & Secrets

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-060 | Proxy Mistral côté serveur (clé hors client) | server | Must | M | FAIT |
| NT-061 | Coach « connecté uniquement » : retrait clé Mistral client + rotation | both | Must | M | FAIT |
| NT-062 | Rate limiting de l'endpoint coach | server | Must | S | FAIT |
| NT-063 | State OAuth à usage unique (CSRF) | server | Must | S | FAIT |
| NT-064 | Vérification du type de token JWT | server | Must | S | FAIT |
| NT-065 | Restreindre CORS par environnement | server | Should | S | FAIT |
| NT-066 | Vérification du nonce Google | server | Should | S | FAIT |

### NT-060 — Proxy Mistral côté serveur
- **Portée** : server · **Dépendances** : NT-030 · **Description** : Centraliser l'appel Mistral côté serveur pour retirer la clé du client (ancien P2).
- **Critères d'acceptation** : `POST /coach/analyze-session` appelle Mistral ; clé lue depuis l'env serveur (`MISTRAL_API_KEY`) ; ni clé ni prompt complet côté client.
- **Statut** : FAIT — `api/coach.py`, `services/mistral_client.py`, `core/config.py`.

### NT-061 — Coach « connecté uniquement » : retrait clé Mistral client + rotation
- **Portée** : both · **Dépendances** : NT-030, NT-060 · **Description** : Rendre le coach accessible **uniquement connecté**, supprimer le chemin Mistral direct et la clé embarquée dans le client, puis faire tourner la clé (arbitrage 2026-07-07).
- **Critères d'acceptation** :
  - le chemin `CoachAnalysisService` direct (Mistral) et la clé côté client sont supprimés ;
  - l'analyse coach exige un utilisateur authentifié (message clair sinon) ;
  - la clé Mistral historique est révoquée/rotée ;
  - le carnet de tir reste utilisable hors-ligne (le coach seul devient online-only).
- **Priorité** : Must · **Statut** : FAIT (code, 2026-07-07, sprint S1 ; clôture auditée le 2026-09-02) — `CoachAnalysisService` direct supprimé, plus aucune clé/config/prompt Mistral côté client (`AppConfig`, `config.yaml`, `build_apk.sh` purgés), analyse protégée par l'auth avec message clair et CTA login ; la clé Mistral historique a été rotée par le mainteneur.
- **Notes** : l'audit de clôture confirme que `ServerCoachAnalysisService` est l'unique chemin d'analyse dans l'app et qu'aucun appel local, proxy de secours ou fallback Mistral client ne subsiste. Le client serveur Mistral reste légitimement côté backend. Les notes de version conservent uniquement le contexte historique nécessaire.

### NT-062 — Rate limiting de l'endpoint coach
- **Portée** : server · **Dépendances** : NT-060 · **Description** : Empêcher l'abus qui viderait le quota Mistral.
- **Critères d'acceptation** : limite par utilisateur (10 requêtes / 5 min) ; réponse 429 au-delà.
- **Statut** : FAIT — `services/rate_limiter.py` (in-memory). · **Notes** : Redis si multi-instance (lié à NT-071).

### NT-063 — State OAuth à usage unique (CSRF)
- **Portée** : server · **Dépendances** : NT-040 · **Critères d'acceptation** : state créé puis consommé une seule fois ; TTL ; non rejouable.
- **Statut** : FAIT — `services/oauth_state.py`. · **Notes** : en mémoire (single-instance).

### NT-064 — Vérification du type de token JWT
- **Portée** : server · **Dépendances** : NT-040 · **Critères d'acceptation** : `payload["type"]` vérifié (`access` vs `callback`) ; un callback token ne donne jamais accès à l'API.
- **Statut** : FAIT — `core/security.py`, `api/deps.py`.

### NT-065 — Restreindre CORS par environnement
- **Portée** : server · **Dépendances** : — · **Description** : `allow_origins=["*"]` est un TODO connu.
- **Critères d'acceptation** : origines restreintes en prod via configuration. · **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S1) — `CORS_ALLOW_ORIGINS` (défaut : `*` en dev, aucune origine sinon), tests `tests/test_cors.py`.

### NT-066 — Vérification du nonce Google
- **Portée** : server · **Dépendances** : NT-040 · **Description** : Nonce généré mais non vérifié dans le callback (identifié dans `SECURITY_ANALYSIS.md`).
- **Critères d'acceptation** : nonce vérifié à la réception du callback. · **Priorité** : Should · **Statut** : FAIT (2026-07-07, sprint S1) — claim `nonce` comparé au state stocké (400 sinon), tests mockés `tests/test_auth_google_nonce.py`.

---

## Thème 8 — Plateforme & Déploiement

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-070 | Déploiement serveur (Render) | server | Must | S | FAIT |
| NT-071 | Migration SQLite → Postgres Neon + Alembic | server | Must | M | FAIT |
| NT-072 | Framework de migrations Hive | app | Should | M | FAIT |
| NT-073 | Calibre par défaut + normalisation statistique | app | Could | S | FAIT |
| NT-074 | Saisie séries plein écran + navigation rapide | app | Could | M | À FAIRE |
| NT-075 | Onboarding + aide contextuelle | app | Could | M | FAIT |
| NT-076 | Cache stats + compactage Hive | app | Could | M | À FAIRE |

### NT-070 — Déploiement serveur (Render)
- **Portée** : server · **Dépendances** : — · **Critères d'acceptation** : déploiement via `render.yaml` ; variables d'env (JWT, OAuth, `MISTRAL_API_KEY`) documentées.
- **Statut** : FAIT — `render.yaml`, `docs/tech/render_setup.md`.

### NT-071 — Migration SQLite → Postgres Neon + Alembic
- **Thème** : Plateforme & Déploiement · **Portée** : server · **Dépendances** : NT-070
- **Description** : Remplacer la base SQLite stockée sur le disque éphémère de Render par une base PostgreSQL Neon persistante, afin que les comptes utilisateurs et les refresh tokens survivent aux mises en veille, redémarrages et redéploiements du serveur. Industrialiser en même temps les évolutions du schéma avec Alembic.
- **Architecture retenue** : service FastAPI conservé sur Render Free ; projet Neon Free `nextarget-prod`, région AWS Europe (Frankfurt), branche `production`, base `neondb` et version PostgreSQL stable gérée par défaut par Neon. Le rôle propriétaire Neon `neondb_owner` est réservé aux migrations, sauvegardes et opérations d'administration ; un rôle dédié à privilèges minimaux (ex. `nextarget_app`) est créé pour le runtime. L'application utilise la connexion poolée de ce rôle dédié ; les migrations et sauvegardes utilisent la connexion directe du rôle propriétaire. SQLite reste autorisé uniquement pour le développement local et les tests unitaires ciblés. Un environnement Neon de staging est prévu ultérieurement mais reste hors périmètre de cet item.
- **Stratégie de bascule** : initialiser une base Neon vide, sans importer la base SQLite éphémère de Render ; créer le schéma par une migration Alembic initiale ; invalider volontairement les sessions/refresh tokens existants et demander une reconnexion unique après la bascule.
- **Critères d'acceptation** :
  - le serveur supporte PostgreSQL via un pilote explicitement déclaré et conserve SQLite pour le développement local ;
  - Alembic est initialisé et une migration de référence crée toutes les tables, contraintes et index des modèles `User` et `RefreshToken` ; Alembic devient la source de vérité des évolutions du schéma et `SQLModel.metadata.create_all()` n'administre plus le schéma de production ;
  - un rôle PostgreSQL dédié au runtime dispose uniquement des droits nécessaires de connexion et de lecture/écriture sur le schéma applicatif ; il ne peut pas modifier le schéma, tandis que `neondb_owner` reste réservé aux migrations et à l'administration ;
  - deux variables Render distinctes sont utilisées : `DATABASE_URL` pour l'URL Neon poolée du rôle runtime et `DATABASE_MIGRATION_URL` pour l'URL directe du rôle propriétaire utilisée par Alembic et les opérations d'administration ; leurs valeurs sont saisies dans Render et aucun secret, hostname complet ni mot de passe n'est commité ou journalisé ;
  - les migrations sont exécutées avant le démarrage d'Uvicorn sur Render ; une migration en échec empêche le serveur de démarrer et produit un diagnostic exploitable sans divulguer de secret ;
  - le fonctionnement nominal et les erreurs de connexion/migration sont couverts par des tests, dont au moins un parcours exécuté contre PostgreSQL ; la suite SQLite existante reste verte ;
  - après création d'un utilisateur, celui-ci et ses données d'authentification restent présents après une veille Render/Neon, un redémarrage et un redéploiement ; une reconnexion Google retrouve le même couple `(email, provider)` sans créer de doublon ;
  - la bascule à vide et l'invalidation des sessions existantes sont documentées et vérifiées en recette ;
  - une procédure de sauvegarde manuelle `pg_dump` via la connexion directe, de restauration et de rollback est documentée et testée avant la bascule ;
  - la documentation de déploiement, `.env.example` et `render.yaml` décrivent les deux URLs, leur usage, la gestion manuelle des secrets et la surveillance des quotas Neon Free ;
  - aucun workflow JavaScript Neon (`neon.ts`, `neon deploy`, MCP ou skills Neon) n'est introduit : le backend reste géré par Python, SQLModel et Alembic.
- **Priorité** : Must (Should → Must, décision 2026-09-02 après constat de perte des utilisateurs en production) · **Estimation** : M · **Statut** : FAIT — livré dans la release produit v0.6.0 (composant NexTarget-server v0.3.0) ; PostgreSQL Neon, Alembic, migrations avant démarrage, rôles runtime/propriétaire séparés et procédures de sauvegarde/rollback documentés.
- **Notes** : décision et diagnostic suivis dans l'issue serveur [#9](https://github.com/clementseguy/NexTarget-server/issues/9). Cette migration corrige la persistance relationnelle ; elle ne rend pas multi-instance les composants encore en mémoire (rate limiting NT-062 et state OAuth NT-063). La création d'un environnement Neon de staging et l'automatisation périodique des sauvegardes feront l'objet de tâches ultérieures si nécessaires. Preuves de livraison : `NexTarget-server` (`alembic/`, `scripts/run_migrations.py`, `app/services/database.py`, `docs/tech/postgres_neon_migration.md`, tests de migration).

### NT-072 — Framework de migrations Hive
- **Portée** : app · **Dépendances** : — · **Description** : Runner générique de migrations de schéma local (ancien P5).
- **Critères d'acceptation** : `MigrationRunner` applique les migrations par version croissante ; version stockée.
- **Statut** : FAIT — `lib/migrations/` (`MigrationRunner`, `SchemaVersionStore`, migrations 2 & 3).
- **Notes** : le **script de vérification de cohérence de schéma** (part du P5) reste À FAIRE — le tracer comme sous-tâche si besoin.

### NT-073 — Calibre par défaut + normalisation statistique
- **Portée** : app · **Dépendances** : NT-001 · **Description** : Améliorer l'hygiène des données sans retirer la liberté de saisie : proposer une liste cohérente, permettre un calibre par défaut explicite et regrouper uniquement les alias connus dans les statistiques par calibre. Aucun « dernier calibre utilisé » n'est mémorisé.
- **Critères d'acceptation** :
  - la préférence « calibre par défaut » est facultative et ne peut contenir qu'une valeur du référentiel configuré ; vide, elle n'applique aucun préremplissage ;
  - le calibre par défaut préremplit les nouvelles sessions réalisées et prévues ; l'édition conserve toujours la valeur enregistrée dans la session ;
  - tous les parcours de saisie utilisent une autocomplétion centralisée proposant les calibres connus, sans autoremplacement ni écrasement de la saisie ; le champ de session reste libre ;
  - l'entrée générique `Autre` est retirée du référentiel et des suggestions, puisqu'une valeur libre peut être saisie directement ;
  - la normalisation de recherche et la résolution statistique sont deux opérations distinctes ; aucune valeur persistée, historique ou nouvellement saisie n'est réécrite vers un libellé canonique ;
  - un calibre libre inconnu reste inclus dans toutes les statistiques globales de score, groupement et volume, mais est exclu des répartitions et regroupements par calibre ;
  - les alias `9mm`, `9 mm`, `9x19`, `9 mm Para` et `9mm (9x19)` sont regroupés statistiquement sous le libellé canonique `9 mm` ; `.380 ACP` reste distinct et aucun regroupement avec `9 mm court` n'est introduit sans retour métier complémentaire ;
  - le référentiel est validé et dédupliqué après normalisation ; les comportements sont cohérents dans les paramètres, la création et l'édition des sessions réalisées et prévues, ainsi que dans le wizard ;
  - les tests couvrent préférence vide/valide/invalide, préremplissage, conservation à l'édition, saisie libre, absence d'autoremplacement, alias connus, valeur inconnue et exclusion limitée aux statistiques par calibre.
- **Priorité** : Could · **Statut** : FAIT — livré sur `dev` par la PR #26 le 2026-09-03 ; critères validés par la suite Flutter complète et la recette manuelle.
- **Notes** : un prototype commun avec NT-100/101/130 a été abandonné le 2026-07-24 après recette UX ; respecter le [REX TAR & saisie rapide](rex-tar-saisie-rapide-2026-07-24.md). Le préremplissage ne doit ajouter aucune étape au parcours classique.

### NT-074 — Saisie séries plein écran + navigation rapide
- **Portée** : app · **Dépendances** : NT-002 · **Description** : Mode plein écran + next/prev pour réduire la friction de saisie (ancien P6).
- **Critères d'acceptation** : saisie plein écran ; navigation rapide entre séries. · **Priorité** : Could · **Statut** : À FAIRE. · **Notes** : inclut les idées de l'issue #5 — numpad/clavier rapide et navigation par swipe entre séries. Complété par le thème 13 (NT-130/NT-131).

### NT-075 — Onboarding + aide contextuelle
- **Portée** : app · **Dépendances** : — · **Description** : Mini-onboarding (3 écrans) + bouton « ? » contextuel (ancien P9).
- **Critères d'acceptation** : onboarding au 1er lancement ; aide sur Objectifs/Exercices/Sessions. · **Priorité** : Could · **Statut** : FAIT (2026-07-07, sprint S2) — `OnboardingScreen`/`OnboardingGate` (3 écrans, flag `onboarding_seen`, ré-accès via Paramètres > Aide), `HelpButton` sur Sessions, Objectifs, Exercices (+ hub Exercices & Objectifs).
- **Notes** : ajusté en recette S2 (2026-07-09) — texte écran 3 simplifié ; aide « Tendance des objectifs » thémable (plus de fond sombre en dur) ; aide « Mes sessions » alignée sur le nouveau comportement du bouton + (création selon l'onglet actif, appui long supprimé).

### NT-076 — Cache stats + compactage Hive
- **Portée** : app · **Dépendances** : NT-010 · **Description** : Cache mémoire des stats (TTL courte) + compactage Hive périodique (ancien P8).
- **Critères d'acceptation** : stats mises en cache ; compactage déclenché sur seuil. · **Priorité** : Could · **Statut** : À FAIRE.

---

## Thème 9 — Idées / hors-scope

| ID | Titre | Portée | Prio | Est | Statut |
|---|---|---|---|---|---|
| NT-090 | Thème ASCII Art | app | Won't-now | M | À FAIRE |
| NT-091 | Revoir les règles de sécurité FFTir | app | Won't-now | S | À FAIRE |
| NT-092 | Thèmes visuels (thème clair « France ») | app | Could | S | FAIT |

### NT-090 — Thème ASCII Art
- **Portée** : app · **Description** : Évaluer un thème visuel ASCII Art si une valeur produit est démontrée. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-091 — Revoir les règles de sécurité FFTir
- **Portée** : app · **Description** : Intégrer/mettre à jour les règles de sécurité FFTir. · **Priorité** : Won't-now · **Statut** : À FAIRE.

### NT-092 — Thèmes visuels (thème clair « France »)
- **Portée** : app · **Description** : Thématisation de l'app, dont le thème clair « France ». · **Priorité** : Could · **Statut** : FAIT — commit `feat: thème clair France`. · **Notes** : d'autres thèmes possibles (voir NT-090).

---

## Thème 10 — Disciplines officielles & TAR

*Aligner l'app sur les disciplines officielles FFTir — en priorité le TAR armes de poing 25 m (épreuves 830/831/832). Référentiel détaillé : [`details/referentiel-tar-25m.md`](details/referentiel-tar-25m.md) (règlement CNS TAR 2025-2026).*

| ID | Titre | Portée | VM | Prio | Est | Statut |
|---|---|---|---|---|---|---|
| NT-100 | Référentiel des disciplines officielles (TAR 25 m) | app | 5 | Must | M | À FAIRE |
| NT-101 | Sessions & séries typées discipline | app | 5 | Must | M | À FAIRE |
| NT-102 | Mode « match blanc » TAR | app | 4 | Should | L | À FAIRE |
| NT-103 | Comparaison aux grilles de classement FFTir | app | 4 | Could | M | À FAIRE |
| NT-104 | Stats & records par discipline | app | 4 | Should | M | À FAIRE |

### NT-100 — Référentiel des disciplines officielles (TAR 25 m)
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : —
- **Description** : Référentiel embarqué des épreuves officielles (830/831/832 en premier) — séquences essai/précision/vitesse, temps, cibles, scoring — pour que sessions, stats et coach parlent le langage de la discipline du tireur.
- **Critères d'acceptation** : référentiel versionné par saison (asset YAML, seed [`details/referentiel-tar-25m.md`](details/referentiel-tar-25m.md)) ; épreuves 830, 831, 832 décrites (séquences, temps, cibles, scoring — gong = 5 pts en 2025-2026) ; dimensions des cibles C50, cible vitesse 25 m et gongs exposées aux autres features (NT-111 notamment).
- **Priorité** : Must · **VM** : 5 · **Statut** : À FAIRE. · **Notes** : source règlement CNS TAR 2025-2026 (diffusion 12/01/2026) ; les règles évoluent chaque saison → champ `saison` obligatoire. Le prototype `117ca83` a été abandonné sans fusion le 2026-07-24 : voir le [REX TAR & saisie rapide](rex-tar-saisie-rapide-2026-07-24.md) avant toute reprise.

### NT-101 — Sessions & séries typées discipline
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-100, NT-001, NT-002
- **Description** : Rattacher une session à une épreuve officielle, avec pré-remplissage du format (séquences, nb coups, temps), pour des données comparables entre elles et exploitables par le coach.
- **Critères d'acceptation** : champ épreuve sur `ShootingSession` (additif Hive) ; type de séquence par série (essai/précision/vitesse) ; scoring adapté par série (pts/zone vs gongs tombés) ; les essais n'entrent pas dans les stats de score.
- **Priorité** : Must · **VM** : 5 · **Statut** : À FAIRE. · **Notes** : le modèle `Series` actuel ne couvre ni gongs, ni temps imparti, ni type de séquence — ajouts additifs uniquement (typeIds/index stables). Une nouvelle implémentation est conditionnée à la validation préalable des parcours décrits dans le [REX du prototype abandonné](rex-tar-saisie-rapide-2026-07-24.md).

### NT-102 — Mode « match blanc » TAR
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-101
- **Description** : Dérouler une épreuve au format officiel (séquences guidées, chrono, décompte de coups) pour s'entraîner en conditions de match.
- **Critères d'acceptation** : déroulé guidé 830/832 (essais 3 min → précision 7 min → vitesse 2×20 s puis 2×10 s) et 831 ; chrono par séquence ; score /200 calculé ; enregistrée comme session de catégorie match blanc.
- **Priorité** : Should · **VM** : 4 · **Statut** : À FAIRE.

### NT-103 — Comparaison aux grilles de classement FFTir
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-101
- **Description** : Situer les scores du tireur par rapport aux grilles de classement fédérales pour objectiver son niveau.
- **Critères d'acceptation** : à définir — dépend du sourcing des grilles.
- **Priorité** : Could · **VM** : 4 · **Statut** : À FAIRE. · **Notes** : les grilles par catégorie relèvent du **RGS FFTir**, pas du règlement TAR — sourcing dédié préalable.

### NT-104 — Stats & records par discipline
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-100, NT-010
- **Description** : Suivre la progression séparément par épreuve (pistolet auto vs revolver, 830 vs 831), sans mélanger des formats non comparables.
- **Critères d'acceptation** : filtres par épreuve dans stats et records ; records par épreuve ; le dashboard distingue les disciplines.
- **Priorité** : Should · **VM** : 4 · **Statut** : À FAIRE.

---

## Thème 11 — Analyse de cible (photo)

*Prolonge NT-005/NT-006 (thème 1) : exploiter la photo de cible pour le coaching. Approche **qualitative multimodale** retenue (décision 2026-07-13) ; l'extraction métrique CV (NT-006) reste en Icebox.*

| ID | Titre | Portée | VM | Prio | Est | Statut |
|---|---|---|---|---|---|---|
| NT-110 | Métadonnées cible & photo par série | app | 3 | Should | S | À FAIRE |
| NT-111 | Analyse qualitative de la photo par le coach (multimodal) | both | 4 | Should | M | À FAIRE |

### NT-110 — Métadonnées cible & photo par série
- **Thème** : Analyse de cible · **Portée** : app · **Dépendances** : NT-005
- **Description** : Taguer la photo (type de cible, distance, série associée) — sans métadonnées, aucune analyse fiable n'est possible.
- **Critères d'acceptation** : tag type de cible (C50, cible vitesse 25 m, gong — depuis NT-100), distance, série associée ; une photo non taguée reste une simple photo « mémoire ».
- **Priorité** : Should · **VM** : 3 · **Statut** : À FAIRE.

### NT-111 — Analyse qualitative de la photo par le coach (multimodal)
- **Thème** : Analyse de cible · **Portée** : both · **Dépendances** : NT-005, NT-110, NT-030, NT-100
- **Description** : Le serveur transmet la photo à un modèle multimodal (ex. Pixtral) avec les dimensions de zones du référentiel ; retour **qualitatif** (répartition, quadrant, hypothèse technique — ex. « groupé bas-gauche : anticipation du départ »), confronté à la saisie manuelle.
- **Critères d'acceptation** : endpoint proxy dédié (JWT requis, rate-limité comme NT-062) ; prompt serveur incluant les specs de cible (zones C50) ; l'analyse **confronte** photo et saisie (points/groupement) sans la remplacer ; dégradation propre si photo inexploitable.
- **Priorité** : Should · **VM** : 4 · **Statut** : À FAIRE. · **Notes** : préféré à la CV métrique (NT-006) — coût faible, valeur coaching réelle.

---

## Thème 12 — Coach : progression & génération

*Précise et décompose NT-033 (thème 4) et NT-023 (thème 3) : analyse transverse de la progression et génération d'entités par le coach, avec validation humaine systématique (le coach propose, le tireur dispose).*

| ID | Titre | Portée | VM | Prio | Est | Statut |
|---|---|---|---|---|---|---|
| NT-120 | Payload d'analyse transverse compact | app | — | Must (socle) | M | À FAIRE |
| NT-121 | Écran Coach : analyse de progression | both | 5 | Should | L | À FAIRE |
| NT-122 | Sortie coach structurée (JSON schema) | server | — | Must (socle) | M | À FAIRE |
| NT-123 | Coach propose des exercices | both | 5 | Should | L | À FAIRE |
| NT-124 | Coach propose des objectifs | both | 4 | Should | M | À FAIRE |
| NT-125 | Suivi des recommandations du coach | both | 4 | Could | L | À FAIRE |
| NT-126 | Plan d'entraînement | both | 5 | Could | L | À FAIRE |

### NT-120 — Payload d'analyse transverse compact
- **Thème** : Coach avancé · **Portée** : app · **Dépendances** : NT-101, NT-010
- **Description** : Pré-agréger côté app (le `stats_service` calcule déjà tout) et n'envoyer au serveur que les agrégats + les N dernières sessions détaillées, par discipline — maîtrise du coût tokens et de la latence, et évite l'analyse « choux et carottes » entre disciplines.
- **Critères d'acceptation** : fenêtre bornée et paramétrable (défaut : 10 sessions / 90 j) ; agrégats calculés localement ; taille de payload bornée et documentée.
- **Priorité** : Must (socle du thème) · **Statut** : À FAIRE. · **Notes** : conditionne NT-121.

### NT-121 — Écran Coach : analyse de progression
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-120, NT-030
- **Description** : Écran Coach dédié : analyse de la progression sur les dernières sessions (par discipline), axes de travail identifiés, actions suggérées. Reprend et remplace le périmètre UX de NT-033.
- **Critères d'acceptation** : analyse par discipline sur la fenêtre NT-120 ; axes de progression explicites ; suggestions d'actions ; `coach_screen.dart` remplace le placeholder « Coming soon ».
- **Priorité** : Should · **VM** : 5 · **Statut** : À FAIRE.

### NT-122 — Sortie coach structurée (JSON schema)
- **Thème** : Coach avancé · **Portée** : server · **Dépendances** : NT-031
- **Description** : Format de sortie structuré (structured outputs Mistral) conforme aux schémas `Exercise`/`Goal`, socle de toute génération d'entités par le coach.
- **Critères d'acceptation** : schémas JSON versionnés alignés sur les entités app ; validation serveur des sorties ; gestion des erreurs de validation (retry / fallback texte).
- **Priorité** : Must (socle du thème) · **Statut** : À FAIRE. · **Notes** : fait référence pour NT-023.

### NT-123 — Coach propose des exercices
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-122, NT-020
- **Description** : Depuis une analyse (session ou progression), le coach propose des exercices ; le tireur prévisualise, édite puis ajoute au catalogue. Précise NT-023.
- **Critères d'acceptation** : écran de prévisualisation/édition avant insertion ; rapprochement/déduplication avec le catalogue existant (anti-inflation d'exercices quasi-dupliqués) ; refus possible sans effet de bord.
- **Priorité** : Should · **VM** : 5 · **Statut** : À FAIRE.

### NT-124 — Coach propose des objectifs
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-122, NT-012
- **Description** : Même mécanique que NT-123 appliquée aux objectifs : objectif mesurable (métrique, comparateur, valeur cible) pré-rempli, aligné sur les axes de progression.
- **Critères d'acceptation** : proposition conforme au schéma `Goal` ; validation/édition avant création ; lien possible avec les exercices proposés (NT-021).
- **Priorité** : Should · **VM** : 4 · **Statut** : À FAIRE.

### NT-125 — Suivi des recommandations du coach
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-121
- **Description** : Le coach mémorise ses recommandations passées et mesure si elles ont été suivies et si elles ont porté — boucle de feedback qui évite les conseils répétitifs.
- **Critères d'acceptation** : à définir — recommandations persistées ; statut suivie/non suivie ; effet mesuré sur les métriques visées ; réinjection dans le contexte des analyses suivantes.
- **Priorité** : Could · **VM** : 4 · **Statut** : À FAIRE.

### NT-126 — Plan d'entraînement
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-123, NT-124
- **Description** : Générer un plan sur 2–4 semaines (sessions prévues + exercices) orienté vers un objectif TAR, en s'appuyant sur les entités existantes (sessions prévues, exercices, objectifs).
- **Critères d'acceptation** : à définir — plan validé par le tireur avant création des entités ; s'appuie sur NT-123/NT-124.
- **Priorité** : Could · **VM** : 5 · **Statut** : À FAIRE.

---

## Thème 13 — Saisie au stand

*Réduire la friction de saisie en conditions réelles au pas de tir. Complète NT-074 (thème 8) — le pré-remplissage est le premier gisement de gain.*

| ID | Titre | Portée | VM | Prio | Est | Statut |
|---|---|---|---|---|---|---|
| NT-130 | Templates de session | app | 4 | Must | S | À FAIRE |
| NT-131 | Session guidée au stand | app | 4 | Should | L | FAIT |
| NT-132 | Spike — saisie vocale d'une série | app | 2 | Could | S | À FAIRE |
| NT-133 | Sessions libres sans séries ni scores | app | 4 | Must | L | FAIT |
| NT-134 | Graphiques d'évolution intra-session | app | 3 | Could | M | À FAIRE |

### NT-130 — Templates de session
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-001, NT-073
- **Description** : Créer une session en 2 taps au stand depuis le « dernier setup » ou des favoris (arme, calibre, épreuve). Quick win : ~80 % du gain de friction pour un coût S.
- **Critères d'acceptation** : création depuis le dernier setup ; favoris nommés ; pré-remplissage arme/calibre/épreuve (épreuve : si NT-101 livré) ; compatible avec la normalisation calibres (NT-073).
- **Priorité** : Must · **VM** : 4 · **Statut** : À FAIRE.
- **Notes** : le prototype commun NT-100/101/073/130 a été abandonné le 2026-07-24, car le menu de templates ajoutait de la friction au parcours standard et employait des libellés ambigus. Repartir de `dev` après design ; voir le [REX TAR & saisie rapide](rex-tar-saisie-rapide-2026-07-24.md).

### NT-131 — Session guidée au stand
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-001, NT-002, NT-003, NT-004, NT-009, NT-022, NT-073, NT-133
- **Description** : Permettre au tireur de préparer puis de saisir directement une session détaillée au fil du tir dans un assistant dédié, sans créer au préalable une session prévue ni passer par un exercice servant artificiellement de gabarit. Le parcours privilégie les informations utiles au pas de tir, sauvegarde une séance interrompue sous forme de brouillon et la clôture en session réalisée standard.
- **Entrées de création** : dans l'écran Sessions, l'action flottante principale et immédiatement identifiable reste **« Au stand »** et ouvre directement l'assistant lorsqu'aucune séance n'est en cours. Un menu secondaire explicite, sans appui long caché, conserve les créations d'une session planifiée, d'une session réalisée via le formulaire détaillé actuel et d'une session libre NT-133. Lorsqu'un brouillon existe, il se reprend depuis sa carte dédiée ; l'action **« Au stand »** signale la séance existante sans changer de libellé ni permettre un second brouillon. Cette organisation supersède, à la livraison de NT-131, la disposition transitoire des actions imposée par NT-133.
- **Préparation de la séance** : un écran unique préremplit la date et l'heure courantes, le calibre depuis la préférence NT-073 lorsqu'elle existe et la prise depuis la préférence utilisateur. L'arme reste une saisie libre avec les suggestions du râtelier NT-009. L'utilisateur choisit la catégorie, zéro, un ou plusieurs exercices associés à l'ensemble de la session, le nombre de séries, le nombre de coups par série, la distance initiale et la prise. Les valeurs initiales proposées sont 10 séries de 5 coups et un récapitulatif affiche le volume total prévu. Le nombre de coups reste un entier libre : aucune borne à cinq ni règle métier FFTir spécifique n'est introduite. Un exercice associé ne détermine pas le nombre de séries et aucun champ distinct de « plan libre » n'est ajouté ; l'intention et le déroulement restent décrits dans la synthèse.
- **Brouillon et reprise** : commencer la séance persiste immédiatement une session détaillée dans un état de brouillon distinct des statuts prévue et réalisée. Le brouillon est affiché séparément et de manière identifiable en tête de l'historique des sessions réalisées, avec sa progression et une action **« Reprendre »**. Il survit à la fermeture de l'application, mais reste exclu des statistiques, objectifs, filtres de sessions réalisées et analyses Coach tant qu'il n'est pas clôturé. Une seule séance guidée peut être en cours à la fois ; elle peut être reprise ou abandonnée après confirmation. Une évolution de persistance respecte NT-072, reste additive et conserve la lecture des données et sauvegardes existantes.
- **Saisie guidée des séries** : l'assistant plein écran affiche la série courante, le nombre de séries prévues, les séries et coups enregistrés et le volume restant. Chaque série exige un nombre de coups entier, une distance entière, un score, un groupement et une prise ; le commentaire est facultatif et identifié comme recommandé pour améliorer l'analyse Coach. Les coups sont préremplis depuis la préparation. La première série reprend distance et prise de la préparation ; chaque série suivante hérite de la distance et de la prise de la précédente, tout en permettant de les modifier indépendamment. La distance reste libre et propose des raccourcis 15 m et 25 m. La navigation précédente/suivante permet de corriger une série et sauvegarde les données ; la saisie courante est également persistée de façon temporisée pour résister à une interruption.
- **Adaptation du programme** : l'utilisateur peut ajouter une série à tout moment. Il peut aussi terminer avant le nombre prévu ; après confirmation explicite, les séries encore vides sont retirées et seules les séries renseignées sont conservées. La dernière série conduit au récapitulatif plutôt que de créer implicitement une série supplémentaire. Quitter temporairement conserve le brouillon ; abandonner le supprime après confirmation.
- **Synthèse et clôture** : l'étape finale récapitule au minimum le nombre de séries réalisées, le total de coups, les distances utilisées, le total de points, le matériel et les exercices associés. La synthèse et la photo restent facultatives. **« Terminer la séance »** transforme atomiquement le brouillon en session réalisée standard, l'inclut dès lors dans les statistiques et le Coach, puis redirige vers la vue de consultation de la session enregistrée. Un échec de clôture conserve un brouillon reprenable et affiche une erreur exploitable sans perte des séries.
- **Compatibilité** : le wizard existant de conversion d'une session prévue en réalisée reste disponible pour les véritables séances planifiées. Les composants de saisie de séries peuvent être mutualisés, mais le nouveau parcours ne doit ni créer une session prévue intermédiaire ni exiger un exercice. Le changement d'arme ou de calibre entre les séries et le chrono de repos sont hors périmètre de cet item.
- **Critères de qualité** : tests du modèle et de la migration du brouillon, de son exclusion des agrégats et du Coach, de la reprise après redémarrage, de la clôture nominale et de son rollback en erreur ; widget tests de la préparation, des entrées de création, des valeurs issues des préférences et du râtelier, de l'héritage modifiable distance/prise, des raccourcis 15/25 m, de la navigation, de l'ajout et de la fin anticipée ; test de redirection vers le détail ; aide contextuelle et cahier de recette mis à jour ; rendu vérifié dans les deux thèmes.
- **Priorité** : Should · **VM** : 4 · **Estimation** : L · **Statut** : FAIT — fusionné sur `dev` par la PR #31 le 2026-09-04, après corrections de revue et de recette.
- **Notes** : cadrage UX validé le 2026-09-04 à partir de l'usage réel au stand. Livraison décidée dans le lot prioritaire courant, immédiatement après NT-133, dont NT-131 réorganise les actions de création. NT-074 reste complémentaire pour les optimisations génériques de clavier et de navigation ; NT-130 n'est pas un prérequis à ce parcours direct.

### NT-132 — Spike — saisie vocale d'une série
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : —
- **Description** : Vérifier la faisabilité de la saisie vocale en environnement stand (détonations, casque de protection) avant tout investissement.
- **Critères d'acceptation** : prototype + test en conditions réelles ; go/no-go documenté.
- **Priorité** : Could · **VM** : 2 · **Statut** : À FAIRE. · **Notes** : spike timeboxé ; aucune implémentation produit sans go.

### NT-133 — Sessions libres sans séries ni scores
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-001, NT-003, NT-005, NT-007, NT-017, NT-022, NT-073
- **Description** : Permettre au tireur de consigner rapidement une séance réalisée sans saisir de séries, de scores ni de groupements : une date, une arme, un calibre, un nombre total de tirs, une distance et une catégorie suffisent. La synthèse, la photo de cible et les exercices sont facultatifs. Dans l'interface, ce type est nommé **« Session libre »**.
- **Modèle métier et persistance** : `ShootingSession` devient le type racine abstrait commun ; les sessions actuelles sont représentées par `DetailedShootingSession` et le nouveau type par `SimpleShootingSession`, tous deux héritant de `ShootingSession`. `SimpleShootingSession` porte une date, une arme obligatoire, un calibre obligatoire, un `shotCount`, une distance, une synthèse facultative, une catégorie, une photo facultative et les IDs des exercices associés ; il ne porte ni séries, ni score, ni groupement, ni analyse Coach. Une session libre est toujours réalisée et ne peut pas être planifiée. Sa catégorie est choisie parmi les valeurs existantes `entraînement`, `match` et `test matériel`. Le nombre de tirs est un entier strictement positif et la distance est un nombre entier strictement positif exprimé en mètres.
- **Création et aide contextuelle** : dans l'écran Sessions, conserver le bouton flottant `+` actuel et son comportement direct pour créer une session détaillée réalisée ou prévue selon l'onglet actif ; ajouter à proximité une action flottante secondaire dédiée à la session libre, visible uniquement dans l'onglet des sessions réalisées. Les deux actions reprennent la même forme et la même structure, mais restent immédiatement distinguables par une couleur compatible avec le thème, une icône et une sémantique accessibles. Un label explicite peut être affiché lorsque l'espace disponible le permet et qu'il ne surcharge pas l'interface ; à défaut, tooltip et libellé d'accessibilité restent obligatoires. Aucun menu intermédiaire ni appui long n'est requis. L'aide contextuelle `?` de l'écran Sessions explique les deux actions et la différence entre session détaillée et session libre.
- **Saisie et cohérence des champs** : le calibre d'une session libre suit NT-073 : préremplissage éventuel depuis la préférence, autocomplétion sans autoremplacement et saisie libre conservée. Les formulaires de sessions libres et détaillées n'acceptent dorénavant que des distances entières strictement positives. Pour préserver les anciennes données et sauvegardes, le type numérique existant peut rester compatible avec les décimales historiques : aucune valeur passée n'est arrondie ou réécrite automatiquement, mais toute création ou modification applique la validation entière.
- **Consultation et cartes** : création, consultation, modification et suppression d'une session libre sont possibles, ainsi que l'ajout, le remplacement et la suppression d'une photo de cible selon la mécanique existante. Dans l'historique et les autres listes de sessions, le type est identifiable sans dépendre uniquement de la couleur : badge/libellé **« Libre »**, icône et accent visuel issus du `ColorScheme` du thème. Une carte de session libre affiche au minimum la date, l'arme, le calibre, la catégorie, le nombre de tirs, la distance et, le cas échéant, le nombre d'exercices associés ; elle n'affiche ni score, ni groupement, ni extrait de la synthèse. La synthèse et la photo restent consultables dans le détail. Les cartes détaillées conservent leur présentation actuelle et ne reçoivent pas de badge « Détaillée ». Les deux thèmes de l'application garantissent contraste et lisibilité.
- **Statistiques, filtres, objectifs et exercices** : le nombre de sessions, les objectifs fondés sur l'assiduité et les indicateurs d'assiduité incluent les deux sous-types réalisés, même sans exercice associé ; les statistiques de score, de groupement et toute métrique fondée sur les séries ignorent les sessions libres ; les métriques de volume additionnent le `shotCount` direct des sessions libres et les `shotCount` des séries des sessions détaillées. NT-017 inclut les tirs d'une session libre dans le compteur de son arme. Les statistiques par calibre appliquent la résolution NT-073 ; un calibre libre inconnu n'exclut pas la session des autres agrégats. Les filtres applicables aux sessions, notamment par catégorie et par exercice, fonctionnent avec les deux sous-types. Une session libre accepte zéro, un ou plusieurs exercices associés selon la mécanique existante.
- **Import, export et rétrocompatibilité** : le format JSON exporté contient un discriminant stable `sessionType` valant `detailed` ou `simple`. Les anciennes données Hive et les anciens exports dépourvus de discriminant sont relus comme des sessions détaillées sans perte de données. L'import et l'export acceptent les sauvegardes contenant uniquement des sessions historiques ou un mélange des deux types ; un cycle export puis import conserve le sous-type et tous les champs de chaque session. L'évolution du format reste additive ; un discriminant inconnu produit une erreur explicite sans import partiel ni altération des données locales.
- **Coach IA** : une session libre ne peut pas être envoyée à l'analyse Coach et son écran de détail ne propose pas cette action ; l'absence de séries, score et groupement ne doit produire ni payload artificiel ni donnée de substitution.
- **Critères de qualité** : migration de schéma et test de migration ; tests de sérialisation des deux sous-types et des données historiques sans discriminant ; tests des champs obligatoires, des catégories et des validations `shotCount`/distance entière ; tests de la photo et de l'absence d'analyse Coach ; tests des agrégats, objectifs d'assiduité, compteurs NT-017 et exclusion des métriques de séries ; widget tests des deux actions flottantes, de l'onglet Prévues, des cartes dans les deux thèmes et de l'aide contextuelle ; cahier de recette mis à jour.
- **Priorité** : Must · **VM** : 4 · **Estimation** : L · **Statut** : FAIT — fusionné sur `dev` par la PR #27 le 2026-09-03.
- **Notes** : `SimpleShootingSession` est le nom technique retenu ; « Session libre » est exclusivement le label utilisateur. Le champ de commentaires réutilise la notion et le libellé de **synthèse** des sessions détaillées. Préserver le parcours actuel du `+` est non négociable pour la livraison autonome de NT-133, conformément au [REX TAR & saisie rapide](rex-tar-saisie-rapide-2026-07-24.md) ; l'organisation des actions pourra ensuite être remplacée par le parcours validé de NT-131.

### NT-134 — Graphiques d'évolution intra-session
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-131, NT-011
- **Description** : Compléter le récapitulatif d'une session détaillée par une lecture visuelle de l'évolution du score et du groupement au fil des séries, afin d'identifier rapidement une progression, une stabilisation ou une dégradation pendant la séance.
- **Critères d'acceptation** : afficher les séries dans leur ordre de tir ; rendre les évolutions de score et de groupement lisibles sans suggérer une comparaison directe entre deux unités différentes ; gérer les séries incomplètes et le nombre minimal de points ; proposer le graphique dans le récapitulatif de clôture et dans la vue de consultation de la session enregistrée ; garantir lisibilité, contraste et accessibilité dans les deux thèmes.
- **Priorité** : Could · **VM** : 3 · **Estimation** : M · **Statut** : À FAIRE.
- **Notes** : cadrage UX requis avant développement, notamment sur un graphique combiné ou deux graphiques séparés, les échelles, les unités, les seuils d'affichage et la valeur apportée par rapport aux statistiques existantes. Cette évolution ne bloque pas NT-131.

---

## Backlog priorisé

> **Plan historique.** Ce bloc reflète la planification établie avant
> l'enrichissement des thèmes 10–13 et contient plusieurs items désormais
> `FAIT`. Le plan courant de priorisation métier, dépendances et sprints
> livrables est maintenu dans [`plan-sprints.md`](plan-sprints.md).

> **Dernière mise à jour** : 2026-07-07.
> Découpage en sprints de 2 semaines. Chaque sprint livre un produit (app +
> serveur) cohérent, fonctionnel, sans régression. Les items FAIT ne figurent pas
> ici. Les Won't-now sont en Icebox.
>
> **Contexte** : dev solo (Senior + agentic dev Claude Code), vélocité élevée.
> **Contrainte** : beta demo à la FFTir début août 2026 — S1 et S2 doivent être
> livrés avant cette date.

### Vue synthétique

| Sprint | Thème | Items | Portée | Deadline |
|---|---|---|---|---|
| **S1** | Sécurité & Qualité | NT-061, NT-065, NT-066, NT-051 | both | **Pré-demo** |
| **S2** | Demo-ready | NT-075, NT-032 | both | **Pré-demo** |
| **S3** | Robustesse serveur | NT-055, NT-054, NT-048, NT-053 | server | Post-demo |
| **S4** | Enrichissement fonctionnel | NT-005, NT-025, NT-073, NT-014 | app | — |
| **S5** | UX & Performance | NT-074, NT-076 | app | — |
| **S6** | Fonctionnalités avancées | NT-033, NT-023, NT-024, NT-015, NT-044 | both | — |
| **Icebox** | Won't-now / pas prioritaire | NT-006, NT-045, NT-046, NT-047, NT-090, NT-091 | — | — |

> **Révision 2026-07-13** : les thèmes 10–13 ne sont pas encore ventilés en
> sprints. Ordre recommandé après S4 (qui contient déjà NT-005, remonté Must) :
> **NT-133** (socle polymorphe et session libre), **NT-130** (quick win), puis
> **NT-100/NT-101** (socle disciplines), puis
> **NT-120/NT-122** (socles coach) qui débloquent NT-121/NT-123/NT-124 en
> parallèle. En S6, NT-033 et NT-023 sont remplacés par leurs déclinaisons
> NT-120→NT-124 ; NT-110/NT-111 s'insèrent après NT-005 + NT-100.

---

### Sprint 1 — Sécurité & Qualité — PRÉ-DEMO

*Objectif : éliminer la dette sécurité (le seul Must restant) et poser la base
qualité. Prérequis à la beta demo FFTir.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-061 | Coach connecté uniquement — retrait clé Mistral client + rotation | both | Must | M |
| 2 | NT-065 | Restreindre CORS par environnement | server | Should | S |
| 3 | NT-066 | Vérification du nonce Google | server | Should | S |
| 4 | NT-051 | Analyse statique & lint (durcir) | app | Should | S |

**Justification** :
- NT-061 est le seul item **Must** non terminé ; il ferme la faille clé Mistral
  côté client. **Bloquant** pour la demo.
- NT-065 et NT-066 sont des quick-wins sécurité (S) identifiés dans l'audit.
- NT-051 stabilise la qualité statique avant d'empiler des features.

**Critère de fin de sprint** : `flutter analyze` zéro warning, coach
inaccessible sans authentification (message clair), CORS restreint en prod,
nonce Google vérifié, clé Mistral historique rotée.

### Sprint 2 — Demo-ready — PRÉ-DEMO

*Objectif : rendre l'app prête pour la demo FFTir — première impression soignée
et coach différenciant.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-075 | Onboarding + aide contextuelle | app | Could → **Must** (demo) | M |
| 2 | NT-032 | Multi-personas coach (neutre / cool) | both | Should | M |

**Justification** :
- NT-075 est **critique pour la demo** : les membres FFTir découvriront l'app
  pour la première fois. Un mini-onboarding (3 écrans) + aide contextuelle sur
  Objectifs/Exercices/Sessions guide la prise en main.
- NT-032 a du scaffolding existant (`prompt_variant`, `_VARIANT_FILES`) et rend
  le coach plus vivant en demo. Le ton « cool » est un atout marketing.

**Critère de fin de sprint** : onboarding au 1er lancement, aide « ? »
contextuelle, ≥ 2 tons de coach sélectionnables. **App buildée en APK de demo.**

### Sprint 3 — Robustesse serveur

*Objectif : rendre le serveur production-ready (CI, tests, auth durable,
observabilité). Fondation avant d'ajouter des features serveur post-demo.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-055 | CI serveur (tests + couverture) | server | Should | S |
| 2 | NT-054 | Tests OAuth mockés (providers externes) | server | Should | M |
| 3 | NT-048 | Refresh tokens + rotation | server | Should | M |
| 4 | NT-053 | Logging structuré + tracing | server | Should | M |

**Justification** :
- NT-055 (CI) est la fondation : sans CI, aucune PR serveur n'est fiable.
- NT-054 sécurise l'auth qui est le point d'entrée de tout le coach.
- NT-048 améliore l'UX (sessions longues sans re-login) — retour probable de la
  demo FFTir.
- NT-053 donne de la visibilité en production, d'autant plus utile si la demo
  génère du trafic.

**Critère de fin de sprint** : pipeline CI vert, providers OAuth mockés, refresh
tokens fonctionnels, logs structurés en JSON.

### Sprint 4 — Enrichissement fonctionnel

*Objectif : améliorer le carnet de tir au quotidien.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-005 | Attacher une photo de la cible | app | Could | M |
| 2 | NT-025 | Niveau de difficulté d'exercice | app | Could | S |
| 3 | NT-073 | Normalisation calibres + dernier calibre utilisé | app | Could | S |
| 4 | NT-014 | Comparatif glissant 30j vs 90j + sparkline | app | Could | M |

**Justification** :
- NT-005 enrichit visuellement le carnet (photo = mémoire visuelle) et prépare
  NT-006 (analyse image, Icebox).
- NT-025 et NT-073 sont des quick-wins (S) qui améliorent l'hygiène de données.
- NT-014 apporte de la profondeur aux statistiques existantes.

**Critère de fin de sprint** : photos attachées aux sessions, exercices
filtrables par difficulté, calibres normalisés avec pré-remplissage, sparklines
sur le dashboard.

### Sprint 5 — UX & Performance

*Objectif : réduire la friction utilisateur et préparer la montée en volumétrie.*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-074 | Saisie séries plein écran + navigation rapide | app | Could | M |
| 2 | NT-076 | Cache stats + compactage Hive | app | Could | M |

**Justification** :
- NT-074 réduit la friction du cœur de métier (saisie de tir).
- NT-076 anticipe la dégradation de performance avec la volumétrie.

**Critère de fin de sprint** : saisie séries plein écran, stats cachées avec
TTL, compactage Hive automatique.

### Sprint 6 — Fonctionnalités avancées

*Objectif : boucler les features avancées. NT-033 pourra être affiné entre-temps
(scope, UX, prompts).*

| Ordre | ID | Titre | Portée | Prio | Est |
|---|---|---|---|---|---|
| 1 | NT-033 | Écran Coach : analyse transverse multi-sessions | both | Should | L |
| 2 | NT-023 | Création d'exercice par le coach | both | Could | L |
| 3 | NT-024 | Stats d'exécution exercices (fenêtres glissantes) | app | Could | M |
| 4 | NT-015 | Recommandations croisées Objectifs ⇄ Exercices | app | Could | M |
| 5 | NT-044 | Authentification OAuth Facebook (partie app) | both | Could | M |

**Justification** :
- NT-033 est repoussée ici volontairement : le scope et les prompts ne sont pas
  encore définis. Le temps post-demo permet de mûrir la vision.
- NT-023 dépend du format de sortie structuré du coach (à définir avec NT-033).
- NT-024 et NT-015 exploitent les liens exercices ↔ sessions/objectifs déjà en
  place.
- NT-044 a une valeur marginale et reste **non prioritaire** : le code serveur
  existe mais n'est pas validé de bout en bout (tests mockés seulement) et le
  bouton app manque.

**Critère de fin de sprint** : écran Coach multi-sessions fonctionnel, coach
proposant des exercices structurés, stats d'usage, recommandations croisées,
login Facebook disponible.

### Icebox (Won't-now / pas prioritaire)

*Items explicitement écartés pour le moment. À réexaminer lors d'un futur cycle
de planification.*

| ID | Titre | Raison |
|---|---|---|
| NT-006 | Analyse d'image de la cible | Coûteux (vision par ordinateur), dépend de NT-005 |
| NT-045 | Stats publiques / partage de profil | Pas de demande utilisateur identifiée |
| NT-046 | Gamification | Scope large, pas prioritaire |
| NT-047 | Apple Sign In | Requis uniquement pour publication iOS avec login social |
| NT-090 | Thème ASCII Art | Cosmétique, pas de valeur métier |
| NT-091 | Règles de sécurité FFTir | À instruire quand le besoin se précise |

### Décisions prises (2026-07-07)

| Sujet | Décision |
|---|---|
| NT-071 (Postgres) | **Décision annulée le 2026-09-02** — le disque SQLite éphémère de Render entraîne la perte des utilisateurs ; NT-071 est désormais Must. |
| NT-033 (Coach multi-sessions) | **Repoussé en S6** — nice-to-have, scope et prompts pas encore définis. |
| Cadence | Senior + agentic dev (Claude Code), sprints de 2 semaines. |
| Demo FFTir | **Début août 2026** — S1 (sécurité) et S2 (onboarding + multi-personas) sont bloquants. |
| NT-075 (Onboarding) | **Remonté en S2** — critique pour la première impression en demo FFTir. |

### Décisions prises (2026-07-13)

| Sujet | Décision |
|---|---|
| Priorité produit | Progression sur les **disciplines officielles**, en premier lieu le **TAR armes de poing 25 m** (épreuves 830/831/832). |
| NT-005 (photo) | Remonté **Could → Must** — socle du thème 11 ; livré le 2026-07-17 (PR #12). |
| Analyse photo | Approche **qualitative multimodale** (NT-111) retenue ; NT-006 (CV métrique) maintenu en Icebox, à réévaluer après retour d'usage. |
| Référentiel TAR | Versionné par saison ; seed extrait du règlement CNS TAR 2025-2026 → [`details/referentiel-tar-25m.md`](details/referentiel-tar-25m.md). |

### Décisions prises (2026-09-02)

| Sujet | Décision |
|---|---|
| NT-071 (Postgres) | **Should → Must, puis FAIT** — migration livrée dans la release produit v0.6.0 (NexTarget-server v0.3.0) : Neon Postgres Free (`nextarget-prod`, Frankfurt), Alembic, bascule sur une base vide et reconnexion des utilisateurs. Voir l'issue serveur [#9](https://github.com/clementseguy/NexTarget-server/issues/9). |
| Estimation | Ajout d'une **Valeur métier (VM 1–5)** sur les thèmes 10+, en complément de MoSCoW + S/M/L (dev solo + agentic : le facteur limitant est la valeur/le risque, pas l'effort). |
| NT-033 / NT-023 | Précisés et décomposés par les items du **thème 12** (NT-120→NT-126), qui font référence. |
