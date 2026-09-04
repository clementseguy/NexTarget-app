# Objectifs

## Définition

Un objectif contient un titre, une métrique, un comparateur, une cible, une période, un statut et une priorité d'affichage. Les métriques disponibles sont :

- moyenne des points par série ;
- moyenne des moyennes de points par session ;
- nombre de sessions ;
- total des points ;
- groupement moyen ;
- meilleure série ;
- meilleur total de session ;
- meilleur groupement.

Le comparateur est `supérieur ou égal` ou `inférieur ou égal`. La période porte sur tout l'historique, les 7 derniers jours ou les 30 derniers jours.

## Progression et atteinte

Le calcul utilise uniquement les sessions réalisées et datées. Une session libre compte pour la métrique nombre de sessions ; elle est ignorée par toutes les métriques fondées sur les séries.

La progression est bornée entre 0 et 100 %. Pour une cible minimale, elle correspond à `valeur / cible`. Pour une cible maximale, elle correspond à `cible / valeur`. Une valeur non calculable produit 0 % ou conserve la dernière mesure selon le cas.

Lorsqu'un objectif actif satisfait sa comparaison, il passe automatiquement au statut atteint et reçoit sa première date d'atteinte. Le calcul ne remet pas automatiquement un objectif atteint au statut actif.

## Tendance

La tendance n'est calculée que pour les périodes glissantes : fenêtre courante de 7 ou 30 jours comparée à la fenêtre de même durée immédiatement précédente. Les bornes suivent exactement le service : dates strictement postérieures au début de fenêtre et, pour la fenêtre précédente, strictement antérieures à sa fin.

Le delta est normalisé afin qu'une valeur positive signifie toujours une amélioration :

- cible minimale : `valeur courante - valeur précédente` ;
- cible maximale : `valeur précédente - valeur courante`.

Avec `kGoalDeltaNeutralEpsilon = 0.001`, la tendance affichée est En hausse au-dessus du seuil, En baisse sous son opposé et Stable entre les deux. Sans mesure précédente exploitable ou sans période glissante, aucune tendance significative n'est affichée.

## Affichage

Les objectifs actifs sont classés d'abord par progression décroissante, puis par priorité. L'écran affiche aussi les totaux actifs et atteints ainsi que les atteintes des 7, 30, 60 et 90 derniers jours.
