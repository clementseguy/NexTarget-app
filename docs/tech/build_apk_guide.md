# Guide de build APK NexTarget

## Vue d'ensemble

Le script `scripts/build_apk.sh` génère les APK de test ou de release de
l'application Flutter.

Depuis NT-061, l'application ne contient plus de clé, d'URL ou de prompt
Mistral. L'analyse Coach passe exclusivement par NexTarget-server et nécessite
un utilisateur connecté. Ne jamais réintroduire de secret ou de prompt Coach
dans le build mobile.

## Prérequis

1. Flutter SDK installé et disponible dans le `PATH`.
2. Dépendances récupérées avec `flutter pub get`.
3. Configuration non sensible éventuelle dans `assets/config.local.yaml`, par
   exemple une surcharge locale du référentiel de calibres.

`assets/config.local.yaml` est facultatif et non versionné. Il ne doit contenir
aucun secret.

## Génération

Build release :

```bash
./scripts/build_apk.sh
```

Build debug :

```bash
./scripts/build_apk.sh --debug
```

Le nom de l'APK est dérivé de la version déclarée dans `pubspec.yaml` et du mode
de build. Le script affiche son emplacement exact à la fin de l'exécution.

## Vérifications avant diffusion

```bash
flutter doctor
flutter pub get
bash scripts/verify_before_commit.sh
./scripts/build_apk.sh
```

Après installation sur un appareil :

1. vérifier le fonctionnement hors ligne du carnet, des statistiques, des
   exercices et des objectifs ;
2. vérifier la connexion Google ;
3. vérifier qu'une analyse Coach fonctionne une fois connecté ;
4. vérifier que le Coach affiche un état explicite sans réseau ou sans compte.

Aucune clé Mistral locale n'est nécessaire pour ces vérifications. Le serveur
porte la clé et les prompts dans ses variables d'environnement et ses assets
privés.

## Dépannage

### Le Coach est indisponible

Vérifier successivement :

- la connexion réseau ;
- l'authentification de l'utilisateur ;
- l'URL du serveur configurée dans `assets/config.yaml` ou sa surcharge locale ;
- la disponibilité de NexTarget-server.

Ne pas contourner une indisponibilité du serveur par un appel Mistral direct
depuis l'app.

### Version incorrecte dans le nom de l'APK

Vérifier la valeur `version:` dans `pubspec.yaml`, puis relancer le script.

### Configuration locale

Pour vérifier qu'une surcharge locale non sensible est bien prise en compte,
contrôler `assets/config.local.yaml` et sa déclaration dans les assets Flutter.
Ne jamais y placer de token, clé API ou identifiant secret.

## Sécurité

Ne pas versionner :

- `assets/config.local.yaml` ;
- les APK générés ;
- un fichier contenant un token, une clé API ou un secret.

La clé Mistral est configurée uniquement côté NexTarget-server, via les
variables d'environnement du déploiement.

---

**Dernière vérification** : 3 septembre 2026.
