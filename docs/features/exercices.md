# Exercices

Un exercice est conservé localement sur l'appareil. Il contient un nom, une catégorie, un type, une description facultative, une durée, du matériel, des consignes ordonnées, une priorité, une difficulté facultative, une provenance et les objectifs auxquels il contribue.

## Valeurs disponibles

- Catégories : Précision, Groupement, Vitesse, Technique, Mental et Physique.
- Types : Stand et Maison.
- Difficultés persistées : `beginner` (Débutant), `advanced` (Avancé) et `expert` (Expert).
- Provenances persistées : `personal` pour un exercice créé localement et `coach_catalog` pour un exercice fourni par le futur catalogue serveur.

Les anciennes catégories textuelles reconnues sont converties vers ces valeurs ; une valeur historique inconnue revient à Précision. Un ancien exercice sans type revient à Stand. Une difficulté absente ou inconnue reste « Non renseignée » : aucune valeur n'est déduite des autres caractéristiques. Un exercice historique ou importé sans provenance devient `personal` ; une provenance inconnue est rejetée.

## Règles fonctionnelles

- L'utilisateur peut créer et modifier un exercice, choisir ou effacer sa difficulté, le trier et lui associer plusieurs objectifs.
- La liste filtre la difficulté par Tous, Non renseignée, Débutant, Avancé ou Expert ; ce choix se combine aux filtres de catégorie et de type ainsi qu'au tri courant.
- Les consignes vides sont retirées lors de l'enregistrement.
- Seul un exercice de type Stand peut être transformé en session prévue.
- Une session référence zéro ou un exercice principal et l'historique peut être filtré par exercice.
- L'action « Supprimer » contrôle dans le service toutes les sessions, y compris les sessions libres, prévues, réalisées et les brouillons guidés. Toute référence bloque la suppression et le message indique le nombre de sessions à dissocier. Sans référence, une confirmation nommant l'exercice est exigée ; aucune session n'est modifiée en cascade.
- L'action « Dupliquer » ouvre un formulaire de création prérempli, difficulté et provenance comprises. Le nom reçoit le suffixe « (copie) » ; l'identifiant, la date de création et l'ordre sont ceux d'un nouvel exercice, avec des listes de consignes et d'objectifs indépendantes.
- Les sauvegardes historiques sans difficulté ni provenance restent importables. Les exports courants conservent ces champs ; une difficulté inconnue à l'import est normalisée à « Non renseignée » et une provenance inconnue est rejetée.
- Si un filtre d'historique pointe vers un exercice supprimé, l'écran revient à Tous les exercices.
