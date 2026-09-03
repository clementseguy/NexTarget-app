# Statistiques Accueil – Documentation Technique (v0.3)

Portée: décrit UNIQUEMENT l'existant (implémenté) pour l'écran Accueil. Aucune projection future.

## 0. Révision
2025-10-03 Réécriture propre (existant only).
2025-10-10 Ajout section
2026-09-03 NT-133 : prise en charge des sessions libres.
2026-09-03 NT-014 : comparatif global glissant 30 j / 90 j et sparklines par session.

## 1. Sources & Préparation (Lot C)
- Filtrage centralisé AVANT tout calcul: `SessionFilters.realizedWithDate` exclut systématiquement les sessions au statut `prévue` et sans date. Utilisé par `StatsService` et `RollingStatsService`.
- Construction `_series` (`StatsService`): sur la base des sessions détaillées filtrées, chaque série hérite de la date session, puis l’ensemble est trié par date ASC. Les sessions libres n'alimentent jamais cette collection. Ordre strict intra-session respecté (F14).
- `RollingStatsService`: service legacy non affiché dans le dashboard, qui calcule des totaux moyens par session détaillée sur 30/60 j. Il est distinct du comparatif NT-014, calculé par série dans `DashboardService`.

## 2. Règles Globales
- Fenêtres temporelles: 30 jours (`date > now - 30j`), 60 jours analogue. Les fenêtres progression: (0..30j) vs (30..60j).
- Sessions libres : incluses dans les nombres de sessions, jours actifs, catégories, séries d'assiduité et volumes de tirs. Leur `shotCount` direct alimente NT-017. Elles sont exclues des scores, groupements, records, distributions de points/distances de séries et courbes fondées sur les séries. Un calibre inconnu reste inclus dans les agrégats généraux et est exclu uniquement de la répartition par calibre.
- Groupement: les valeurs `groupSize <= 0` NE SONT PAS filtrées dans la moyenne 30j (elles entrent dans le dénominateur) mais sont ignorées pour: best groupement (`bestGroupSize`) et record groupement (`lastSeriesIsRecordGroup`) et implicites dans min() (positives uniquement).
- Valeurs par défaut / insuffisance:
	- Moyennes / compte / distributions / rolling / streak / charge: 0 si vide ou insuffisant.
	- Consistency: 0 si <3 séries ou moyenne ≤0 ou résultat non fini.
	- Progression: `NaN` si conditions non remplies (≥5 séries dans chaque fenêtre & avgPrev>0).
	- Records: false si <2 séries ou conditions non satisfaites.
- Série pour les graphes de tendance (points, groupement) et le scatter: sélection des 30 dernières séries en ordre chronologique ASC (ancien → récent). Cette sélection est indépendante des fenêtres 30j/60j basées sur la date.
- Comparatif NT-014 : fenêtre 90 j `[J-90, aujourd'hui]`, fenêtre récente 30 j `[J-30, aujourd'hui]` et population antérieure `[J-90, J-30[`. Les comparaisons utilisent les jours calendaires locaux normalisés à minuit : J-90 et J-30 sont donc inclus quelle que soit l'heure courante ou stockée, J-30 appartient à la période récente et tout jour futur est exclu. L'horloge est figée à la construction de `DashboardService` et injectable dans les tests.
- NT-014 est global : aucun filtre par arme, calibre, distance, catégorie ou exercice. Seules les sessions réalisées détaillées contribuent ; les sessions prévues, sans date et libres sont exclues.

## 3. Glossaire
Points = `serie.points` (entier, somme simple; aucune normalisation) • Groupement = `serie.groupSize` (cm, peut être 0 ou ≤0: ces valeurs comptent dans la moyenne 30j mais sont ignorées pour best/record) • Distance = `serie.distance` (m, arrondie UNIQUEMENT pour la distribution distance) • Catégorie = `session.category` (niveau session, défaut 'entraînement').

## 4. Tableau Synthétique
| Code | Nom UI | Source | Fenêtre | Formule / Règle | Condition | Fallback |
|------|--------|--------|---------|-----------------|----------|----------|
| AVG30 | Moy. points 30j | Séries | 30j | sum(points)/N | ≥1 série 30j | 0 |
| GRP30 | Groupement moy 30j | Séries | 30j (toutes valeurs, y compris ≤0) | sum(groupSize)/N | ≥1 série 30j | 0 |
| BEST | Best série | Séries | Toutes | max(points) | ≥1 série | '-' |
| SESSM | Sessions ce mois | Sessions | Mois courant | count(sessions) | Toujours | 0 |
| SMA3 | Tendance (SMA3) | Séries | Historique | moyenne glissante taille 3 (bords tronqués; si window<=1 → points bruts) | ≥1 série | valeurs brutes |
| CONS | Consistency 30j | Séries | 30j | (1 - σ/μ)*100 clamp [0,100] | ≥3 séries & μ>0 | 0 |
| PROGLEG | Ancien calcul de progression non affiché | Séries | 0..30 vs 30..60 | ((avgC-avgP)/avgP)*100 | ≥5 & avgP>0 | NaN |
| DIST30 | Répartition distances 30j | Séries | 30j | comptage distance arrondie | ≥1 série | liste vide |
| CAT | Répartition catégories | Sessions | Toutes | count(category) | ≥1 session | liste vide |
| BUCK | Distribution points 30j | Séries | 30j | buckets taille 10 | ≥1 série | liste vide |
| ROLL | Rolling avg30/avg60 | Sessions | 30/60j | sum(pointsSession)/count | ≥0 | 0 |
| RDELTA | Rolling delta | Sessions | 30/60j | avg30 - avg60 | dépend ROLL | 0 |
| STRK | Streak (jours) | Sessions | Historique | jours consécutifs | ≥1 session | 0 |
| LOAD | Charge semaine | Sessions | Semaine ISO | sessionsThisWeek() | ≥0 | 0 |
| LΔ | Delta charge | Sessions | Semaine cour./préc. | currentWeek - previousWeek | ≥0 | 0 |
| BESTGRP | Best groupement | Séries | Toutes | min(groupSize>0) | ≥1 série valide | 0 |
| RRECPTS | Record points dernière | Séries | Dernière vs précédent | last.points > max(prev) | ≥2 séries | false |
| RRECGRP | Record groupement dernière | Séries | Dernière vs précédent | last.groupSize < min(prev>0) | ≥2 séries valides | false |
| SCAT | Scatter pts/groupement | Séries | 30 dernières séries | (x=group_size,y=points) | ≥1 série | n/a |
| CMPPTS | Comparatif points NT-014 | Séries | 30 j inclus dans 90 j | avg30, avg90, `avg30-avg90`, `delta/avg90*100` | ≥1 série récente et ≥1 antérieure | état insuffisant ; % indisponible si avg90=0 |
| CMPGRP | Comparatif groupement NT-014 | Séries avec groupSize fini et >0 | 30 j inclus dans 90 j | mêmes moyennes/delta ; signe du delta conservé, pourcentage d'amélioration de signe opposé | ≥1 série valide par période | état insuffisant |
| SPARK | Sparklines NT-014 | Sessions | 90 j | 1 point/session = moyenne des séries exploitables de la session | ≥5 sessions exploitables par métrique | masquée avec compteur N/5 |

## 5. Détails des Calculs
### 5.1 Moyenne points 30j (AVG30)
Filtre: séries date > now-30j. Moyenne simple. Vide → 0.
### 5.2 Groupement moyen 30j (GRP30)
Filtre: séries date > now-30j (AUCUN filtrage sur groupSize). La moyenne inclut donc aussi les valeurs 0 ou négatives présentes. Vide → 0. (Les filtres groupSize>0 ne s'appliquent qu'à BESTGRP et RRECGRP.)
### 5.3 Best série (BEST)
Max(points) global. Aucune série → '-'.
### 5.4 Sessions ce mois (SESSM)
Count sessions (year & month = now).
### 5.5 SMA3 (SMA3)
Pour i: moyenne des points indices [i-2..i] (fenêtre 3 tronquée en début de série). Si window<=1 ou liste vide → valeurs brutes (points). Pas d'interpolation.
### 5.6 Consistency (CONS)
Fenêtre 30j. Conditions: ≥3 séries & moyenne>0. σ population. (1 - σ/μ)*100 clamp [0,100]. Sinon 0.
### 5.7 Progression (PROG)
Fenêtres: C (0..30j) & P (30..60j). Conditions: |C|≥5 & |P|≥5 & avgP>0 sinon NaN.
Ce calcul historique reste disponible dans le service pour compatibilité, mais n'est plus affiché. La carte « Progression » reprend désormais exclusivement, sur une même ligne, les deux deltas relatifs de NT-014 : amélioration du groupement puis évolution du score.
### 5.8 Distances 30j (DIST30)
Arrondi entier + comptage.
### 5.9 Catégories (CAT)
1 incrément par session (sessionsOnly).
### 5.10 Buckets points 30j (BUCK)
Buckets 10 pts successifs jusqu'au max.
### 5.11 Rolling (ROLL)
Somme points/session. avg30 / avg60 = sum / count (0 si count=0).
### 5.12 Rolling delta (RDELTA)
Delta = avg30 - avg60.
### 5.13 Streak (STRK)
Dates normalisées jour; tri DESC; diff==1 → incrément, autre → arrêt. Aucune session → 0.
### 5.14 Charge & Delta (LOAD / LΔ)
Semaine ISO (lundi). Delta = current - previous.
### 5.15 Best groupement (BESTGRP)
Min groupSize>0 sinon 0.
### 5.16 Records dernière (RRECPTS / RRECGRP)
Points: last > max(prev). Groupement: last < min(prev>0). <2 séries → false.
### 5.17 Scatter (SCAT)
Prendre les 30 dernières séries (après aplatissement ASC) → spots (group_size, points). maxX = max(group_size)+5 (plancher 10). maxY = 55 fixe.

### 5.18 Comparatif glissant et sparklines (NT-014)
Le score utilise toutes les séries, y compris une série à zéro point. Le groupement utilise uniquement les valeurs finies et strictement positives ; une valeur absente ou incohérente n'affecte pas la population score. Les moyennes 90 j portent sur toute la fenêtre emboîtée, donc incluent les valeurs des 30 derniers jours. Le comparatif entier n'est présenté que si la population score contient au moins une série récente et une série antérieure ; chaque métrique conserve ensuite son propre état d'insuffisance.

Le delta absolu est toujours `moyenne30 - moyenne90`. Le delta relatif score est `delta / moyenne90 * 100`. Si la moyenne 90 j vaut zéro, le pourcentage est indisponible plutôt que forcé à zéro. Pour le groupement, l'UI conserve le signe du delta absolu et inverse le signe relatif pour expliciter le sens métier : `-4,0 cm · +14,3 %`. Aucun verdict global ni seuil de stagnation/hausse/baisse n'est calculé.

Chaque sparkline parcourt les sessions des 90 derniers jours de l'ancienne vers la récente. Un point score est la moyenne des points de toutes les séries de la session ; un point groupement est la moyenne de ses seuls groupements valides. Les deux seuils d'affichage sont indépendants et fixés à cinq sessions exploitables. Aucun plafond de séries ou de sessions n'est appliqué.

L'affichage utilise normalement une décimale. Si les moyennes 30 j et 90 j deviennent identiques à une décimale alors qu'un écart réel subsiste, les moyennes et le delta absolu passent à deux décimales afin de ne jamais présenter visuellement `14,4 / 14,4` avec un pourcentage non nul. La sparkline n'affiche aucune ligne de référence arbitraire ; ses extrémités indiquent les valeurs ancienne et récente.

## 6. Règles d'Affichage
- Ancienne progression 30/60 : `NaN` si insuffisante, mais cette métrique n'est plus affichée. Consistency==0 → '-'.
- Badges record affichés si true.
- Badge "Best grp" affiché si `bestGroupSize() > 0` (valeur formatée 1 décimale + 'cm').
- Scatter / distributions masqués si aucune donnée.
- 0 ≠ '-' (0 = calcul valide; '-' = absence / insuffisant).
- NT-014 affiche ses deux métriques sur deux sections distinctes. Dans chacune, le delta est placé à droite des moyennes 30 j/90 j lorsque la largeur le permet. Les signes, unités, deltas et messages d'insuffisance portent le sens sans dépendre de la couleur. Une sparkline masquée indique le nombre de sessions exploitables sur les cinq requises.
- Le bouton d'aide de Synthèse détaille uniquement les indicateurs nécessitant une interprétation : régularité, carte Progression issue du comparatif 30 j/90 j et lecture des sparklines.

## 7. Limites Connues
- Scatter tronqué (30 séries) donc non exhaustif.
- Pas de normalisation distance sur groupement.
- σ population utilisé.
- Rolling 30/60 legacy: filtrage statut appliqué (Lot C), non affiché et non équivalent à NT-014 car il moyenne des totaux de session.
- Scatter biaisé: sélection d'abord des 10 dernières sessions puis découpe à 10 séries → certaines séries récentes hors de ces sessions peuvent être exclues.

## 8. Présentation
- Onglet "Synthèse"
	- Carré :
		Moyenne points 30 jours
		Groupement moyen 30 jours
		Best série : min absolu > 0
		Sessions ce mois : nombre de sessions du mois en cours
	- Evolution points par série
		- 30 dernières séries
		- Points
		- Tendance SMA3
	- Evolution groupement (cm)
		- 30 dernières séries
		- Groupement
	- Répartition catégorie
		- flat bar
	- Distribution points 
		- barres
		- par score de série
		- par dizaine
	Répartition distances (30j)
		- barres
		- par distances (10, 25 et 50)
- Onglet "Avancé"
	- Cartes
		Consistency : x% (c'est quoi ?)
		Progression : pourcentage groupement puis pourcentage score, tous deux issus du comparatif 30 j/90 j
		Distance fréquente : x m (nb série)
		Catégorie dominante
	- Comparatif global 30 jours vs 90 jours (NT-014)
		- Ligne Points par série : moyennes 30 j/90 j, delta absolu/relatif, sparkline par session si N≥5
		- Ligne Groupement par série : mêmes valeurs, groupements valides uniquement et sens d'amélioration explicité
	- Badges
		Streak : x J (useless)
		Charge : x (+/- x) (comprends pas)
		Best groupement : x cm
	- Corrélation Points / Groupement
		- Graphe à point
	- Points et groupement - 1 main
		- Score série
		- Groupement série
	- Points et groupement - 2 mains
		- Score série
		- Groupement série
