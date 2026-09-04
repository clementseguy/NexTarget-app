# Documentation NexTarget App

Cette documentation décrit le produit actuellement livré. Le code et les tests restent la référence d'exécution ; le backlog est la référence des intentions et des évolutions.

## Produit

- [Sessions](features/sessions.md) : sessions détaillées, prévues, réalisées et libres.
- [Statistiques](features/statistiques.md) : populations, fenêtres et formules affichées.
- [Objectifs](features/objectifs.md) : métriques, progression, atteinte et tendance.
- [Exercices](features/exercices.md) : catalogue, associations et planification.
- [Compte et Coach IA](features/compte-et-coach.md) : OAuth optionnel, renouvellement et analyse connectée.
- [Préférences et données](features/preferences-et-donnees.md) : râtelier, réglages et sauvegardes.

Ces fichiers ne doivent décrire que l'existant. Toute fonctionnalité future appartient au backlog.

## Pilotage produit

- [Backlog unifié](backlog/backlog-unifie.md) : source de vérité produit.
- [Vue app](backlog/vue-app.md) et [vue serveur](backlog/vue-serveur.md) : projections à maintenir après le backlog.
- [Plan de sprints](backlog/plan-sprints.md) : ordre de réalisation courant.
- [Gouvernance](backlog/README.md) : statuts, Definition of Done et convention d'identifiants.
- [REX TAR et saisie rapide](backlog/rex-tar-saisie-rapide-2026-07-24.md) : lecture obligatoire avant de reprendre ce périmètre.
- [Référentiel TAR 25 m](backlog/details/referentiel-tar-25m.md) : détail préparatoire conservé pour NT-100.

Le dossier historique `specs` a été supprimé : les spécifications livrées étaient redondantes avec le code, les tests et les releases ; les intentions non livrées sont maintenant uniquement dans le backlog.

## Technique et validation

- [Build APK](tech/build_apk_guide.md).
- [Serveur local avec un émulateur Android](tech/serveur_local_emulateur_android.md).
- [Tests et recette](tests/README.md).
- [Notes de version](releases/).

Les captures et ressources sous `assets/` sont volontairement hors du périmètre de maintenance documentaire.

## Règles de maintenance

1. Modifier le backlog unifié avant ses vues.
2. Mettre à jour la documentation fonctionnelle avec tout comportement visible modifié.
3. Mettre à jour `docs/tests/cahier_recette.yaml`, puis régénérer le Markdown pour tout parcours concerné.
4. Ajouter une note dans `releases/` uniquement lors d'une release ; `CHANGELOG.md` conserve l'historique détaillé.
5. Ne pas conserver de brouillon obsolète dans la documentation active.
