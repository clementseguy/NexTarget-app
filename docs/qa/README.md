# Processus de recette automatisée

La recette Android de NexTarget est exécutée par l'agent Hermes **Yvain**. Son
code, son prompt, ses scripts et sa configuration vivent hors de ce dépôt. Ce dépôt reste la source de vérité fonctionnelle :

- les US livrées sont déclarées dans les lignes ajoutées à `CHANGELOG.md` ;
- le cahier de recette source reste `docs/tests/cahier_recette.yaml` ;
- chaque évolution visible conserve ses tests Flutter habituels.

Yvain sélectionne les IDs `NT-XXX` depuis le diff du changelog, puis exécute
uniquement les scénarios déclarés dans son manifeste externe. Les US
exclusivement serveur sont hors périmètre de la recette mobile ; une US
app+serveur garde un scénario mobile.

La campagne de recette s'exécute sur `staging`, après fusion de `dev` et avant
la fusion de `staging` dans `main`.

Les rapports, captures et logs sont produits par Yvain. Les tickets GitHub sont
préparés à partir de deux échecs reproductibles après remise à zéro ; leur
publication est une action explicitement validée par un humain.
