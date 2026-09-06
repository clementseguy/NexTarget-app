# Exercices

Un exercice est local à l'appareil. Il contient un nom, une catégorie, un type, une description facultative, une durée, du matériel, des consignes ordonnées, une priorité, une difficulté facultative et les objectifs auxquels il contribue.

## Valeurs disponibles

- Catégories : Précision, Groupement, Vitesse, Technique, Mental et Physique.
- Types : Stand et Maison.
- Difficultés persistées : `beginner` (Débutant), `advanced` (Avancé) et `expert` (Expert).

Les anciennes catégories textuelles reconnues sont converties vers ces valeurs ; une valeur historique inconnue revient à Précision. Un ancien exercice sans type revient à Stand. Une difficulté absente ou inconnue reste « Non renseignée » : aucune valeur n'est déduite des autres caractéristiques.

## Règles fonctionnelles

- L'utilisateur peut créer et modifier un exercice, choisir ou effacer sa difficulté, le trier et lui associer plusieurs objectifs.
- La liste filtre la difficulté par Tous, Non renseignée, Débutant, Avancé ou Expert ; ce choix se combine aux filtres de catégorie et de type ainsi qu'au tri courant.
- Les consignes vides sont retirées lors de l'enregistrement.
- Seul un exercice de type Stand peut être transformé en session prévue.
- Une session peut référencer plusieurs exercices et l'historique peut être filtré par exercice.
- L'action « Supprimer » contrôle dans le service toutes les sessions, y compris les sessions libres, prévues, réalisées et les brouillons guidés. Toute référence bloque la suppression et le message indique le nombre de sessions à dissocier. Sans référence, une confirmation nommant l'exercice est exigée ; aucune session n'est modifiée en cascade.
- L'action « Dupliquer » ouvre un formulaire de création prérempli, difficulté comprise. Le nom reçoit le suffixe « (copie) » ; l'identifiant, la date de création et l'ordre sont ceux d'un nouvel exercice, avec des listes de consignes et d'objectifs indépendantes.
- Les sauvegardes historiques sans difficulté restent importables. Les exports courants conservent la difficulté et une valeur inconnue à l'import est normalisée à « Non renseignée ».
- Si un filtre d'historique pointe vers un exercice supprimé, l'écran revient à Tous les exercices.
