# NexTarget

<!-- SonarCloud Badges -->
![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=alert_status)
![Coverage](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=coverage)
![Maintainability](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=sqale_rating)
![Reliability](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=reliability_rating)
![Security](https://sonarcloud.io/api/project_badges/measure?project=clementseguy_NexTarget-app&metric=security_rating)

Application mobile pour suivre et analyser les entraînements de tir sportif (NexTarget).

## Fonctionnalités principales
- Suivi des sessions de tir (date, arme, calibre, séries...)
- Statistiques générales (points, groupement, etc.)
- Interface sombre, logo applicatif
- Stockage local, aucune authentification

## Lancer le projet

1. Installer Flutter : https://docs.flutter.dev/get-started/install
2. Installer les dépendances :
   flutter pub get
3. Lancer sur un émulateur ou appareil Android :
   flutter run

## Coach IA (connecté uniquement — NT-061)

Depuis la v0.5.0, l'analyse coach passe **exclusivement** par NexTarget-server
(`POST /coach/analyze-session`, JWT requis). Le serveur détient la clé Mistral et
le prompt : **aucune clé API ni secret côté client**, y compris dans les builds.
Sans compte, la section « Analyse Coach » affiche un message clair et un bouton
de connexion ; le reste de l'app (carnet, stats, objectifs, exercices) fonctionne
100 % hors-ligne.

L'URL du serveur se configure dans `assets/config.yaml` (`auth.base_url`).
Pour une recette contre un serveur local : `base_url: "http://localhost:8000"`
+ `adb reverse tcp:8000 tcp:8000` (ne pas committer cette valeur).

## Exemple de configuration

Un fichier `assets/config.example.yaml` est fourni comme modèle.

## Cahier de Recette (tests manuels)

- Document: `docs/tests/cahier_recette.md`
- Source (inventaire): `docs/tests/cahier_recette.yaml`
- Objectif: vérifier manuellement les fonctionnalités principales après refactor/évolutions.

Mise à jour / génération:

```bash
# depuis la racine du repo
dart run scripts/generate_cahier_recette.dart
```

Avant toute MR vers `main`:
- Jouer le cahier de recette (tests manuels) et s’assurer que les résultats attendus sont conformes.
- Si une fonctionnalité change: mettre à jour `docs/tests/cahier_recette.yaml`, régénérer le Markdown, et committer.

## Qualité / Pré-commit

Un script d'assurance basique avant commit : `scripts/verify_before_commit.sh`

Usage :
```
./scripts/verify_before_commit.sh         # analyse + tous les tests
./scripts/verify_before_commit.sh fast    # analyse + sous-ensemble rapide
```

Hook Git (optionnel) :
```
ln -sf ../../scripts/verify_before_commit.sh .git/hooks/pre-commit
```
Le hook empêchera le commit si l'analyse ou les tests échouent.

Lancement émulateur
```
adb emu kill
emulator -avd Pixel_8 -dns-server 8.8.8.8,8.8.4.4 &
flutter run -d emulator-5554
```