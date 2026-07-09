# Cahier de Recette

- Dernière mise à jour: 2026-07-07
- Généré automatiquement depuis `docs/tests/cahier_recette.yaml`

## SESS-01 — Sessions – création/édition
Objectif: Créer une session réalisée avec armes/séries, puis l’éditer sans perte de données.
Pré-requis:
- Application installée
- Aucune session obligatoire
Étapes:
1. Ouvrir l’app, onglet “Réalisées”, puis “+” (le + crée une session du type de l’onglet actif)
2. Renseigner arme, calibre, prise, au moins 1 série (coups, distance, points, groupement)
3. Enregistrer la session
4. Ouvrir la session et modifier un champ (ex: commentaire)
5. Enregistrer à nouveau
Résultats attendus:
- La session apparaît dans l’historique réalisée
- Les champs saisis sont persistés fidèlement
- La modification est bien visible après réouverture

## SESS-01b — Sessions – bouton + selon l'onglet actif
Objectif: Vérifier que le + crée une session du même type que l'onglet affiché (retour recette S2).
Étapes:
1. Ouvrir Mes sessions, onglet Réalisées, toucher + et vérifier le statut prérempli
2. Revenir, passer sur l'onglet Prévues, toucher + et vérifier le statut prérempli
Résultats attendus:
- Onglet Réalisées → formulaire de session réalisée ; onglet Prévues → formulaire de session prévue
- Aucun menu d'appui long sur le + (comportement supprimé)

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

## DASH-01 — Tableau de bord – statistiques récap
Objectif: Afficher les statistiques macro et les dernières tendances.
Étapes:
1. Créer/ajouter une session avec au moins 1 série
2. Ouvrir l’accueil/Tableau de bord (onglet Synthèse)
3. Vérifier l’affichage des indicateurs (réalisés total, 7/30/60/90j) et cartes récap
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
1. Créer un exercice de type "entraînement" avec 3 consignes
2. Transformer cet exercice en session prévue
Résultats attendus:
- La session prévue est créée avec un nombre de séries égal au nombre de consignes (3)

## CAL-01 — Calibres – autocomplétion + préférence par défaut
Objectif: Saisie de calibre assistée et préremplie si préférence définie.
Étapes:
1. Ouvrir création de session, focus sur calibre → voir liste complète
2. Taper un alias (ex: 9mm) et sélectionner une option
Résultats attendus:
- La liste s’affiche au focus
- La sélection remplit le champ correctement

## CAL-02 — Calibres – préférence par défaut
Objectif: Préremplir le champ calibre depuis la préférence utilisateur.
Étapes:
1. Aller dans Préférences et sélectionner un calibre par défaut
2. Créer une nouvelle session
Résultats attendus:
- Le champ calibre est prérempli avec le calibre par défaut

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

## EXP-01 — Export sessions
Objectif: Exporter les sessions et vérifier le fichier généré.
Étapes:
1. Ouvrir le module d’export, choisir un dossier
2. Lancer l’export
Résultats attendus:
- Un fichier est généré dans le dossier choisi

## SEC-01 — Règles de sécurité (dashboard)
Objectif: Afficher le bloc de règles FFTir et vérifier sa lisibilité.
Étapes:
1. Ouvrir l’accueil/Tableau de bord
2. Vérifier la section “Règles de sécurité”
Résultats attendus:
- Le contenu est à jour et lisible (révision FFTir 2024)

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
Objectif: Vérifier qu'une erreur d'analyse reste claire et ne bloque pas l'app.
Pré-requis:
- Utilisateur connecté avec un token expiré ou invalide (ou serveur temporairement indisponible)
Étapes:
1. Lancer l'analyse coach dans ces conditions dégradées
Résultats attendus:
- Un message d'erreur clair s'affiche ("Session expirée, reconnectez-vous." ou équivalent)
- Aucun crash, l'app reste utilisable ensuite

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

