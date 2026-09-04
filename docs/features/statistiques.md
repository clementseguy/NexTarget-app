# Statistiques

Ce document décrit les règles fonctionnelles actuellement implémentées dans `StatsService` et `DashboardService`.

## Population commune

- Toutes les statistiques ignorent les sessions prévues et les sessions sans date.
- Les séries proviennent uniquement des sessions détaillées réalisées et sont ordonnées par date de session, puis dans l'ordre de saisie.
- Les sessions libres comptent dans les nombres de sessions, les jours actifs, les catégories et les volumes de tirs, mais pas dans les métriques fondées sur les séries.
- Les fenêtres glissantes historiques de 30 jours utilisent `date > maintenant - 30 jours`.

## Synthèse

- Moyenne des points sur 30 jours : moyenne simple des points de toutes les séries de la fenêtre.
- Groupement moyen sur 30 jours : moyenne simple des valeurs enregistrées, y compris les anciennes valeurs nulles ou négatives. Seuls les records de groupement filtrent les valeurs non positives.
- Meilleure série : maximum des points sur tout l'historique réalisé.
- Sessions du mois : sessions détaillées et libres réalisées du mois civil courant.
- Courbes points et groupement : au plus les 30 dernières séries, affichées de l'ancienne vers la récente. La tendance points est une moyenne mobile sur trois séries, avec une fenêtre réduite au début.
- Répartitions catégories et calibres : une occurrence par session réalisée. Les alias `9mm`, `9x19`, `9mm para` et `9mm (9x19)` sont regroupés sous `9 mm`. Un calibre inconnu reste dans la session mais est exclu de cette seule répartition.

## Statistiques avancées

- Régularité : `(1 - écart-type population / moyenne) × 100`, bornée entre 0 et 100 ; elle vaut 0 avec moins de trois séries ou une moyenne non positive.
- Meilleur groupement : minimum strictement positif de tout l'historique.
- Record de la dernière série : comparaison stricte avec toutes les séries précédentes, séparément pour les points et le groupement.
- Compteur par arme : somme des tirs des sessions réalisées dont le nom d'arme correspond au râtelier après normalisation de casse et d'espaces. Les séries détaillées et le nombre direct des sessions libres sont additionnés ; les sessions prévues sont exclues.

## Comparatif 30 jours / 90 jours

Le comparatif est global et ne tient compte que des sessions détaillées réalisées datées entre J-90 et aujourd'hui, bornes calendaires incluses. J-30 appartient à la période récente ; la période antérieure va de J-90 à la veille de J-30.

Pour les points et le groupement, il présente séparément :

- la moyenne des séries des 30 derniers jours ;
- la moyenne des séries des 90 derniers jours, qui inclut les 30 derniers jours ;
- le delta absolu `moyenne30 - moyenne90` ;
- le delta relatif à la moyenne 90 jours.

Une comparaison exige au moins une série exploitable dans chaque période. Un score nul est valide. Pour le groupement seulement, les valeurs non finies ou non strictement positives sont ignorées. L'amélioration relative du groupement inverse le signe métier : une baisse de taille est une amélioration.

Chaque sparkline contient un point moyen par session, de l'ancienne vers la récente, et n'apparaît qu'à partir de cinq sessions exploitables pour la métrique concernée. Aucun verdict global de hausse, baisse ou stagnation n'est déduit.
