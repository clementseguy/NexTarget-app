# Sessions

Ce document décrit le comportement livré. Les évolutions envisagées restent dans le [backlog unifié](../backlog/backlog-unifie.md).

## Types et états de session

Une session détaillée contient une date facultative, une arme, un calibre, une catégorie, des séries, une synthèse, zéro ou un exercice principal et éventuellement une photo et une analyse Coach. Elle peut être `prévue` ou `réalisée`.

Une session libre sert à consigner rapidement une séance sans séries, score ni groupement. Elle exige une date, une arme, un calibre, un nombre de tirs entier positif et une distance entière positive. Elle est toujours `réalisée`, peut avoir une synthèse, une photo et un exercice principal facultatif, et ne propose jamais d'analyse Coach.

Une session détaillée peut aussi être `brouillon` pendant une séance guidée au stand. Ce troisième état métier est distinct d'une session `prévue` : il contient les séries validées et la saisie partielle courante, survit au redémarrage et reste exclu de tous les agrégats et du Coach jusqu'à sa clôture.

Les catégories persistées sont `entraînement`, `match` et `test matériel`.

## Création et planification

- Dans Sessions, l'action principale reste `Au stand`. Un brouillon se reprend depuis sa carte en tête de l'historique ; une seule séance guidée peut être en cours à la fois.
- Le menu `Autres créations` conserve trois parcours explicites : session planifiée, session réalisée détaillée via le formulaire historique et session libre.
- Seul un exercice de type Stand peut créer une session prévue. Une série provisoire est créée par consigne ; sans consigne, une série provisoire unique est créée.
- La conversion d'une session prévue en session réalisée force le statut `réalisée`, fixe la date si nécessaire et conserve les séries renseignées dans l'assistant.
- La première page du wizard présente l'exercice associé dans une card pleine largeur avec le nombre de consignes, la durée et le matériel requis. Arme, calibre et catégorie sont espacés ; la catégorie reste limitée aux valeurs contrôlées.
- Lorsqu'un exercice est associé, la dernière page « Synthèse de la session » conserve la synthèse du tireur puis ajoute une analyse entièrement facultative : exercice réalisé (`oui`, `non` ou non renseigné), protocole suivi (`oui`, `partiellement`, `non` ou non renseigné) et commentaire libre. Les aides accessibles au toucher précisent que les deux questions portent sur l'exécution du début à la fin. Une session prévue sans exercice conserve sa page de synthèse historique.

## Séance guidée au stand

La préparation propose la date et l'heure courantes, l'arme libre assistée par le râtelier, le calibre libre éventuellement prérempli, la catégorie, un exercice principal facultatif, le nombre de séries, les coups par série, la distance initiale et la prise préférée. L'exercice n'impose jamais le nombre de séries.

`Commencer la séance` crée immédiatement le brouillon. La saisie série par série préremplit les coups, hérite de la distance et de la prise précédentes sans lier les séries entre elles, et sauvegarde à chaque navigation ainsi qu'après une courte temporisation. Un score nul saisi reste distingué d'un score encore absent après reprise. Les distances 15 m et 25 m sont des raccourcis ; toute distance entière positive reste possible. Le commentaire est facultatif et recommandé pour le Coach.

L'utilisateur peut corriger une série précédente, ajouter une série, quitter puis reprendre, ou terminer plus tôt après confirmation du nombre de séries vides retirées. La synthèse finale récapitule matériel, exercices, séries, coups, distances et points, puis permet une synthèse et une photo facultatives. `Terminer la séance` remplace atomiquement le brouillon par une session détaillée `réalisée` et ouvre directement son détail. En cas d'échec, le brouillon reste intégralement reprenable.

Le champ Groupement de la séance guidée et du wizard des sessions prévues
partage une aide gestuelle : poing fermé sous 10 cm, pouce déployé autour de
15 cm, puis pouce et petit doigt déployés autour de 20 cm. Ces repères dépendent
de la main et se comparent au niveau de la cible. L'aide ne modifie jamais la
saisie.

## Saisie et consultation

- Les champs arme et calibre restent libres. Les suggestions du râtelier et du catalogue de calibres n'écrasent jamais le texte saisi.
- Le calibre par défaut préremplit uniquement une nouvelle saisie ; une session existante conserve sa valeur.
- Toute nouvelle distance, détaillée ou libre, doit être un entier strictement positif. Les anciennes distances décimales restent lisibles mais doivent être corrigées avant une nouvelle sauvegarde.
- L'historique sépare les sessions réalisées des sessions prévues. Il trie les réalisées de la plus récente à la plus ancienne et les prévues datées de la plus proche à la plus lointaine, suivies des prévues affichées explicitement `Sans date`. Les filtres catégorie et exercice sont disponibles côte à côte dans les deux onglets.
- Supprimer une session supprime aussi sa photo locale. Remplacer ou retirer une photo nettoie l'ancien fichier après sauvegarde.
- Le détail d'une session réalisée ou prévue propose « Dupliquer la session ». Le formulaire de création reprend son sous-type et ses champs, mais jamais son identifiant, son UUID Coach, son débrief ou sa date. Une session réalisée exige une nouvelle date avant enregistrement ; un brouillon guidé ne peut pas être dupliqué.
- Les séries, exercices et autres listes d'une duplication sont indépendants. La photo source n'est copiée physiquement qu'à la validation ; une annulation ou un échec ne laisse ni session ni fichier orphelin.

## Effets sur les statistiques

Les sessions libres comptent dans l'assiduité, les catégories et les volumes de tirs. Elles ne participent jamais aux scores, groupements, séries, courbes fondées sur les séries ou analyses Coach. Les règles détaillées sont dans [statistiques.md](statistiques.md).

## Persistance et compatibilité

Le champ `sessionType` vaut `detailed` ou `simple`. Chaque session porte un
`sessionUuid` stable, généré à la création ou par migration pour les données
historiques et conservé dans les sauvegardes. Une duplication reçoit un nouvel
UUID. `coachAnalysis` contient le débrief structuré ; l'ancien champ `analyse`
reste relu comme fallback Markdown. Une ancienne donnée sans `sessionType` est
relue comme une session détaillée. `exerciseId` contient l'identifiant facultatif
de l'exercice principal. Lors de la migration d'une ancienne liste `exercises`,
seul le premier identifiant dans l'ordre enregistré est conservé ; une liste
vide devient `null`. Une session détaillée avec exercice peut porter
`exerciseExecution`, structure additive contenant `performed` (`bool?`),
`protocolFollowed` (`yes`, `partially`, `no` ou absent) et `comment` facultatif.
Une qualification absente ou partiellement invalide reste lisible sans valeur
inventée. Pour une session détaillée, `status` accepte `prévue`, `réalisée` ou
`brouillon` ; chaque série porte des marqueurs additifs de saisie guidée, dont
la présence effective du score. Les séries historiques dépourvues de ces
marqueurs sont relues comme enregistrées. Un type ou un état inconnu, ou un
import qui créerait plusieurs brouillons, fait échouer l'import avant l'écriture
des sessions.
