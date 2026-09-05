# Préférences et données locales

## Préférences de saisie

- La prise préférée préremplit les nouvelles séries.
- Le calibre par défaut doit appartenir au catalogue configuré. Il préremplit les nouvelles sessions mais ne modifie jamais les sessions existantes.
- Le ton du Coach est Neutre ou Cool.
- L'onboarding apparaît une seule fois et peut être rejoué depuis Paramètres.
- Les sections de Paramètres sont ordonnées ainsi : Préférences Tir, Sauvegardes & Portabilité, Coach IA, Thème, Aide. Dans Préférences Tir, la prise précède le râtelier puis le calibre par défaut.

## Râtelier d'armes

Le râtelier contient des noms uniques après suppression des espaces de bord et comparaison sans tenir compte de la casse. Renommer une arme, après confirmation, propage le nouveau nom aux sessions prévues et réalisées correspondantes ; l'opération revient à l'état initial si une écriture échoue. Supprimer une arme du râtelier ne modifie jamais les sessions existantes.

## Sauvegarde JSON

Le format courant `mycoach-data`, version 3, exporte les sessions, objectifs et armes. Les sessions sont validées avant une insertion groupée ; leurs identifiants importés sont remplacés pour éviter les collisions. Les anciens exports sans objectifs, armes ou discriminant de session restent acceptés.

Dans Paramètres, l'export puis l'import sont regroupés sous « Sauvegardes & Portabilité ». L'avertissement sur l'absence de chiffrement clôt cette section.

Les objectifs invalides et les doublons d'armes sont ignorés pendant l'import. Le râtelier importé est fusionné avec le râtelier local, sans effacer les armes déjà présentes. La sauvegarde ne contient pas les jetons OAuth, les préférences ni les fichiers photo eux-mêmes ; les sessions ne stockent que leur chemin local de photo.
