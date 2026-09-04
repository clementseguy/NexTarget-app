# Sessions

Ce document décrit le comportement livré. Les évolutions envisagées restent dans le [backlog unifié](../backlog/backlog-unifie.md).

## Deux types de session

Une session détaillée contient une date facultative, une arme, un calibre, une catégorie, des séries, une synthèse, des exercices associés et éventuellement une photo et une analyse Coach. Elle peut être `prévue` ou `réalisée`.

Une session libre sert à consigner rapidement une séance sans séries, score ni groupement. Elle exige une date, une arme, un calibre, un nombre de tirs entier positif et une distance entière positive. Elle est toujours `réalisée`, peut avoir une synthèse, une photo et plusieurs exercices, et ne propose jamais d'analyse Coach.

Les catégories persistées sont `entraînement`, `match` et `test matériel`.

## Création et planification

- Dans l'onglet Réalisées, le bouton principal crée une session détaillée et une action distincte crée une session libre.
- Dans l'onglet Prévues, le bouton principal crée une session détaillée prévue ; l'action libre n'est pas disponible.
- Seul un exercice de type Stand peut créer une session prévue. Une série provisoire est créée par consigne ; sans consigne, une série provisoire unique est créée.
- La conversion d'une session prévue en session réalisée force le statut `réalisée`, fixe la date si nécessaire et conserve les séries renseignées dans l'assistant.

## Saisie et consultation

- Les champs arme et calibre restent libres. Les suggestions du râtelier et du catalogue de calibres n'écrasent jamais le texte saisi.
- Le calibre par défaut préremplit uniquement une nouvelle saisie ; une session existante conserve sa valeur.
- Toute nouvelle distance, détaillée ou libre, doit être un entier strictement positif. Les anciennes distances décimales restent lisibles mais doivent être corrigées avant une nouvelle sauvegarde.
- L'historique sépare les sessions réalisées des sessions prévues, trie les réalisées de la plus récente à la plus ancienne et permet de filtrer par catégorie et par exercice.
- Supprimer une session supprime aussi sa photo locale. Remplacer ou retirer une photo nettoie l'ancien fichier après sauvegarde.

## Effets sur les statistiques

Les sessions libres comptent dans l'assiduité, les catégories et les volumes de tirs. Elles ne participent jamais aux scores, groupements, séries, courbes fondées sur les séries ou analyses Coach. Les règles détaillées sont dans [statistiques.md](statistiques.md).

## Persistance et compatibilité

Le champ `sessionType` vaut `detailed` ou `simple`. Une ancienne donnée sans ce champ est relue comme une session détaillée. Un type inconnu fait échouer l'import avant l'écriture des sessions.
