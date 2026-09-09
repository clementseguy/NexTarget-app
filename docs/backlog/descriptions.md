# NexTarget — Description des US actives

Ce fichier contient la définition fonctionnelle des US présentes dans
[`backlog-unifie.md`](backlog-unifie.md). Le statut et la priorité P0–P3 n'y
sont volontairement pas reproduits.

## Thème 1 — Carnet de tir (Sessions & Séries)

<a id="NT-006"></a>
### NT-006 — Analyse d'image de la cible
- **Thème** : Carnet de tir
- **Description** : Analyser la photo (dispersion, score total) pour confronter aux commentaires et enrichir l'analyse coach.
- **Portée** : both · **Dépendances** : NT-005, NT-030
- **Critères d'acceptation** : à définir — extraction dispersion/score ; résultat versé dans le contexte envoyé au coach.
- **Notes** : vision par ordinateur, coûteux ; probablement côté serveur. Décision 2026-07-13 : l'analyse **qualitative multimodale** (NT-111) est retenue en premier ; NT-006 reste en Icebox, à réévaluer après retour d'usage de NT-111.

## Thème 2 — Statistiques & Objectifs

<a id="NT-015"></a>
### NT-015 — Recommandations croisées Objectifs ⇄ Exercices
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012, NT-021
- **Description** : Suggérer des exercices selon les objectifs en retard, et inversement.
- **Critères d'acceptation** : à définir — au moins une reco pertinente affichée selon l'état des objectifs.

<a id="NT-016"></a>
### NT-016 — Objectifs enrichis : statuts étendus, journal, vue détail
- **Thème** : Statistiques & Objectifs · **Portée** : app · **Dépendances** : NT-012
- **Description** : Cycle de vie d'objectif plus riche que l'actuel `active/achieved/failed` : statuts étendus (ex. planned/in_progress/achieved/abandoned), journal des changements de statut (avec dates), vue détail dédiée.
- **Critères d'acceptation** : statuts étendus persistés (migration Hive + adapters régénérés) ; historique des transitions consultable ; écran détail d'un objectif.
- **Notes** : repris de l'issue GitHub #5 (tracking v0.3), 2026-07-09. Attention : champ Hive additif uniquement (typeIds/index stables).

## Thème 3 — Exercices

<a id="NT-024"></a>
### NT-024 — Stats d'exécution (fenêtres glissantes)
- **Thème** : Exercices · **Portée** : app · **Dépendances** : NT-022
- **Description** : Compter l'usage des exercices (`usageCount`, `lastPerformedAt`) puis produire des statistiques par fenêtres glissantes.
- **Critères d'acceptation** : incrément d'usage à chaque session liée ; date de dernière exécution ; stats sur fenêtre glissante.

## Thème 4 — Coach IA

<a id="NT-034"></a>
### NT-034 — Affiner les prompts des personas coach
- **Thème** : Coach IA · **Portée** : server · **Dépendances** : NT-032
- **Description** : Itérer sur le contenu des templates `coach_neutre.yaml` / `coach_cool.yaml` (qualité, différenciation des tons, format de sortie) à partir des retours d'usage réels.
- **Critères d'acceptation** : à définir — prompts revus et validés en recette sur des sessions réelles ; différence de ton nette entre personas ; règles de mesurabilité conservées.
- **Notes** : créé suite à la recette S2 (2026-07-09). Aucun changement de contrat d'API.

---

## Thème 5 — Auth & Compte

<a id="NT-044"></a>
### NT-044 — Authentification OAuth Facebook
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Se connecter avec Facebook.
- **Critères d'acceptation** : serveur `/auth/facebook/*` **validé de bout en bout** contre une vraie app Facebook (au-delà des tests mockés) ; **app : bouton Facebook câblé** (manquant aujourd'hui).
- **Notes** : côté serveur, le **code est présent** (`api/auth_facebook.py` : `/start` + `/callback`, échange de code, Graph API) mais **reste à valider** de bout en bout : couvert uniquement par des tests mockés (`tests/test_oauth_flows.py`), pas encore éprouvé contre une vraie app Facebook (credentials non configurés). Côté app, aucun bouton Facebook. Le flow doit être câblé dans l'app et validé contre une vraie app Facebook. Arbitrage 2026-07-07 : « plus tard, optionnelle ».

<a id="NT-045"></a>
### NT-045 — Stats publiques / partage de profil
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Exposer (en option) des stats publiques du tireur.
- **Critères d'acceptation** : à définir.

<a id="NT-046"></a>
### NT-046 — Gamification
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-042
- **Description** : Système de gamification (badges, niveaux…).
- **Critères d'acceptation** : à définir.

<a id="NT-047"></a>
### NT-047 — Apple Sign In
- **Thème** : Auth & Compte · **Portée** : both · **Dépendances** : NT-040
- **Description** : Provider Apple (requis pour publication iOS si autres logins sociaux présents).
- **Critères d'acceptation** : à définir. · **Notes** : roadmap serveur v0.2.

## Thème 8 — Plateforme & Déploiement

<a id="NT-074"></a>
### NT-074 — Saisie séries plein écran + navigation rapide
- **Thème** : Plateforme & Déploiement · **Portée** : app · **Dépendances** : NT-002 · **Description** : Mode plein écran + next/prev pour réduire la friction de saisie.
- **Critères d'acceptation** : saisie plein écran ; navigation rapide entre séries. · **Notes** : inclut les idées de l'issue #5 — numpad/clavier rapide et navigation par swipe entre séries. Complété par le thème 13 (NT-130/NT-131).

<a id="NT-076"></a>
### NT-076 — Cache stats + compactage Hive
- **Thème** : Plateforme & Déploiement · **Portée** : app · **Dépendances** : NT-010 · **Description** : Cache mémoire des stats (TTL courte) + compactage Hive périodique.
- **Critères d'acceptation** : stats mises en cache ; compactage déclenché sur seuil.

## Thème 9 — Idées / hors-scope

<a id="NT-090"></a>
### NT-090 — Thème ASCII Art
- **Thème** : Idées / hors-scope · **Portée** : app · **Description** : Évaluer un thème visuel ASCII Art si une valeur produit est démontrée.

<a id="NT-091"></a>
### NT-091 — Revoir les règles de sécurité FFTir
- **Thème** : Idées / hors-scope · **Portée** : app · **Description** : Intégrer/mettre à jour les règles de sécurité FFTir.

## Thème 10 — Disciplines officielles & TAR

<a id="NT-100"></a>
### NT-100 — Référentiel des disciplines officielles (TAR 25 m)
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : —
- **Description** : Référentiel embarqué des épreuves officielles (830/831/832 en premier) — séquences essai/précision/vitesse, temps, cibles, scoring — pour que sessions, stats et coach parlent le langage de la discipline du tireur.
- **Critères d'acceptation** : référentiel versionné par saison (asset YAML, seed [`details/referentiel-tar-25m.md`](details/referentiel-tar-25m.md)) ; épreuves 830, 831, 832 décrites (séquences, temps, cibles, scoring — gong = 5 pts en 2025-2026) ; dimensions des cibles C50, cible vitesse 25 m et gongs exposées aux autres features (NT-111 notamment).
- **VM** : 5 · **Notes** : source règlement CNS TAR 2025-2026 (diffusion 12/01/2026) ; les règles évoluent chaque saison → champ `saison` obligatoire. Le prototype `117ca83` a été abandonné sans fusion le 2026-07-24 : voir le [REX TAR & saisie rapide](details/rex-tar-saisie-rapide-2026-07-24.md) avant toute reprise.

<a id="NT-101"></a>
### NT-101 — Sessions & séries typées discipline
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-100, NT-001, NT-002
- **Description** : Rattacher une session à une épreuve officielle, avec pré-remplissage du format (séquences, nb coups, temps), pour des données comparables entre elles et exploitables par le coach.
- **Critères d'acceptation** : champ épreuve sur `ShootingSession` (additif Hive) ; type de séquence par série (essai/précision/vitesse) ; scoring adapté par série (pts/zone vs gongs tombés) ; les essais n'entrent pas dans les stats de score.
- **VM** : 5 · **Notes** : le modèle `Series` actuel ne couvre ni gongs, ni temps imparti, ni type de séquence — ajouts additifs uniquement (typeIds/index stables). Une nouvelle implémentation est conditionnée à la validation préalable des parcours décrits dans le [REX du prototype abandonné](details/rex-tar-saisie-rapide-2026-07-24.md).

<a id="NT-102"></a>
### NT-102 — Mode « match blanc » TAR
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-101
- **Description** : Dérouler une épreuve au format officiel (séquences guidées, chrono, décompte de coups) pour s'entraîner en conditions de match.
- **Critères d'acceptation** : déroulé guidé 830/832 (essais 3 min → précision 7 min → vitesse 2×20 s puis 2×10 s) et 831 ; chrono par séquence ; score /200 calculé ; enregistrée comme session de catégorie match blanc.
- **VM** : 4

<a id="NT-103"></a>
### NT-103 — Comparaison aux grilles de classement FFTir
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-101
- **Description** : Situer les scores du tireur par rapport aux grilles de classement fédérales pour objectiver son niveau.
- **Critères d'acceptation** : à définir — dépend du sourcing des grilles.
- **VM** : 4 · **Notes** : les grilles par catégorie relèvent du **RGS FFTir**, pas du règlement TAR — sourcing dédié préalable.

<a id="NT-104"></a>
### NT-104 — Stats & records par discipline
- **Thème** : Disciplines & TAR · **Portée** : app · **Dépendances** : NT-100, NT-010
- **Description** : Suivre la progression séparément par épreuve (pistolet auto vs revolver, 830 vs 831), sans mélanger des formats non comparables.
- **Critères d'acceptation** : filtres par épreuve dans stats et records ; records par épreuve ; le dashboard distingue les disciplines.
- **VM** : 4

---

## Thème 11 — Analyse de cible (photo)

<a id="NT-110"></a>
### NT-110 — Métadonnées cible & photo par série
- **Thème** : Analyse de cible · **Portée** : app · **Dépendances** : NT-005
- **Description** : Taguer la photo (type de cible, distance, série associée) — sans métadonnées, aucune analyse fiable n'est possible.
- **Critères d'acceptation** : tag type de cible (C50, cible vitesse 25 m, gong — depuis NT-100), distance, série associée ; une photo non taguée reste une simple photo « mémoire ».
- **VM** : 3

<a id="NT-111"></a>
### NT-111 — Analyse qualitative de la photo par le coach (multimodal)
- **Thème** : Analyse de cible · **Portée** : both · **Dépendances** : NT-005, NT-110, NT-030, NT-100
- **Description** : Le serveur transmet la photo à un modèle multimodal (ex. Pixtral) avec les dimensions de zones du référentiel ; retour **qualitatif** (répartition, quadrant, hypothèse technique — ex. « groupé bas-gauche : anticipation du départ »), confronté à la saisie manuelle.
- **Critères d'acceptation** : endpoint proxy dédié (JWT requis, rate-limité comme NT-062) ; prompt serveur incluant les specs de cible (zones C50) ; l'analyse **confronte** photo et saisie (points/groupement) sans la remplacer ; dégradation propre si photo inexploitable.
- **VM** : 4 · **Notes** : préféré à la CV métrique (NT-006) — coût faible, valeur coaching réelle.

---

## Thème 12 — Coach : progression & génération

<a id="NT-120"></a>
### NT-120 — Payload d'analyse transverse compact
- **Annulation** : approche obsolète, remplacée par NT-121, NT-153 et NT-156.
- **Thème** : Coach avancé · **Portée** : app · **Dépendances** : NT-101, NT-010
- **Description** : Pré-agréger côté app (le `stats_service` calcule déjà tout) et n'envoyer au serveur que les agrégats + les N dernières sessions détaillées, par discipline — maîtrise du coût tokens et de la latence, et évite l'analyse « choux et carottes » entre disciplines.
- **Critères d'acceptation** : fenêtre bornée et paramétrable (défaut : 10 sessions / 90 j) ; agrégats calculés localement ; taille de payload bornée et documentée.
- **Notes** : les données nécessaires sont transmises lors d'une analyse autorisée par NT-153. Le serveur persiste les sessions reçues et calcule lui-même les métriques ; NT-121 reste la macro-US du Coach de progression.

<a id="NT-121"></a>
### NT-121 — MVP Coach de progression transverse
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-030, NT-152 à NT-157
- **Description** : Macro-US du MVP Coach de progression : analyser plusieurs sessions comparables, choisir une priorité explicable, créer ou réviser un objectif de coaching, sélectionner un exercice validé et suivre un plan exprimé en nombre de sessions. Reprend et remplace le périmètre UX de NT-033.
- **Critères d'acceptation** : à détailler dans des US dédiées avant développement ; `coach_screen.dart` remplace le placeholder « Coming soon » ; le Coach de progression reste seul autorisé à créer ou modifier le plan.
- **VM** : 5
- **Notes** : hors de la release préparatoire NT-152 à NT-157. La démo constitue un sous-ensemble contrôlé de cette macro-US et ne doit pas figer toutes les règles du MVP.

<a id="NT-122"></a>
### NT-122 — Sortie coach structurée (JSON schema)
- **Thème** : Coach avancé · **Portée** : server · **Dépendances** : NT-031
- **Description** : Définir des contrats de sortie structurés, distincts et versionnés pour le Coach de session et le Coach de progression. Les décisions métier validées sont séparées du texte finalement présenté à l'utilisateur.
- **Critères d'acceptation** : schéma JSON versionné pour chaque type d'analyse ; validation serveur stricte ; champs et valeurs contrôlés ; gestion des sorties invalides par retry borné ou fallback déterministe.
- **Notes** : NT-156 introduit le premier contrat concret du Coach de session et NT-157 sépare sa décision de sa reformulation. L'alignement commun avec le Coach de progression sera finalisé lors du découpage de NT-121.

<a id="NT-123"></a>
### NT-123 — Coach de progression : sélectionner un exercice
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-020, NT-121, NT-122
- **Description** : Le Coach de progression sélectionne et paramètre un exercice provenant d'un catalogue fermé et validé. Le Coach de session ne propose ni ne crée d'exercice.
- **Critères d'acceptation** : catalogue versionné ; sélection limitée aux exercices actifs et compatibles avec la priorité ; protocole, prérequis, mesure, critère de réussite et variante disponibles ; aucune génération libre d'exercice dans le MVP.
- **VM** : 5
- **Notes** : remplace l'orientation historique de NT-023 fondée sur la création d'un exercice par le Coach.

<a id="NT-124"></a>
### NT-124 — Coach de progression : proposer un objectif
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-012, NT-121, NT-122
- **Description** : Le Coach de progression propose un objectif de coaching mesurable, aligné sur la priorité retenue et distinct de l'intention personnelle de l'utilisateur.
- **Critères d'acceptation** : à revoir avant développement — compétence, métrique, référence initiale, valeur cible, nombre de sessions et justification structurés.
- **VM** : 4
- **Notes** : la pertinence de conserver cette capacité comme US autonome et son articulation avec le modèle actuel `Goal` restent à décider.

<a id="NT-125"></a>
### NT-125 — Suivi des prescriptions et tentatives
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-121, NT-154
- **Description** : Persister chaque prescription, les sessions qui tentent de la suivre et leur résultat afin que le Coach de progression puisse poursuivre, adapter ou arrêter un plan sans répéter des conseils sans justification.
- **Critères d'acceptation** : prescription et tentative reliées aux sessions concernées ; exercice réalisé et protocole suivi pris en compte ; résultat réussi, échoué ou non évaluable ; métriques et décisions conservées pour les analyses suivantes.
- **VM** : 4

<a id="NT-126"></a>
### NT-126 — Plan d'entraînement
- **Thème** : Coach avancé · **Portée** : both · **Dépendances** : NT-121, NT-123, NT-124, NT-125
- **Description** : Construire un plan de coaching composé d'un objectif mesurable, d'un exercice validé, d'un critère de réussite et d'un nombre de sessions. Le plan ne dépend ni d'un calendrier imposé ni du périmètre TAR.
- **Critères d'acceptation** : une seule priorité et une seule prescription principale actives ; durée exprimée en nombre de sessions ; référence initiale et critère conservés ; transitions poursuivre, adapter, clôturer ou recommander un encadrement humain justifiées par les tentatives.
- **VM** : 5

---

## Thème 13 — Saisie au stand

<a id="NT-130"></a>
### NT-130 — Templates de session
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-001, NT-073
- **Description** : Créer une session en 2 taps au stand depuis le « dernier setup » ou des favoris (arme, calibre, épreuve). Quick win : ~80 % du gain de friction pour un coût S.
- **Critères d'acceptation** : création depuis le dernier setup ; favoris nommés ; pré-remplissage arme/calibre/épreuve (épreuve : si NT-101 livré) ; compatible avec la normalisation calibres (NT-073).
- **VM** : 4
- **Notes** : le prototype commun NT-100/101/073/130 a été abandonné le 2026-07-24, car le menu de templates ajoutait de la friction au parcours standard et employait des libellés ambigus. Repartir de `dev` après design ; voir le [REX TAR & saisie rapide](details/rex-tar-saisie-rapide-2026-07-24.md).

<a id="NT-132"></a>
### NT-132 — Spike — saisie vocale d'une série
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : —
- **Description** : Vérifier la faisabilité de la saisie vocale en environnement stand (détonations, casque de protection) avant tout investissement.
- **Critères d'acceptation** : prototype + test en conditions réelles ; go/no-go documenté.
- **VM** : 2 · **Notes** : spike timeboxé ; aucune implémentation produit sans go.

<a id="NT-134"></a>
### NT-134 — Graphiques d'évolution intra-session
- **Thème** : Saisie au stand · **Portée** : app · **Dépendances** : NT-131, NT-011
- **Description** : Compléter le récapitulatif d'une session détaillée par une lecture visuelle de l'évolution du score et du groupement au fil des séries, afin d'identifier rapidement une progression, une stabilisation ou une dégradation pendant la séance.
- **Critères d'acceptation** : afficher les séries dans leur ordre de tir ; rendre les évolutions de score et de groupement lisibles sans suggérer une comparaison directe entre deux unités différentes ; gérer les séries incomplètes et le nombre minimal de points ; proposer le graphique dans le récapitulatif de clôture et dans la vue de consultation de la session enregistrée ; garantir lisibilité, contraste et accessibilité dans les deux thèmes.
- **VM** : 3
- **Notes** : cadrage UX requis avant développement, notamment sur un graphique combiné ou deux graphiques séparés, les échelles, les unités, les seuils d'affichage et la valeur apportée par rapport aux statistiques existantes. Cette évolution ne bloque pas NT-131.

---

## Thème 14 — Finitions UX

<a id="NT-151"></a>
### NT-151 — Harmoniser et densifier les cartes d'exercice
- **Thème** : Finitions UX · **Portée** : app · **Dépendances** : NT-003, NT-020, NT-025, NT-027
- **Description** : Repenser la hiérarchie visuelle des cartes d'exercice pour
  les rapprocher des cartes Sessions et Séries, donner davantage de place aux
  informations utiles et réduire l'emprise des actions sans en supprimer.
- **Critères d'acceptation** :
  - un inventaire compare explicitement les cartes Exercices, Sessions et Séries et identifie les conventions actives à réutiliser plutôt que de créer un nouveau langage visuel ;
  - la zone d'information devient prioritaire sur la zone d'actions sur une largeur mobile, sans tronquer les informations essentielles ;
  - planification, modification, duplication et suppression restent accessibles, avec regroupement éventuel des actions secondaires dans un menu clairement identifié ;
  - nom, catégorie, type, difficulté, nombre d'objectifs, consignes, durée et matériel restent présentés selon leur disponibilité avec une hiérarchie compacte et compréhensible ;
  - les états liés à une session prévue restent identifiables sans dépendre uniquement de la couleur ;
  - textes, contrastes, zones tactiles et débordements sont vérifiés sur les deux thèmes et sur les largeurs mobiles prises en charge ;
  - navigation, routes et comportements métier existants restent inchangés ; les tests couvrent les variantes Stand/Maison, données minimales/complètes et session prévue.
- **VM** : 3
- **Notes** : créé à la recette du 2026-09-06 sous l'identifiant provisoire
  NT-145, puis déplacé vers NT-151 lors de la synchronisation avec `dev` afin
  de préserver les nouveaux items NT-145 à NT-150 sans collision. Hors
  périmètre du correctif de contraste NT-025 : ce dernier rend immédiatement
  les textes lisibles mais ne préjuge pas de la future composition des cartes.

---

## Thème 15 — Socle Coach transverse

<a id="NT-152"></a>
### NT-152 — Limiter une session à un exercice principal
- **Thème** : Socle Coach transverse · **Portée** : both · **Dépendances** : NT-001, NT-020, NT-022, NT-072
- **Description** : Remplacer l'association actuelle de plusieurs exercices par zéro ou un exercice principal par session, afin d'attribuer sans ambiguïté le résultat d'une session à l'exercice travaillé.
- **Critères d'acceptation** : le modèle app et le contrat serveur portent un `exerciseId` facultatif ; aucun `prescriptionId` n'est ajouté ; les interfaces empêchent de sélectionner plusieurs exercices ; la migration des sessions existantes conserve le premier exercice dans l'ordre enregistré et ignore les suivants ; les sessions sans exercice restent valides ; duplication, import, export, affichage, filtres et contrôle de suppression d'un exercice utilisent la nouvelle cardinalité ; les anciennes sauvegardes restent lisibles.
- **Notes** : cette évolution remplace la cardinalité plusieurs-à-plusieurs livrée par NT-022 sans réécrire son historique.

<a id="NT-153"></a>
### NT-153 — Consentement à l'utilisation des coachs
- **Thème** : Socle Coach transverse · **Portée** : both · **Dépendances** : NT-030, NT-040, NT-048
- **Description** : Ajouter une autorisation globale, explicite et simple avant toute transmission de données à un Coach NexTarget.
- **Critères d'acceptation** : une case unique est disponible dans les préférences Coach ; cochée, elle autorise les Coachs de session et de progression à recevoir les données nécessaires uniquement lors d'une analyse demandée par l'utilisateur ; décochée, elle désactive les deux coachs et chaque point d'entrée affiche que le partage des données est requis ; le carnet et les autres fonctions locales restent utilisables ; aucune synchronisation automatique ou en arrière-plan n'est déclenchée ; retirer l'autorisation n'efface pas les données déjà transmises.
- **Notes** : la suppression des données déjà transmises est hors périmètre et suivie par NT-158.

<a id="NT-154"></a>
### NT-154 — Qualifier l'exercice lors de la réalisation d'une session prévue
- **Thème** : Socle Coach transverse · **Portée** : both · **Dépendances** : NT-002, NT-131, NT-152
- **Description** : Lorsqu'une session prévue avec exercice devient une session réalisée, recueillir les informations minimales permettant au Coach d'évaluer la tentative.
- **Critères d'acceptation** : la dernière page du wizard de conversion remplace le récapitulatif actuel par la qualification de l'exercice, sans ajouter d'étape ; elle demande si l'exercice a été réalisé, si le protocole a été suivi et permet un commentaire facultatif ; le modèle de session conserve ces trois valeurs dans une structure simple ; le résultat exploitable par le Coach est réussi, échoué ou non évaluable, notamment si l'exercice n'a pas été réalisé ou si le protocole est insuffisamment suivi ; les sessions sans exercice et les autres parcours de création ne sont pas modifiés ; les données sont incluses lors d'une analyse et persistées avec la session côté serveur.

<a id="NT-155"></a>
### NT-155 — Déplacer le niveau d'expérience dans les préférences Coach
- **Thème** : Socle Coach transverse · **Portée** : app · **Dépendances** : NT-032, NT-042
- **Description** : Déplacer l'édition du niveau d'expérience depuis le profil vers les préférences Coach, à côté des autres réglages influençant les analyses.
- **Critères d'acceptation** : le contrôle n'est plus éditable depuis le profil ; il apparaît dans `Paramètres > Coach IA` ; les trois valeurs et leur stockage actuels sont strictement conservés ; si l'utilisateur n'a sélectionné aucune valeur, le niveau reste non renseigné ; aucune valeur par défaut n'est appliquée ; aucune migration ni modification de modèle ou de contrat serveur n'est introduite.
- **Notes** : la transmission de cette préférence pendant une analyse relève de NT-156.

<a id="NT-156"></a>
### NT-156 — Recentrer le Coach de session sur le débrief
- **Thème** : Socle Coach transverse · **Portée** : both · **Dépendances** : NT-030, NT-031, NT-152 à NT-155
- **Description** : Faire du Coach de session un débrief limité à la session terminée et à l'exercice éventuellement travaillé, sans décision longitudinale réservée au Coach de progression.
- **Critères d'acceptation** : l'analyse exige le consentement NT-153 et reçoit un identifiant stable, les données complètes de la session et des séries, le niveau d'expérience courant, l'exercice associé, sa réalisation, le suivi du protocole et les commentaires ; lors de la demande, le serveur crée ou met à jour la session reçue sans synchronisation préalable, puis persiste l'analyse séparément ; une demande rejouée sur une session inchangée ne crée pas de doublon ; la réponse structurée contient un débrief factuel, une à trois réussites, un point d'attention, les limites et, lorsqu'un exercice existe, son résultat réussi, échoué ou non évaluable ; la seule suite autorisée est de refaire l'exercice ou de demander une nouvelle décision au Coach de progression ; le Coach de session ne crée ni ne modifie objectif, exercice ou plan ; l'application présente dès cette release le futur Coach de progression, même s'il n'est pas encore utilisable ; aucun feature flag n'est ajouté.

<a id="NT-157"></a>
### NT-157 — Séparer décision et ton du Coach de session
- **Thème** : Socle Coach transverse · **Portée** : server · **Dépendances** : NT-032, NT-122, NT-156
- **Description** : Séparer l'analyse et les décisions du Coach de session de leur reformulation selon le ton choisi par l'utilisateur.
- **Critères d'acceptation** : un premier prompt produit une sortie structurée validée ; un second prompt reçoit cette sortie et la reformule selon le ton configuré ; la reformulation ne peut modifier aucune métrique, conclusion, évaluation ou prochaine action ; les personas partagent donc exactement la même décision ; si la reformulation échoue ou devient invalide, le serveur renvoie une formulation de secours issue de la sortie structurée.
- **Notes** : pipeline attendu : `PromptCoach` → sortie structurée → `PromptTonCoach` → texte utilisateur.

<a id="NT-158"></a>
### NT-158 — Supprimer les données transmises aux coachs
- **Thème** : Socle Coach transverse · **Portée** : both · **Dépendances** : NT-153, NT-156
- **Description** : Permettre ultérieurement à l'utilisateur de supprimer les sessions et analyses déjà transmises aux coachs.
- **Critères d'acceptation** : à définir — déclenchement, périmètre, confirmation, propagation et conservation des traces légales ou techniques.
- **Notes** : Icebox ; hors release préparatoire, démo et MVP immédiat. Retirer le consentement NT-153 ne déclenche pas cette suppression.

---
