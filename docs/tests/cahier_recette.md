# Cahier de Recette

- Dernière mise à jour: 2026-09-04
- Généré automatiquement depuis `docs/tests/cahier_recette.yaml`

## NT-140 — Démarrage sans second splash Flutter
Objectif: Vérifier que le splash natif conduit directement à la destination attendue.
Étapes:
1. Effectuer un démarrage à froid Android avec un utilisateur authentifié
2. Recommencer avec un utilisateur non authentifié
3. Effacer les données puis recommencer au premier lancement avec l'onboarding
4. Recommencer en ouvrant un callback OAuth nextarget://callback valide
5. Recommencer avec une configuration absente ou invalide afin d'utiliser les valeurs de repli
Résultats attendus:
- Le splash natif sobre est le seul écran de démarrage
- La destination attendue apparaît directement, sans slogan, animation Flutter ni délai artificiel
- L'onboarding, l'état d'authentification, la navigation et le callback OAuth restent fonctionnels

## NT-141 — Ordre des sections de Paramètres
Objectif: Vérifier l'ordre vertical complet et le rattachement visuel de l'avertissement.
Étapes:
1. Ouvrir Paramètres sur une largeur mobile dans le thème Classique puis France
2. Parcourir successivement Préférences Tir, Sauvegardes & Portabilité, Coach IA, Thème et Aide
3. Dans Préférences Tir, vérifier prise, râtelier puis calibre par défaut
4. Dans Sauvegardes & Portabilité, vérifier export, import puis avertissement non chiffré
5. Importer une sauvegarde contenant une nouvelle arme
Résultats attendus:
- Les cinq sections et leurs contrôles suivent exactement l'ordre attendu dans les deux thèmes
- L'avertissement appartient visuellement aux sauvegardes et précède Coach IA
- Aucun contrôle ou texte d'aide ne manque et le râtelier est rafraîchi après import

## NT-143 — Duplication de sessions détaillées et libres
Objectif: Créer une session indépendante depuis un détail sans effet avant validation.
Étapes:
1. Ouvrir une session détaillée réalisée avec exercices, séries, synthèse, analyse et photo, puis choisir Dupliquer la session
2. Vérifier le préremplissage et la date vide, modifier une série et un exercice, choisir une nouvelle date puis enregistrer
3. Modifier puis supprimer la copie et contrôler la source et son fichier photo
4. Dupliquer de la même manière une session libre
5. Annuler une duplication, puis simuler un échec d'écriture et un échec de copie photo
6. Ouvrir le détail d'un brouillon guidé
Résultats attendus:
- La copie conserve le sous-type et les champs métier mais reçoit un nouvel identifiant et exige une nouvelle date si elle est réalisée
- Les listes, séries et exercices sont indépendants et la source reste inchangée
- La photo de la copie possède un chemin et un cycle de vie propres
- Annulation et erreurs ne laissent ni session partielle ni fichier orphelin
- Le brouillon guidé ne propose pas l'action et aucun résumé n'est copié dans le presse-papiers

## NT-026-027 — Suppression et duplication d'exercice
Objectif: Vérifier les nouvelles actions sans modifier les sessions ni l'exercice source.
Étapes:
1. Tenter de supprimer un exercice référencé par plusieurs sessions de types et statuts différents
2. Dissocier l'exercice, relancer Supprimer, vérifier son nom dans la confirmation puis annuler
3. Confirmer ensuite la suppression et contrôler la liste, le compteur et les sessions
4. Simuler une erreur de lecture des sessions puis une erreur de suppression
5. Dupliquer un exercice renseigné avec catégorie, type, description, durée, matériel, consignes et objectifs
6. Modifier tous les champs de la copie, annuler une première fois, puis recommencer et enregistrer
Résultats attendus:
- Toute session liée bloque la suppression avec le nombre exact de sessions à dissocier
- L'annulation et les erreurs ne modifient rien ; la suppression réussie ne touche aucune session et rafraîchit liste et compteur
- Le formulaire dupliqué porte le suffixe (copie) et reprend tous les champs
- La copie possède un nouvel identifiant, une nouvelle date et un nouvel ordre ; ses listes sont indépendantes de l'original

## NT-014 — Comparatif glissant 30 j / 90 j et sparklines
Objectif: Vérifier les deux métriques indépendantes, leurs populations et leur présentation mobile.
Pré-requis:
- Disposer d'au moins une série réalisée récente, une série réalisée entre J-90 et J-31, et cinq sessions exploitables pour afficher chaque sparkline
Étapes:
1. Ouvrir Statistiques > Avancé dans le thème Classique puis dans le thème France
2. Ouvrir l'aide depuis Synthèse et vérifier les explications de Régularité, Progression, Dynamique des performances et des courbes
3. Vérifier les lignes Points par série et Groupement par série sur une petite largeur mobile
4. Comparer manuellement les moyennes 30 j et 90 j, le delta absolu et le pourcentage relatif
5. Utiliser deux moyennes qui s'arrondissent toutes deux à 14,4 mais conservent un faible écart réel
6. Ajouter une session prévue, une session libre et une série à zéro point sans groupement, puis rouvrir le comparatif
7. Tester successivement quatre puis cinq sessions exploitables pour chaque métrique
8. Vérifier un jeu de données où le score progresse tandis que le groupement s'élargit
Résultats attendus:
- La fenêtre 90 j inclut les 30 derniers jours et le comparatif exige une série récente plus une série antérieure ; J-30 et J-90 à minuit restent inclus même lorsque l'heure courante est plus tardive
- Les sessions prévues et libres ne changent aucune valeur ; le score nul reste compté et le groupement invalide est ignoré uniquement pour cette métrique
- Chaque ligne affiche ses moyennes, son delta signé et son pourcentage ; une base 90 j nulle ou une population insuffisante produit un message explicite
- La carte Progression affiche sur une ligne les mêmes pourcentages de groupement puis de score que le comparatif
- Si une décimale masque l'écart, les moyennes et le delta passent à deux décimales et restent cohérents avec le pourcentage
- Une baisse du groupement conserve un delta négatif et affiche un pourcentage positif, sans verdict global
- Chaque sparkline reste masquée à quatre sessions et apparaît à cinq avec un point moyen par session
- Aucun débordement n'apparaît et la compréhension ne dépend pas de la couleur dans les deux thèmes
- L'aide explique que Progression reprend les deux pourcentages du comparatif emboîté 30 j/90 j

## NT-073 — Calibre par défaut et statistiques par calibre
Objectif: Vérifier le préremplissage explicite, la saisie libre et le regroupement statistique sans réécriture.
Pré-requis:
- Disposer de sessions réalisées avec les calibres 9mm, 9x19, .380 ACP et une valeur libre inconnue
Étapes:
1. Dans Paramètres > Préférences Tir, choisir .45 ACP comme calibre par défaut
2. Créer une session réalisée puis une session prévue depuis leurs onglets
3. Modifier librement le calibre proposé, enregistrer, puis rouvrir les sessions en édition et dans le wizard
4. Effacer la préférence et créer une nouvelle session
5. Ouvrir Statistiques et consulter la répartition par calibre
Résultats attendus:
- La préférence ne propose que les calibres reconnus et persiste après redémarrage
- Les deux nouvelles sessions sont préremplies avec .45 ACP sans étape supplémentaire
- La saisie n'est jamais autoremplacée et l'édition comme le wizard conservent exactement la valeur enregistrée
- Sans préférence, le calibre d'une nouvelle session est vide
- 9mm et 9x19 sont regroupés sous 9 mm, .380 ACP reste distinct et la valeur inconnue est absente de cette seule répartition

## NT-131 — Session guidée au stand et brouillon reprenable
Objectif: Préparer, interrompre, reprendre puis clôturer une séance détaillée sans session prévue ni exercice obligatoire.
Pré-requis:
- Disposer éventuellement d'un calibre et d'une prise par défaut, d'armes au râtelier et de plusieurs exercices
Étapes:
1. Ouvrir Sessions et vérifier l'action principale Au stand ainsi que les trois créations du menu Autres créations
2. Préparer 10 séries de 7 coups avec une arme libre suggérée par le râtelier, un calibre libre, zéro puis plusieurs exercices, une distance initiale et une prise
3. Vérifier l'alignement arme/calibre puis séries/coups/distance et la position des raccourcis 15 m et 25 m sous la distance
4. Commencer, renseigner une série avec un score nul et un commentaire vide, puis vérifier la sauvegarde temporisée
5. Sur une autre série, saisir un commentaire sans score, quitter puis reprendre et vérifier que le score reste vide et obligatoire
6. Utiliser les raccourcis 15 m et 25 m, une distance libre, modifier la prise, naviguer vers la série précédente puis la suivante
7. Ajouter une série, quitter temporairement l'assistant, fermer puis redémarrer l'application
8. Vérifier que l'action principale reste Au stand et reprendre depuis la carte Séance en cours de l'historique
9. Terminer plus tôt, vérifier le nombre de séries vides retirées, puis annuler et recommencer la confirmation
10. Dans le récapitulatif, vérifier matériel, exercices, séries, coups, distances et points ; ajouter, remplacer puis retirer une photo et saisir une synthèse
11. Vérifier qu'une seconde création guidée est refusée tant que le brouillon existe
12. Terminer la séance, créer un nouveau brouillon puis l'abandonner après confirmation
13. Créer un autre brouillon, puis exporter et réimporter la sauvegarde
14. Pendant une clôture, vérifier que l'ajout, les actions et la sortie sont désactivés ; tenter aussi de réimporter un brouillon lorsqu'un autre existe
Résultats attendus:
- La préparation propose date et heure courantes, les préférences sans autoremplacement, 10 séries de 5 coups par défaut et un volume calculé sans borne maximale à cinq
- L'exercice reste facultatif et ne modifie jamais le nombre de séries ; distance et prise sont héritées comme simples préremplissages indépendants
- Le brouillon et la saisie partielle survivent à l'interruption, apparaissent séparément en tête des Réalisées et restent absents des statistiques, objectifs, compteurs et analyses Coach
- La fin anticipée ne conserve aucune série vide et l'abandon supprime le brouillon et sa photo uniquement après confirmation
- Après abandon, aucun brouillon ne réapparaît, même brièvement, au retour dans Sessions
- La clôture ouvre directement le détail d'une session détaillée réalisée standard sans réafficher temporairement le brouillon ; une erreur simulée conserve intégralement le brouillon avec un message exploitable
- Un score absent ne devient jamais zéro après reprise ; aucune mutation ne peut suivre la clôture et un import ne peut jamais créer un second brouillon
- Les sessions planifiées, réalisées détaillées, libres et le wizard de conversion prévue restent fonctionnels dans les thèmes Classique et France
- Les filtres exercice et catégorie restent alignés dans les onglets Réalisées et Prévues ; les prévues datées sont classées par date croissante avant celles affichées Sans date

## SESS-01 — Sessions – création/édition
Objectif: Créer une session réalisée avec armes/séries, puis l’éditer sans perte de données.
Pré-requis:
- Application installée
- Aucune session obligatoire
Étapes:
1. Ouvrir Sessions, Autres créations, puis Session réalisée détaillée
2. Renseigner arme, calibre, prise, au moins 1 série (coups, distance, points, groupement)
3. Enregistrer la session
4. Ouvrir la session et modifier un champ (ex: commentaire)
5. Enregistrer à nouveau
Résultats attendus:
- La session apparaît dans l’historique réalisée
- Les champs saisis sont persistés fidèlement
- La modification est bien visible après réouverture

## SESS-01b — Sessions – créations secondaires explicites
Objectif: Vérifier que les parcours historiques restent accessibles après la réorganisation NT-131.
Étapes:
1. Ouvrir Sessions, toucher Autres créations puis Session planifiée et vérifier le statut prérempli
2. Revenir, choisir Session réalisée détaillée, puis Session libre
Résultats attendus:
- Les trois actions sont nommées et ouvrent leurs formulaires respectifs sans appui long ni geste caché
- Le parcours planifié crée toujours une véritable session prévue et la session libre reste distincte

## SESS-02 — Sessions prévues (planification) + conversion wizard
Objectif: Planifier une session, puis la convertir en réalisée via l’assistant.
Étapes:
1. Depuis un exercice, planifier une session prévue
2. Vérifier l’icône “prévue” et la présence dans la liste dédiée
3. Lancer la conversion (wizard), compléter séries et synthèse
4. Valider la conversion
Résultats attendus:
- La session disparaît des “prévues” et figure dans les sessions réalisées
- Les séries saisies via le wizard sont bien persistées

## SESS-03 — Sessions libres sans séries ni scores (NT-133)
Objectif: Créer, relire, modifier et supprimer une session libre sans dégrader le parcours détaillé.
Pré-requis:
- Disposer éventuellement d'un calibre par défaut et d'au moins deux exercices
Étapes:
1. Dans Sessions, ouvrir Autres créations et choisir Session libre
2. Vérifier aussi les actions Session planifiée et Session réalisée détaillée
3. Créer une session libre avec date, arme, calibre libre, nombre de tirs, distance entière et chacune des trois catégories lors de trois essais
4. Associer zéro, un puis plusieurs exercices ; ajouter, consulter, remplacer puis supprimer une photo ; renseigner une synthèse
5. Ouvrir la carte Libre, modifier la session puis la supprimer
6. Vérifier l'aide contextuelle Sessions et les thèmes Classique et France
7. Contrôler statistiques, objectifs d'assiduité, filtres catégorie/exercice et compteur de tirs de l'arme
8. Exporter puis réimporter une sauvegarde contenant sessions détaillées et libres
9. Modifier une session détaillée historique à distance décimale sans toucher la distance, puis essayer une nouvelle distance décimale
Résultats attendus:
- Les trois créations secondaires sont distinctes par icône, libellé et sémantique accessibles
- La session libre est toujours réalisée et refuse arme/calibre vides, tirs nuls, distance nulle ou décimale
- Carte et détail affichent Libre, arme, calibre, catégorie, tirs, distance et exercices sans score, groupement, séries ni action Coach
- Synthèse, photo et exercices sont conservés ; l'import/export préserve chaque sous-type et ses champs
- Les agrégats d'assiduité et volumes incluent la session libre, contrairement aux métriques de séries ; un calibre inconnu est absent de la seule répartition par calibre
- La distance décimale historique reste affichée sans arrondi ni réécriture et doit être corrigée vers un entier avant enregistrement

## DASH-01 — Tableau de bord – statistiques récap
Objectif: Afficher les statistiques macro et les dernières tendances.
Étapes:
1. Créer/ajouter une session avec au moins 1 série
2. Ouvrir l’accueil/Tableau de bord (onglet Synthèse)
3. Vérifier la moyenne de points 30 j, le groupement moyen 30 j, la meilleure série et le nombre de sessions du mois
Résultats attendus:
- Les valeurs sont cohérentes avec les sessions existantes

## DASH-02 — Tableau de bord – statistiques avancées
Objectif: Vérifier la mise à jour des statistiques dans l’onglet Avancé.
Étapes:
1. Créer/ajouter une session avec au moins 1 série
2. Ouvrir le Tableau de bord (onglet Avancé)
Résultats attendus:
- Les statistiques et graphes sont mis à jour avec la nouvelle session

## GOAL-01 — Objectifs – création/édition et listing
Objectif: Créer un objectif, vérifier son affichage et sa progression.
Étapes:
1. Créer un objectif (nom, période, métriques)
2. Vérifier la présence dans le listing et la carte “Top”
3. Modifier l’objectif et enregistrer
Résultats attendus:
- L’objectif est visible avec ses informations correctes
- La modification est persistée

## EX-01 — Exercices – création et association aux sessions
Objectif: Créer un exercice et l’associer à une session.
Étapes:
1. Créer un exercice (nom, catégorie, type, durée, matériel, consignes)
2. Depuis l’exercice, planifier puis convertir une session (cf. SESS-02)
Résultats attendus:
- L’exercice apparaît dans la liste et l’association session ↔ exercice est visible

## EX-02 — Exercices – session prévue depuis un exercice d’entraînement
Objectif: Vérifier que le nombre de séries prévues correspond au nombre de consignes.
Étapes:
1. Créer un exercice de type "Stand" avec 3 consignes
2. Transformer cet exercice en session prévue
Résultats attendus:
- La session prévue est créée avec un nombre de séries égal au nombre de consignes (3)

## CAL-01 — Calibres – autocomplétion + préférence par défaut
Objectif: Saisie de calibre assistée et préremplie si préférence définie.
Étapes:
1. Ouvrir création de session, focus sur calibre → voir liste complète
2. Taper un alias (ex: 9mm) et sélectionner une option
3. Saisir une valeur libre sans choisir de suggestion
Résultats attendus:
- La liste s’affiche au focus
- La sélection remplit le champ correctement
- La saisie n'est jamais remplacée automatiquement et la valeur libre est conservée

## CAL-02 — Calibres – préférence par défaut
Objectif: Préremplir le champ calibre depuis la préférence utilisateur.
Étapes:
1. Aller dans Préférences et sélectionner un calibre par défaut
2. Créer une nouvelle session
Résultats attendus:
- Le champ calibre est prérempli avec le calibre par défaut
- Une édition conserve son calibre enregistré, même si la préférence a changé

## PREF-01 — Réglages – préférences utilisateur (Hive)
Objectif: Tester la préférence "1 main / 2 mains" et son effet de préremplissage.
Étapes:
1. Ouvrir l’écran Réglages et régler la préférence de prise d’arme (1 main / 2 mains)
2. Créer une nouvelle session et vérifier le préremplissage de la prise
Résultats attendus:
- La préférence est persistée et appliquée au formulaire de session

## PREF-02 — Réglages – préférence calibre
Objectif: Tester la préférence de calibre (saisie assistée + persistance).
Étapes:
1. Ouvrir l’écran Réglages et modifier la préférence de calibre (autocomplétion: la liste apparaît lors de la saisie)
2. Sauvegarder, puis rouvrir les préférences pour vérifier la persistance
Résultats attendus:
- La liste de calibres apparaît bien lors de la saisie et la valeur choisie est persistée

## WEAP-01 — Râtelier d'armes – CRUD (NT-008)
Objectif: Ajouter, renommer et supprimer une arme du râtelier personnel, avec propagation du renommage aux sessions.
Pré-requis:
- Au moins une session réalisée utilisant une arme du râtelier
Étapes:
1. Ouvrir Paramètres > Préférences Tir, section Râtelier d'armes
2. Ajouter une arme (ex. "CZ 75") ; tenter d'en ajouter une autre avec le même nom (espaces/casse différents) → refusé
3. Renommer l'arme (ex. "CZ 75 SP-01 Shadow"), confirmer
4. Supprimer une autre arme du râtelier, confirmer
Résultats attendus:
- Le doublon normalisé est refusé avec un message clair
- Le renommage est propagé au champ arme des sessions correspondantes (prévues et réalisées)
- La suppression retire l'arme de la liste sans modifier aucune session existante

## WEAP-02 — Autocomplétion de l'arme en saisie de session (NT-009)
Objectif: Vérifier que la saisie libre reste prioritaire tout en proposant les armes du râtelier.
Pré-requis:
- Au moins deux armes dans le râtelier (ex. "CZ 75 SP-01 Shadow", "Glock 17")
Étapes:
1. Créer ou éditer une session (réalisée ou prévue), taper le début du nom d'une arme du râtelier
2. Sélectionner la suggestion proposée
3. Dans une autre session, taper un nom d'arme absent du râtelier jusqu'au bout
4. Répéter dans le wizard de conversion (session prévue → réalisée)
Résultats attendus:
- Les suggestions correspondantes apparaissent pendant la frappe (casse ignorée)
- Sélectionner une suggestion remplit le champ avec le nom complet
- Le texte libre n'est jamais écrasé ni bloqué, y compris dans le wizard

## WEAP-03 — Compteur de tirs par arme (NT-017)
Objectif: Vérifier le compteur de tirs par arme du râtelier en bas de Statistiques > Synthèse.
Pré-requis:
- Au moins une arme du râtelier avec des sessions réalisées associées, et une arme sans aucune session
Étapes:
1. Ouvrir Statistiques > Synthèse et faire défiler après la répartition par calibre
2. Vérifier le total affiché pour une arme ayant des sessions réalisées
3. Vérifier l'affichage d'une arme sans session (total à zéro)
4. Ajouter une nouvelle session réalisée pour une arme du râtelier, revenir sur l'écran
Résultats attendus:
- La section est en dernière position de Synthèse, absente d'Avancé, sans graphe et avec une ligne par arme du râtelier
- Le total correspond à la somme des coups des sessions réalisées uniquement (essais compris)
- Une arme sans session affiche 0 tir
- Le total se met à jour après l'ajout d'une nouvelle session

## EXP-01 — Export sessions
Objectif: Exporter les sessions et vérifier le fichier généré.
Étapes:
1. Ouvrir le module d’export, choisir un dossier
2. Lancer l’export
Résultats attendus:
- Un fichier est généré dans le dossier choisi

## SEC-01 — Rappels essentiels de sécurité
Objectif: Afficher les rappels de sécurité et vérifier leur lisibilité.
Étapes:
1. Ouvrir l’accueil/Tableau de bord puis le panneau “Rappels Essentiels”
2. Consulter l'onglet Sécurité
Résultats attendus:
- Les rappels sont lisibles et le lien d'information externe est accessible

## AUTH-01 — Connexion Google – persistance longue durée (refresh token, NT-048)
Objectif: Vérifier que la connexion reste active sans reconnexion manuelle après expiration de l'access token courant.
Pré-requis:
- Compte Google configuré
Étapes:
1. Se connecter avec Google depuis Paramètres
2. Utiliser l'app normalement (profil, Coach) pendant une durée dépassant la validité de l'access token courant
Résultats attendus:
- Aucune demande de reconnexion: le renouvellement de l'access token est transparent
- Le profil et le Coach restent accessibles sans interruption visible

## AUTH-02 — Déconnexion – révocation serveur et nettoyage local (NT-048)
Objectif: Vérifier qu'une déconnexion efface systématiquement la session locale, même si le serveur est injoignable.
Pré-requis:
- Utilisateur connecté
Étapes:
1. Depuis le profil, se déconnecter avec une connexion réseau fonctionnelle
2. Se reconnecter, puis couper le réseau (mode avion) et se déconnecter à nouveau
Résultats attendus:
- Dans les deux cas, l'app repasse immédiatement en mode non connecté (bouton "Se connecter" visible)
- Aucune donnée d'authentification ne subsiste localement après la déconnexion, même hors ligne

## AUTH-03 — Résilience réseau – session connectée préservée hors ligne (NT-048)
Objectif: Vérifier qu'une coupure réseau ne déconnecte jamais l'utilisateur et ne bloque pas le carnet.
Pré-requis:
- Utilisateur connecté
Étapes:
1. Couper le réseau (mode avion)
2. Consulter le carnet de tir, les statistiques, les objectifs et les exercices
3. Ouvrir une session réalisée et tenter de lancer l'analyse Coach
4. Réactiver le réseau
Résultats attendus:
- Le carnet, les statistiques, les objectifs et les exercices restent pleinement utilisables hors ligne
- Le Coach indique clairement son indisponibilité réseau (pas un message de session expirée)
- L'utilisateur reste connecté (pas de retour forcé à l'écran de connexion) ; le Coach redevient utilisable une fois le réseau rétabli

## AUTH-04 — Migration – installation existante sans refresh token (NT-048)
Objectif: Vérifier qu'une installation connectée avant NT-048 (sans refresh token stocké) demande une unique reconnexion Google.
Pré-requis:
- Installation existante avec un access token stocké avant le déploiement de NT-048 (pas de refresh token)
Étapes:
1. Ouvrir l'app après la mise à jour et attendre l'expiration de l'ancien access token (ou solliciter le profil/Coach)
Résultats attendus:
- L'app demande une reconnexion Google une seule fois (message clair, pas de boucle ni de crash)
- Après cette reconnexion, la persistance longue durée (AUTH-01) fonctionne normalement

## COACH-01 — Analyse coach – utilisateur connecté (via serveur)
Objectif: Vérifier que l'analyse coach passe par NexTarget-server quand l'utilisateur est connecté, sans clé Mistral côté client.
Pré-requis:
- Utilisateur connecté (compte Google)
- Session avec au moins 1 série
Étapes:
1. Ouvrir une session réalisée avec au moins 1 série
2. Ouvrir la section "Analyse Coach" et lancer l'analyse
Résultats attendus:
- L'analyse s'affiche normalement (popup markdown), sans configurer de clé Mistral locale
- La réponse est enregistrée dans la session (relecture après réouverture)

## COACH-02 — Analyse coach – utilisateur non connecté (coach connecté uniquement, NT-061)
Objectif: Vérifier que sans compte, l'analyse coach est inaccessible avec un message clair, et que le carnet de tir reste 100 % utilisable hors connexion.
Pré-requis:
- Utilisateur non connecté (pas de compte)
Étapes:
1. Vérifier que l'app démarre normalement sans être connecté (carnet de tir accessible)
2. Ouvrir une session réalisée et déplier la section "Analyse Coach"
Résultats attendus:
- Aucun bouton "Lancer analyse" ; message "Le coach IA nécessite un compte" + bouton "Se connecter" menant à l'écran de connexion
- Le reste de l'app (sessions, exercices, objectifs, stats) reste pleinement utilisable hors connexion

## COACH-03 — Analyse coach – gestion des erreurs (session expirée / serveur indisponible)
Objectif: Vérifier qu'une erreur d'analyse reste claire, distingue session expirée et panne réseau, et ne bloque pas l'app.
Pré-requis:
- Utilisateur connecté avec un refresh token invalide/expiré/révoqué (ou serveur temporairement indisponible / réseau coupé)
Étapes:
1. Lancer l'analyse coach avec une session dont la reconnexion échoue (refresh invalide): un message "Session expirée, reconnectez-vous." s'affiche
2. Lancer l'analyse coach hors ligne (réseau coupé): un message distinct d'indisponibilité réseau s'affiche (pas "session expirée")
Résultats attendus:
- Les deux messages sont clairement différenciés (session à reconnecter vs réseau indisponible)
- Aucun crash, l'app reste utilisable ensuite ; hors ligne, l'utilisateur n'est pas déconnecté (cf. AUTH-03)

## COACH-04 — Coach – sélection du ton (neutre / cool) (NT-032)
Objectif: Vérifier la sélection de la persona du coach et son effet sur l'analyse.
Pré-requis:
- Utilisateur connecté
- Session réalisée avec au moins 1 série
Étapes:
1. Dans Paramètres > Coach IA, sélectionner le ton Cool
2. Ouvrir une session réalisée, déplier Analyse Coach (aucun sélecteur de ton ne doit y figurer)
3. Lancer l'analyse ; puis repasser sur Neutre dans Paramètres et relancer une analyse sur une autre session
Résultats attendus:
- Le choix est persisté (y compris après redémarrage) et ne se règle QUE dans Paramètres
- L'analyse en ton cool est tutoyée/encourageante ; en ton neutre elle est sèche et factuelle

## ONB-01 — Onboarding – premier lancement (NT-075)
Objectif: Vérifier l'introduction 3 écrans au premier lancement.
Pré-requis:
- Première installation (ou données app effacées)
Étapes:
1. Lancer l'app et parcourir les 3 écrans avec "Suivant" puis "Commencer"
2. Redémarrer l'app
Résultats attendus:
- Les 3 écrans (carnet de tir, stats & objectifs, coach IA) s'affichent au premier lancement uniquement
- Le bouton Passer saute l'introduction ; après Commencer ou Passer, l'app s'ouvre normalement
- Au redémarrage, l'onboarding ne réapparaît pas

## ONB-02 — Onboarding – revoir l'introduction (NT-075)
Objectif: Revoir l'introduction depuis les Paramètres.
Étapes:
1. Ouvrir Paramètres > Aide > Revoir l'introduction
2. Parcourir ou passer l'introduction
Résultats attendus:
- L'introduction s'affiche en plein écran et se referme sur Commencer/Passer
- Retour aux Paramètres sans effet de bord

## HELP-01 — Aide contextuelle « ? » (NT-075)
Objectif: Vérifier les boutons d'aide sur Sessions, Objectifs, Exercices.
Étapes:
1. Ouvrir l'écran Mes sessions et toucher l'icône « ? »
2. Ouvrir l'onglet Exercices & Objectifs et toucher l'icône « ? »
3. Ouvrir la liste Objectifs puis la liste Exercices et toucher l'icône « ? »
Résultats attendus:
- Chaque écran affiche une bottom sheet d'aide avec un titre et des points concrets propres à l'écran
- La bottom sheet se ferme par glissement ou tap hors zone, sans effet de bord
