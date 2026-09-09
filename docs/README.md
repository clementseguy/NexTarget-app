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

- [Backlog unifié](backlog/backlog-unifie.md) : inventaire et statut des US actives.
- [Descriptions des US](backlog/descriptions.md) : définition fonctionnelle et critères d'acceptation.
- [Priorités](backlog/priorites.md) : ordre de réalisation courant, indépendant de l'inventaire.
- [Journal](backlog/journal/) : chronologie concise des décisions et livraisons significatives.
- [Archive](backlog/archive/) : US archivées, classées par année d'archivage.
- [Gouvernance](backlog/README.md) : statuts, Definition of Done et convention d'identifiants.
- [REX TAR et saisie rapide](backlog/details/rex-tar-saisie-rapide-2026-07-24.md) : lecture obligatoire avant de reprendre ce périmètre.
- [Référentiel TAR 25 m](backlog/details/referentiel-tar-25m.md) : détail préparatoire conservé pour NT-100.

Le dossier historique `specs` a été supprimé : les spécifications livrées étaient redondantes avec le code, les tests et les releases ; les intentions non livrées sont maintenant uniquement dans le backlog.

## Technique et validation

- [Build APK](tech/build_apk_guide.md).
- [Serveur local avec un émulateur Android](tech/serveur_local_emulateur_android.md).
- [Tests et recette](tests/README.md).
- [Notes de version](releases/).

Les captures et ressources sous `assets/` sont volontairement hors du périmètre de maintenance documentaire.

## Règles de maintenance

1. Modifier le statut uniquement dans `backlog/backlog-unifie.md`, la définition fonctionnelle dans `backlog/descriptions.md` et l'ordre de traitement dans `backlog/priorites.md`.
2. Mettre à jour la documentation fonctionnelle avec tout comportement visible modifié.
3. Mettre à jour `docs/tests/cahier_recette.yaml`, puis régénérer le Markdown pour tout parcours concerné.
4. Préparer dans la PR l'entrée du journal et le statut `FAIT` lorsqu'elle clôt une US ; ces changements deviennent canoniques à la fusion dans `dev`.
5. Ajouter une note dans `releases/` uniquement lors d'une release ; `CHANGELOG.md` conserve l'historique détaillé.
6. Ne pas conserver de brouillon obsolète dans la documentation active.
