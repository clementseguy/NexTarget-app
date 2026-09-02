# Prompt agent — lot NT-014, NT-048, NT-061, NT-073 et NT-133

Tu dois terminer le lot prioritaire NexTarget composé de NT-014, NT-048,
NT-061, NT-073 et NT-133. Le travail concerne principalement l'application
Flutter. Le serveur FastAPI ne doit être modifié que si l'inspection de NT-048
révèle un écart réel entre son contrat actuel et les critères du backlog ;
n'apporte aucun changement serveur spéculatif.

Spécifications produit :
https://github.com/clementseguy/NexTarget-app/blob/main/docs/backlog/backlog-unifie.md

Plan du lot :
https://github.com/clementseguy/NexTarget-app/blob/main/docs/backlog/plan-sprints.md

Sections concernées :

- NT-014 — Comparatif glissant 30j vs 90j + sparkline
- NT-048 — Refresh tokens + rotation
- NT-061 — Coach connecté uniquement : retrait clé Mistral client + rotation
- NT-073 — Calibre par défaut + normalisation statistique
- NT-133 — Sessions libres sans séries ni scores

## Avant toute modification

1. Lis intégralement `AGENTS.md` dans NexTarget-app.
2. Lis intégralement `AGENTS.md` dans NexTarget-server avant toute inspection ou
   modification serveur.
3. Consulte la gouvernance dans `NexTarget-app/docs/backlog/README.md` et les
   critères complets de chaque item dans le backlog unifié.
4. Inspecte les modèles, repositories, services, providers, formulaires,
   statistiques, objectifs, filtres, préférences, authentification, sauvegardes,
   migrations, cahier de recette et tests existants avant de choisir
   l'architecture.
5. Vérifie l'état Git des deux dépôts et préserve toutes les modifications
   préexistantes.
6. Respecte le workflow Git de chaque dépôt : pars de `dev`, ne travaille jamais
   directement sur `dev` ou `main`, et crée une branche conforme aux conventions.
   Le lot peut utiliser une branche app multi-features. Ne crée une branche
   serveur que si une modification serveur est effectivement nécessaire.
7. Compare le contrat NT-048 de l'app avec les endpoints serveur existants
   `/auth/token/exchange`, `/auth/token/refresh` et `/auth/token/revoke` avant de
   modifier l'API.

## Stratégie de livraison

Travaille dans cet ordre et garde les deux incréments fusionnables séparément :

1. incrément A : NT-061 documentaire, NT-073, NT-014, puis NT-048 ;
2. incrément B : NT-133 et sa migration structurelle.

NT-133 ne doit pas retarder la livraison de l'incrément A. Ne marque un item
`FAIT` qu'après satisfaction complète de sa Definition of Done.

## Exigences générales

- Implémente exactement les critères d'acceptation du backlog unifié.
- Recherche une solution simple, lisible, robuste et cohérente avec l'existant.
- Évite la surarchitecture, la duplication et toute abstraction non justifiée.
- Respecte le sens des dépendances : UI vers provider/service vers repository
  vers modèle.
- Aucun accès direct à Hive depuis les nouveaux composants UI.
- Le carnet, les statistiques, les objectifs et les exercices doivent continuer
  à fonctionner hors ligne. Seules les fonctionnalités avancées connectées,
  principalement le Coach, dépendent du réseau.
- Préserve la compatibilité des données Hive et des exports JSON historiques.
- N'introduis aucun changement fonctionnel hors périmètre.
- N'ajoute aucun secret, appel Mistral direct, fallback Coach local, `print`,
  `withOpacity` ou suppression de lint injustifiée.

## NT-061 — Clôture documentaire et audit

- Considère NT-061 comme déjà `FAIT` sur le plan fonctionnel.
- Vérifie qu'il n'existe aucun `CoachAnalysisService` direct, clé/config/prompt
  Mistral, appel Mistral local, proxy de secours ou fallback client actif.
- `ServerCoachAnalysisService` doit rester l'unique chemin app ; le client
  Mistral du backend est légitime et ne doit pas être supprimé.
- La clé historique a déjà été rotée : ne tente aucune rotation ni opération sur
  un secret.
- Préserve les changelogs, anciennes release notes et specs versionnées comme
  historique. Corrige seulement un document actif qui décrirait encore le
  fonctionnement ancien.
- Si l'audit ne trouve aucun code mort, n'invente aucun changement de code pour
  cet item.

## NT-073 — Calibre par défaut et normalisation

- Aucun « dernier calibre utilisé » ne doit être mémorisé.
- La préférence de calibre par défaut est facultative. Elle ne peut être choisie
  que parmi les calibres reconnus ; vide, elle ne préremplit rien.
- Elle préremplit uniquement les nouvelles sessions réalisées ou prévues.
  L'édition conserve toujours la valeur de la session.
- Centralise l'autocomplétion pour les paramètres, la création et l'édition des
  sessions prévues/réalisées et le wizard.
- Les suggestions ne doivent jamais autoremplacer, forcer ou écraser la saisie.
  Les champs de session restent libres.
- Retire l'entrée générique `Autre` du référentiel et des suggestions.
- Sépare la normalisation de recherche de la résolution statistique. Ne modifie
  jamais la valeur stockée.
- Regroupe `9mm`, `9 mm`, `9x19`, `9 mm Para` et `9mm (9x19)` sous le libellé
  statistique `9 mm`.
- Garde `.380 ACP` distinct. N'ajoute aucun alias `9 mm court` sans nouvel
  arbitrage produit.
- Un calibre inconnu reste inclus dans les scores, groupements, volumes et
  autres statistiques globales ; il est exclu uniquement des regroupements par
  calibre.
- Valide et déduplique le référentiel après normalisation.

## NT-014 — Comparatif 30/90 jours

- Utilise deux fenêtres glissantes emboîtées : les 90 derniers jours incluent
  les 30 derniers jours.
- Calcule globalement, sans filtre par arme, calibre, distance ou exercice.
- Exige au moins une série dans les 30 derniers jours et au moins une autre
  série entre J-90 et J-31 avant d'afficher le comparatif.
- Utilise uniquement les sessions réalisées et détaillées.
- Présente séparément :
  - moyenne des points par série ;
  - moyenne du groupement par série.
- Une série réalisée à zéro point reste valide. Un groupement absent, incohérent
  ou non strictement positif est ignoré seulement pour la métrique groupement.
- Score et groupement sont indépendants. Ne calcule aucun verdict global et
  n'ajoute aucune qualification automatique de stagnation, hausse ou baisse.
- Affiche, pour chaque métrique, les moyennes 30 j et 90 j, le delta absolu et
  le pourcentage fondé sur la moyenne 90 j.
- Pour le groupement, conserve le signe mathématique tout en rendant le sens
  métier explicite, par exemple `-4 cm · +14 % d'amélioration`. Conserve l'unité
  actuelle de l'app et n'introduis aucune conversion implicite des données.
- Une sparkline contient un point par session, égal à la moyenne des séries
  exploitables de cette session pour la métrique. Elle est masquée sous cinq
  sessions exploitables, indépendamment pour score et groupement.
- Reprends la structure validée à deux lignes. Elle doit être compacte sur
  mobile, accessible, lisible dans les deux thèmes et ne pas dépendre uniquement
  de la couleur.
- Utilise une horloge injectable, traite explicitement les bornes J-30/J-90 et
  supprime toute limite silencieuse susceptible de tronquer la population.
- Clarifie ou supprime l'ancien calcul 30/60 s'il est présenté comme équivalent à
  NT-014 ; ne casse pas une statistique distincte encore utile sans justification.

## NT-048 — Refresh tokens côté app

- Le serveur possède déjà l'émission, l'expiration glissante de 30 jours, la
  rotation à usage unique, la détection de rejeu, la révocation de famille et
  des tests. Réutilise ce contrat.
- Stocke access token, refresh token et expirations dans
  `flutter_secure_storage`, sans journaliser leurs valeurs.
- Remplace atomiquement la paire après rotation. Une interruption ne doit pas
  laisser l'access token et le refresh token de deux générations différentes.
- Renouvelle proactivement l'access token juste avant expiration.
- Après un `401`, autorise au maximum un renouvellement et un rejeu de la requête.
  Ne crée aucune boucle de retry.
- Implémente un mécanisme single-flight afin que des requêtes concurrentes ne
  consomment pas deux fois le même refresh token.
- Vérifie soigneusement comment rendre une requête HTTP rejouable, notamment les
  corps streamés ; ne tente pas de renvoyer un `BaseRequest` déjà finalisé.
- Un refresh invalide, expiré, révoqué ou rejoué entraîne une reconnexion. Les
  installations historiques sans refresh token demandent une reconnexion
  Google unique.
- Une panne réseau ne doit jamais effacer les tokens ni rendre le carnet local
  inutilisable. Le Coach affiche une erreur réseau claire.
- Au logout, tente `/auth/token/revoke` en best effort puis efface toujours les
  données d'authentification locales.
- Fais passer le profil, le Coach et tous les appels authentifiés par la même
  mécanique.

## NT-133 — Sessions libres

- Fais de `ShootingSession` la racine abstraite commune de
  `DetailedShootingSession` et `SimpleShootingSession`, conformément au backlog.
- Les anciennes sessions deviennent détaillées sans perte de données.
- Une session libre est toujours réalisée et ne peut jamais être planifiée.
- Champs obligatoires : date, arme, calibre, nombre total de tirs entier
  strictement positif, distance entière strictement positive et catégorie.
- Catégories autorisées : `entraînement`, `match`, `test matériel`.
- Champs facultatifs : synthèse, photo de cible et zéro à plusieurs exercices.
- Réutilise la notion et le libellé actuels de synthèse ; ne crée pas un doublon
  « commentaires ».
- Le calibre suit NT-073 : préférence éventuelle, autocomplétion libre et
  résolution statistique sans réécriture.
- Une session libre ne contient aucune série, aucun score, aucun groupement et
  aucune analyse Coach. Ne propose pas l'action Coach et ne fabrique aucun
  payload artificiel.
- Autorise ajout, remplacement, consultation et suppression d'une photo selon la
  mécanique actuelle de NT-005.
- Conserve sans changement le comportement direct du bouton `+` actuel. Ajoute
  une action secondaire distincte, accessible et visible uniquement dans
  l'onglet Réalisées ; aucun menu intermédiaire ni appui long.
- Identifie seulement les sessions libres avec badge/libellé `Libre`, icône et
  accent thématique. N'ajoute pas de badge `Détaillée` aux cartes existantes.
- La carte libre montre au minimum date, arme, calibre, catégorie, nombre de
  tirs, distance et nombre éventuel d'exercices ; la synthèse reste dans le
  détail.
- Les indicateurs de nombre de sessions, d'assiduité et les objectifs fondés sur
  l'assiduité incluent les sessions libres. Les métriques de score, groupement
  ou séries les ignorent. Les volumes et NT-017 additionnent leur `shotCount`.
- Les filtres pertinents, notamment catégorie et exercice, fonctionnent sur les
  deux sous-types.
- Le format JSON contient `sessionType: detailed|simple`. Une ancienne donnée
  sans discriminant est détaillée. Un discriminant inconnu produit une erreur
  explicite et un import entièrement atomique.
- Pour les distances détaillées existantes, conserve la compatibilité de lecture
  avec les décimales historiques. Les créations et modifications, libres comme
  détaillées, n'acceptent dorénavant que des mètres entiers positifs ; ne réécris
  ni n'arrondis automatiquement l'historique.

## Qualité et tests

- Ajoute les tests unitaires, de repository, de service, de migration et de
  widget nécessaires, avec cas nominaux, limites et erreurs.
- NT-014 : couvre exactement les bornes temporelles, population minimale,
  fenêtres emboîtées, score nul, groupement absent, deltas, division par zéro,
  métriques contradictoires et seuil de cinq sessions par sparkline.
- NT-073 : couvre préférence vide/valide/invalide, tous les parcours de saisie,
  édition, liberté de saisie, absence d'autoremplacement, alias 9 mm et inconnus.
- NT-048 : couvre renouvellement proactif, retry unique, concurrence, rotation
  atomique, rejeu, expiration, absence de refresh historique, réseau indisponible
  et logout.
- NT-133 : couvre polymorphisme, migration, sérialisation historique et mixte,
  import atomique, validations, catégories, photo, absence de Coach, exercices,
  filtres, objectifs, agrégats, NT-017, actions flottantes et les deux thèmes.
- Si le stockage exige une évolution structurelle Hive, applique strictement les
  règles de migration d'`AGENTS.md` et ajoute un test de migration.
- Mets à jour la source du cahier de recette puis régénère le document puisque
  les comportements visibles changent.
- Mets à jour les changelogs et la documentation concernée. Synchronise d'abord
  le backlog unifié, puis ses vues. Ne modifie pas les anciennes notes de release
  uniquement parce qu'elles décrivent fidèlement un ancien état.
- Exécute le formatage, `flutter analyze --fatal-infos`, les tests ciblés puis la
  suite complète ou `scripts/verify_before_commit.sh` côté app. Exécute `pytest`
  côté serveur uniquement si le serveur est modifié.

## Compte rendu attendu

À la fin, fournis un compte rendu concis contenant :

- les branches et dépôts modifiés ;
- l'architecture retenue et les principaux fichiers modifiés ;
- les décisions importantes, notamment polymorphisme, migration, atomicité des
  tokens, single-flight et requêtes rejouables ;
- les migrations et mesures de rétrocompatibilité ;
- les tests ajoutés et toutes les commandes exécutées ;
- leurs résultats exacts ;
- les vérifications manuelles restantes et toute limite connue ;
- le statut réel de chaque item au regard de la Definition of Done.
