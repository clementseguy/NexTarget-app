#!/usr/bin/env bash
set -euo pipefail

#############################################
# Script de build APK NexTarget
# - Support release (défaut) et debug (--debug)
# - Lecture automatique de la version (pubspec.yaml)
# - Renommage: NexTarget-v<version>-<mode>-<timestamp>.apk
#
# NT-061 : plus aucune clé Mistral côté client — l'analyse coach passe
# par NexTarget-server (aucun secret à injecter au build).
#
# Usage:
#   ./build_apk.sh                 # build release
#   ./build_apk.sh --debug         # build debug
#
# Options:
#   --debug          Mode debug (sinon release)
#   --flavor <f>     (réservé future extension flavors)
#
# Exemples noms générés:
#   NexTarget-v0.4.0-release-20251017-1432.apk
#   NexTarget-v0.4.0-debug-20251017-1434.apk
#############################################

BUILD_MODE="release" # ou debug
FLAVOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      BUILD_MODE="debug"; shift ;;
    --flavor)
      FLAVOR="$2"; shift 2 ;;
    *) echo "Option inconnue: $1"; exit 1 ;;
  esac
done

echo "==> Vérification environnement Flutter"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter introuvable dans le PATH" >&2
  exit 3
fi

# Optionnel: nettoyage
# flutter clean

echo "==> Récupération des dépendances"
flutter pub get

echo "==> Lecture version application"
if [[ ! -f pubspec.yaml ]]; then
  echo "pubspec.yaml introuvable" >&2; exit 5
fi
APP_VERSION=$(grep -E '^version:' pubspec.yaml | head -n1 | awk '{print $2}')
if [[ -z "$APP_VERSION" ]]; then
  echo "Impossible de déterminer la version" >&2; exit 6
fi
echo "Version détectée: $APP_VERSION"

echo "==> Préparation commande build ($BUILD_MODE)"
if [[ "$BUILD_MODE" == "release" ]]; then
  CMD=(flutter build apk --release)
else
  CMD=(flutter build apk --debug)
fi

if [[ -n "$FLAVOR" ]]; then
  CMD+=(--flavor "$FLAVOR")
fi

echo "==> Commande: ${CMD[*]}"
"${CMD[@]}"

APK_DIR="build/app/outputs/flutter-apk"

if [[ "$BUILD_MODE" == "release" ]]; then
  RAW_NAME="app-release.apk"
else
  RAW_NAME="app-debug.apk"
fi

APK_PATH="$APK_DIR/$RAW_NAME"
if [[ -f "$APK_PATH" ]]; then
  TS=$(date +%Y%m%d-%H%M)
  TARGET_NAME="NexTarget-v${APP_VERSION}-${BUILD_MODE}-${TS}.apk"
  mv -f "$APK_PATH" "$APK_DIR/$TARGET_NAME"
  SIZE=$(du -h "$APK_DIR/$TARGET_NAME" | cut -f1)
  echo -e "\nAPK généré: $APK_DIR/$TARGET_NAME ($SIZE)"
else
  echo "Échec: APK introuvable à $APK_PATH" >&2
  exit 4
fi

echo "Terminé."
