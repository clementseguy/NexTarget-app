# Exercices

Un exercice est conservé localement sur l'appareil. Il contient un nom, une catégorie, un type, une description facultative, une durée, du matériel, des consignes ordonnées, une priorité, une difficulté facultative, une provenance et les objectifs auxquels il contribue.

## Valeurs disponibles

- Catégories : Précision, Groupement, Vitesse, Technique, Mental et Physique.
- Types : Stand et Maison.
- Difficultés persistées : `beginner` (Débutant), `advanced` (Avancé) et `expert` (Expert).
- Provenances persistées : `personal` pour un exercice créé localement et `coach_catalog` pour une copie locale fournie par le catalogue serveur.

Les anciennes catégories textuelles reconnues sont converties vers ces valeurs ; une valeur historique inconnue revient à Précision. Un ancien exercice sans type revient à Stand. Une difficulté absente ou inconnue reste « Non renseignée » : aucune valeur n'est déduite des autres caractéristiques. Un exercice historique ou importé sans provenance devient `personal` ; une provenance inconnue est rejetée.

## Règles fonctionnelles

- L'utilisateur peut créer et modifier un exercice, choisir ou effacer sa difficulté, le trier et lui associer plusieurs objectifs.
- La liste filtre la difficulté par Tous, Non renseignée, Débutant, Avancé ou Expert ; ce choix se combine aux filtres de catégorie et de type ainsi qu'au tri courant.
- Chaque carte de la liste présente le nom puis des puces compactes pour les objectifs, la catégorie, le type, la difficulté, le nombre de consignes et la durée. La description et le matériel restent réservés au formulaire ou au détail. Les icônes Exercice et Planifier sont affichées seules. Le type Stand reprend le bleu de Planifier, les objectifs et consignes sont jaunes, et la difficulté devient verte lorsqu'elle correspond au niveau d'expérience du profil. Le clic sur une carte personnelle ouvre son édition ; la colonne d'actions contient uniquement la planification éventuelle et le menu Dupliquer/Supprimer.
- Les consignes vides sont retirées lors de l'enregistrement.
- Seul un exercice de type Stand peut être transformé en session prévue.
- Une session référence zéro ou un exercice principal et l'historique peut être filtré par exercice.
- L'action « Supprimer » contrôle dans le service toutes les sessions, y compris les sessions libres, prévues, réalisées et les brouillons guidés. Toute référence bloque la suppression et le message indique le nombre de sessions à dissocier. Sans référence, une confirmation nommant l'exercice est exigée ; aucune session n'est modifiée en cascade.
- L'action « Dupliquer » d'un exercice personnel ouvre un formulaire de création prérempli, difficulté et provenance comprises. Le nom reçoit le suffixe « (copie) » ; l'identifiant, la date de création et l'ordre sont ceux d'un nouvel exercice, avec des listes de consignes et d'objectifs indépendantes.
- Les sauvegardes historiques sans difficulté ni provenance restent importables. Les exports courants conservent ces champs ; une difficulté inconnue à l'import est normalisée à « Non renseignée » et une provenance inconnue est rejetée.
- Si un filtre d'historique pointe vers un exercice supprimé, l'écran revient à Tous les exercices.
- Le catalogue Coach n'est jamais parcouru ni synchronisé globalement. L'app
  récupère un exercice actif uniquement à partir de son identifiant explicite et
  conserve sa copie dans la box Hive `exercises` pour la consultation hors ligne.
  Une actualisation remplace uniquement l'exercice Coach de même identifiant ;
  une absence, une réponse invalide, une erreur réseau ou une collision avec un
  exercice personnel laisse toutes les données locales inchangées.
- La liste et le détail en lecture seule identifient ces copies par « Créé par le
  Coach ». Leurs actions de modification et de suppression sont absentes et le
  service refuse également ces mutations. En build DEBUG, un bouton éclair dans
  la barre de la liste permet de simuler une future attribution en saisissant
  l'identifiant à récupérer ; aucun téléchargement ne démarre à l'ouverture.
