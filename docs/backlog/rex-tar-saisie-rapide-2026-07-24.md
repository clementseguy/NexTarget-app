# REX — prototype TAR et saisie rapide abandonné

**Date de décision** : 2026-07-24  
**Items concernés** : NT-100, NT-101, NT-073, NT-130  
**Branche abandonnée** :
`feat/NT-100-NT-101-NT-073-NT-130-socle-tar-saisie-rapide`  
**Dernier commit du prototype** : `117ca83`  
**Issue de la revue** : PR fermée sans fusion ; aucun code de cette branche ne
fait partie de `dev`.

## Décision

Le prototype est abandonné. Les quatre items restent **À FAIRE**.

La branche a démontré la faisabilité technique de plusieurs éléments
(référentiel YAML, persistance de la discipline, génération de séries TAR,
normalisation des calibres et stockage de setups), mais n'a pas démontré leur
utilisabilité. Une reprise devra repartir de `dev`, après une phase de design
validée. Il ne faut pas fusionner ni reprendre en bloc le commit `117ca83`.

Ce REX ne remet pas en cause la valeur métier du TAR ou de la saisie rapide. Il
documente pourquoi la solution proposée n'était pas la bonne.

## Ce qui a été observé en recette

### Le parcours standard a été dégradé

- Le bouton `+`, auparavant direct, ouvrait systématiquement un menu
  intermédiaire.
- L'action principale de ce menu était nommée « Vide », sans expliquer qu'il
  s'agissait d'une nouvelle session sans template.
- Ce choix supplémentaire était imposé même pour une session non TAR et même
  lorsqu'aucun dernier setup ou favori utile n'était disponible.

La promesse de NT-130 — réduire la friction — produisait donc l'effet inverse
sur le parcours majoritaire.

### Le mode TAR était techniquement présent mais peu compréhensible

- Après sélection, le champ n'affichait plus que le code `830`, au lieu du code
  et du nom complet de l'épreuve.
- Le style du champ ressemblait à un avertissement : rouge dans le thème France,
  jaune dans le thème classique.
- La sélection créait bien des séries, mais l'utilisateur ne disposait pas des
  explications nécessaires pour vérifier le nombre de coups et les règles.
- Essai, précision et vitesse étaient surtout différenciés par des couleurs,
  sans libellé ni légende explicite.
- Les cibles, temps réglementaires et modalités de comptage n'étaient pas
  suffisamment visibles.
- Pour les gongs, remplacer « Points » par « Gongs » ne suffisait pas à expliquer
  la saisie, la limite attendue ou la conversion en score.

### La consultation ne restituait pas le contexte

- La discipline et la saison étaient bien persistées.
- En lecture, une session TAR restait toutefois visuellement indiscernable
  d'une session classique.
- Les informations réglementaires utiles à l'interprétation des séries
  n'étaient pas restituées.

### Les favoris n'avaient pas de modèle mental clair

- Le bouton « Favori » n'expliquait pas ce qui serait mémorisé.
- Son activation a conduit à un écran d'erreur pendant la recette.
- Le lien entre dernier setup, favoris, template et session vide n'était pas
  compréhensible sans connaître l'implémentation.

## Raisons de l'échec

1. **Conception pilotée par les structures techniques.** Le référentiel, les
   champs persistés et les templates ont été exposés directement, sans partir
   des tâches réelles du tireur.
2. **Assemblage de quatre items dans un seul formulaire.** Chaque feature
   ajoutait son propre concept et ses propres états au parcours principal.
3. **Absence de divulgation progressive.** Les options TAR et templates étaient
   visibles ou bloquantes pour tous, y compris les utilisateurs non concernés.
4. **Sémantique insuffisante.** Des termes d'implémentation (« Vide », « setup »,
   codes seuls) ont remplacé des actions formulées du point de vue utilisateur.
5. **Couleur utilisée comme information métier.** Les types de séquence
   dépendaient trop de vignettes colorées, sans texte explicatif.
6. **Design de la saisie sans design de la consultation.** La donnée était
   stockée, mais sa valeur n'était pas restituée dans le détail de session.
7. **Validation UX trop tardive.** La recette utilisateur est intervenue après
   l'intégration technique complète du lot, plutôt qu'après des parcours ou un
   prototype léger.

## Principes UX obligatoires pour la reprise

### Préserver le parcours classique

- Une personne qui ne pratique pas le TAR ne doit subir aucune étape
  supplémentaire.
- Le bouton `+` doit rester direct par défaut.
- Un sélecteur de modèles ne doit apparaître que s'il propose des choix
  réellement disponibles et compréhensibles.
- Employer « Nouvelle session sans modèle » ou une formulation équivalente,
  jamais « Vide » seul.

### Rendre le TAR volontaire et guidé

- Le mode TAR doit être choisi explicitement, sans ressembler à une erreur ou à
  un avertissement.
- Une épreuve sélectionnée doit afficher au minimum son code et son nom complet.
- Le tireur doit comprendre avant validation quelles séries seront créées ou
  remplacées.
- Chaque série doit afficher textuellement son type, le nombre de coups, la
  cible, le temps et le mode de comptage.
- La couleur peut renforcer l'information, jamais la porter seule.
- Les règles proviennent d'un référentiel saisonné et leur saison doit être
  consultable.

### Expliquer la saisie des gongs

- Afficher le nombre de gongs attendus et la valeur d'un gong.
- Borner la saisie à une plage cohérente.
- Afficher immédiatement la conversion en points.
- Distinguer sans ambiguïté coups tirés, gongs touchés et score comptabilisé.

### Concevoir également la lecture

- Le détail doit identifier clairement une session TAR.
- Il doit afficher l'épreuve, la saison et les informations réglementaires
  nécessaires pour relire chaque série.
- Une session classique doit conserver une présentation simple.

### Donner un sens clair aux modèles

- Expliquer ce qui est enregistré dans un favori et ce qui ne l'est pas.
- Distinguer explicitement « dernier réglage », « favori » et « nouvelle
  session ».
- Ne jamais recopier silencieusement des résultats, une date, une photo ou une
  synthèse depuis une session précédente.
- Si aucun modèle n'existe, ne pas afficher une étape de sélection vide.

## Parcours à concevoir avant le prochain développement

Les quatre parcours suivants doivent être représentés par des wireframes ou un
prototype navigable :

1. création d'une session classique ;
2. création d'une session TAR guidée ;
3. création depuis un dernier réglage ou un favori ;
4. consultation d'une session TAR enregistrée.

Ils doivent couvrir les thèmes classique et France, les sessions réalisées et
prévues, l'absence de favoris, ainsi que la modification d'une session
existante.

## Critères de succès de la prochaine tentative

### Validation UX préalable

- Les quatre parcours sont revus avant tout changement de modèle ou de
  persistance.
- Les libellés sont compréhensibles sans explication orale du développeur.
- Le parcours classique conserve le même nombre d'actions qu'avant la feature.
- Un test utilisateur sur prototype permet de créer une session classique et
  une session TAR sans assistance.

### NT-100

- Le référentiel est versionné et testable indépendamment de l'interface.
- L'utilisateur peut consulter les règles utiles de l'épreuve sélectionnée.
- Code, nom complet et saison sont visibles sans ambiguïté.

### NT-101

- Les séries générées expliquent type, coups, distance, cible, temps et scoring.
- Le remplacement de séries existantes demande une confirmation explicite.
- Les essais sont clairement identifiés et exclus du score.
- Les données TAR restent compréhensibles dans le détail après redémarrage.

### NT-073

- La normalisation réduit les doublons sans modifier une saisie inconnue.
- Le dernier calibre est repris de manière prévisible et reste modifiable.
- Cette reprise n'ajoute aucune étape au parcours.

### NT-130

- Sans modèle disponible, `+` ouvre directement la création standard.
- Avec des modèles disponibles, leurs noms et contenus sont explicites.
- La création depuis un modèle apporte un gain mesurable d'actions.
- L'ajout, l'utilisation et la suppression d'un favori sont testés, sans écran
  d'erreur.

## Stratégie de reprise

1. Repartir d'une branche créée depuis `dev`.
2. Produire et valider les parcours avant le code.
3. Découper l'implémentation : référentiel métier, expérience TAR, puis saisie
   rapide, au lieu d'exposer les quatre items simultanément.
4. Tester chaque incrément sur les parcours classique et TAR.
5. Mettre à jour le cahier de recette avant la PR.
6. Ne réutiliser du prototype abandonné que des idées ou données revues
   explicitement ; aucun cherry-pick global.

