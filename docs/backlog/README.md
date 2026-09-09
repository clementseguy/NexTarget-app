# Backlog NexTarget — Gouvernance

Ce dossier contient la source de vérité produit de NexTarget pour
l'application et le serveur.

## Fichiers

| Fichier | Rôle |
|---|---|
| [`backlog-unifie.md`](backlog-unifie.md) | Inventaire des US actives et source unique de leur statut. |
| [`descriptions.md`](descriptions.md) | Description fonctionnelle et critères d'acceptation des US actives. |
| [`priorites.md`](priorites.md) | Ordre de traitement courant : P0, P1, P2, P3 et Icebox. |
| [`journal/`](journal/) | Historique annuel et concis des décisions et livraisons significatives. |
| [`archive/`](archive/) | US livrées ou annulées, classées par année. |
| [`details/`](details/) | Référentiels et compléments durables liés aux US. |

## Cycle de vie

Les statuts autorisés sont `À FAIRE`, `EN COURS`, `FAIT` et `ANNULÉ`.

- Une US passe à `FAIT` lorsqu'elle est fusionnée dans `dev`.
- Une US remplacée passe à `ANNULÉ` et référence ses remplaçantes dans le
  tableau et dans sa description.
- Le statut n'est modifié que dans `backlog-unifie.md`.
- Le déplacement des US `FAIT` ou `ANNULÉ` dans l'archive est une tâche
  documentaire distincte. Elle inclut leur retrait éventuel de `priorites.md`.

## Identifiants

Les IDs `NT-XXX` sont globaux, stables et ne sont jamais réutilisés.

- Les anciennes plages thématiques sont abandonnées à partir de `NT-152`.
- Le prochain ID figure en tête de `backlog-unifie.md`.
- Créer une US et incrémenter ce compteur forment une seule modification.
- Les trous historiques ne sont pas réattribués.

## Priorisation

Une US peut être créée sans priorité. Son absence de `priorites.md` signifie
simplement qu'elle n'a pas encore été arbitrée.

- **P0** : immédiat — 2 US maximum fortement recommandé.
- **P1** : prochain — 5 US maximum fortement recommandé.
- **P2** : ultérieur.
- **P3** : opportunité.
- **Icebox** : pas envisagé actuellement.

MoSCoW est une analyse facultative conservée dans `backlog-unifie.md`. Elle
peut rester à `—` jusqu'à ce qu'un arbitrage soit utile. L'estimation `S`, `M`
ou `L` est également facultative.

## Mise à jour d'une US

- Création : ajouter la ligne dans `backlog-unifie.md`, ajouter la définition
  dans `descriptions.md`, puis incrémenter le prochain ID.
- Changement de statut : modifier uniquement `backlog-unifie.md`.
- Changement de priorité : modifier uniquement `priorites.md`.
- Changement fonctionnel : modifier uniquement `descriptions.md`, sauf si la
  portée, l'estimation ou MoSCoW évolue également.

## Traçabilité du développement

Référencer l'ID de l'US dans les branches, commits et PR. Les détails de
livraison restent dans les PR et changelogs ; `backlog-unifie.md` ne reçoit pas
de journal intermédiaire.

- Branche : `type/NT-XXX-slug-court`.
- Commit : inclure `NT-XXX` dans le sujet.
- PR : titre `[NT-XXX] …` et critères d'acceptation vérifiés dans le corps.

## Journal du backlog

Le dossier [`journal/`](journal/) conserve la chronologie des décisions produit
et des livraisons significatives, dans un fichier par année.

- Le journal est historique et ne constitue jamais une source du statut courant.
- Le statut courant existe uniquement dans `backlog-unifie.md`.
- Une entrée est ajoutée pour un cadrage matériel, une annulation ou une fusion
  dans `dev`.
- Les changements ordinaires `À FAIRE` vers `EN COURS`, ou inversement, ne sont
  pas journalisés.
- Une livraison est résumée en quelques lignes et renvoie vers la PR, le
  `CHANGELOG.md` ou la note de release.
- Les critères d'acceptation, fichiers modifiés et détails techniques déjà
  documentés ailleurs ne sont pas recopiés.
- Les entrées sont antéchronologiques et ne sont modifiées qu'en cas de
  correction factuelle.
- Le journal ne remplace ni [`priorites.md`](priorites.md), ni le changelog, ni
  les archives par US.

## Definition of Done

Une US peut être fusionnée dans `dev` lorsque ses critères d'acceptation sont
vérifiés, les tests et contrôles qualité concernés sont verts, la recette est
mise à jour si nécessaire et aucune règle de sécurité n'est régressée. La
fusion dans `dev` déclenche son passage à `FAIT`.

Les `AGENTS.md` restent la référence pour les conventions de code,
l'architecture et les règles de sécurité propres à chaque dépôt.
