# Préférences et données locales

## Préférences de saisie

- La prise préférée préremplit les nouvelles séries.
- Le calibre par défaut doit appartenir au catalogue configuré. Il préremplit les nouvelles sessions mais ne modifie jamais les sessions existantes.
- Le ton du Coach est Neutre ou Cool.
- L'onboarding apparaît une seule fois et peut être rejoué depuis Paramètres.
- Les sections de Paramètres sont ordonnées ainsi : Préférences Tir, Sauvegardes & Portabilité, Coach IA, Thème, Aide. Dans Préférences Tir, la prise précède le râtelier puis le calibre par défaut.
- Le même séparateur et les mêmes espacements distinguent la prise du râtelier,
  puis le râtelier du calibre par défaut.

## Râtelier d'armes

Le râtelier contient des noms uniques après suppression des espaces de bord et comparaison sans tenir compte de la casse. Renommer une arme, après confirmation, propage le nouveau nom aux sessions prévues et réalisées correspondantes ; l'opération revient à l'état initial si une écriture échoue. Supprimer une arme du râtelier ne modifie jamais les sessions existantes.

## Sauvegarde JSON

Le format courant `mycoach-data`, version 6, exporte les sessions, objectifs,
armes et exercices. Chaque session porte un `sessionUuid` stable, son débrief
Coach structuré éventuel et un `exerciseId` facultatif ; chaque exercice porte
une provenance `personal` ou `coach_catalog`. Les identifiants Hive importés
sont remplacés pour éviter les collisions, tandis que le `sessionUuid` est
conservé afin d'identifier la même session côté serveur. Les anciens exports
restent acceptés : un UUID absent est généré, une ancienne analyse Markdown
reste lisible, le premier élément d'une liste `exercises` devient l'exercice
principal et un exercice sans provenance devient `personal`. Une difficulté
d'exercice absente ou inconnue est importée comme non renseignée.

Les exports temporaires partagés et les exports enregistrés dans un dossier
utilisent par défaut `nextarget_export_<timestamp>.json`. Ce nom n'affecte pas
le format JSON historique `mycoach-data`, et un nom explicitement choisi reste
prioritaire.

Dans Paramètres, l'export puis l'import sont regroupés sous « Sauvegardes & Portabilité ». L'avertissement sur l'absence de chiffrement clôt cette section.

Les objectifs invalides et les doublons d'armes sont ignorés pendant l'import. Le râtelier importé est fusionné avec le râtelier local, sans effacer les armes déjà présentes. La sauvegarde ne contient pas les jetons OAuth, les préférences ni les fichiers photo eux-mêmes ; les sessions ne stockent que leur chemin local de photo.
