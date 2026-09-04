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
- Le service sait supprimer un exercice sans supprimer les sessions associées, mais cette action n'est pas encore exposée dans l'interface ; elle reste suivie par NT-026.
- Si un filtre d'historique pointe vers un exercice supprimé, l'écran revient à Tous les exercices.
