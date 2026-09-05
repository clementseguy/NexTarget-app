# Exercices

Un exercice est local à l'appareil. Il contient un nom, une catégorie, un type, une description facultative, une durée, du matériel, des consignes ordonnées, une priorité et les objectifs auxquels il contribue.

## Valeurs disponibles

- Catégories : Précision, Groupement, Vitesse, Technique, Mental et Physique.
- Types : Stand et Maison.

Les anciennes catégories textuelles reconnues sont converties vers ces valeurs ; une valeur historique inconnue revient à Précision. Un ancien exercice sans type revient à Stand.

## Règles fonctionnelles

- L'utilisateur peut créer et modifier un exercice, le trier et lui associer plusieurs objectifs.
- Les consignes vides sont retirées lors de l'enregistrement.
- Seul un exercice de type Stand peut être transformé en session prévue.
- Une session peut référencer plusieurs exercices et l'historique peut être filtré par exercice.
- L'action « Supprimer » contrôle dans le service toutes les sessions, y compris les sessions libres, prévues, réalisées et les brouillons guidés. Toute référence bloque la suppression et le message indique le nombre de sessions à dissocier. Sans référence, une confirmation nommant l'exercice est exigée ; aucune session n'est modifiée en cascade.
- L'action « Dupliquer » ouvre un formulaire de création prérempli. Le nom reçoit le suffixe « (copie) » ; l'identifiant, la date de création et l'ordre sont ceux d'un nouvel exercice, avec des listes de consignes et d'objectifs indépendantes.
- Si un filtre d'historique pointe vers un exercice supprimé, l'écran revient à Tous les exercices.
