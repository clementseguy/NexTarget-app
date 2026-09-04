# Guide de Test Manuel - Authentification OAuth Google

## Vue d'ensemble

Ce document décrit les étapes de test manuel pour l'authentification OAuth2 avec Google dans NexTarget.

## Prérequis

1. **Serveur backend** : `https://nextarget-server.onrender.com` doit être accessible
2. **Configuration** : `assets/config.yaml` doit contenir la section `auth`
3. **Appareils** : Tests sur iOS (simulateur + device) et Android (emulateur + device)

## Configuration de Test

### Test avec authentification obligatoire (Production)

```yaml
# assets/config.yaml
auth:
  enabled: true
  base_url: "https://nextarget-server.onrender.com"
  callback_scheme: "nextarget"
```

### Test avec authentification optionnelle (Développement)

```yaml
# assets/config.local.yaml (non versionné)
auth:
  enabled: false
  base_url: "http://localhost:3000"  # ou serveur de dev
  callback_scheme: "nextarget"
```

## Scénarios de Test

### 1. Premier lancement (aucun token stocké)

**Étapes :**
1. Supprimer l'app et réinstaller (ou vider les données)
2. Lancer l'app
3. Vérifier l'affichage du LoginScreen

**Résultat attendu :**
- LoginScreen affiché avec :
  - Icône de verrouillage
  - Titre "NexTarget"
  - Message "Connecte-toi pour synchroniser tes données"
  - Bouton "Se connecter avec Google"
  - Bouton "Continuer sans compte" (si `auth.enabled=false`)

**Capture d'écran recommandée :** LoginScreen initial

---

### 2. Flow OAuth complet (authentification réussie)

**Étapes :**
1. Sur LoginScreen, appuyer sur "Se connecter avec Google"
2. Vérifier l'ouverture du navigateur in-app
3. S'authentifier avec un compte Google valide
4. Vérifier la redirection automatique vers l'app

**Résultat attendu :**
- Navigateur in-app s'ouvre avec l'écran Google OAuth
- Après authentification, navigateur se ferme automatiquement
- Dashboard s'affiche (écran principal avec BottomNavigationBar)
- Logs dans la console :
  ```
  [AUTH] Demande de l URL OAuth au serveur...
  [AUTH] Ouverture du navigateur in-app...
  [AUTH] Callback intercepte
  [AUTH] Authentification reussie et token stocke
  ```

**Vérifications supplémentaires :**
- Token JWT stocké dans flutter_secure_storage
- Email stocké dans flutter_secure_storage
- `AuthProvider.isAuthenticated` = true

**Captures d'écran recommandées :**
- Google OAuth screen
- Dashboard après login

---

### 3. Déconnexion

**Étapes :**
1. Aller dans Paramètres (onglet Settings dans BottomNavigationBar)
2. Vérifier la présence de l'icône de déconnexion dans l'AppBar
3. Appuyer sur l'icône logout
4. Confirmer la déconnexion dans la popup

**Résultat attendu :**
- Popup de confirmation affichée
- Après confirmation, retour au LoginScreen
- Token et email supprimés du stockage
- Log dans la console : (aucun log spécifique de déconnexion actuellement)

**Capture d'écran recommandée :** Popup de confirmation de déconnexion

---

### 4. Relance avec token valide

**Étapes :**
1. Se connecter avec Google (voir scénario 2)
2. Fermer complètement l'app (kill process)
3. Relancer l'app

**Résultat attendu :**
- Écran de chargement (CircularProgressIndicator) brièvement affiché
- Dashboard affiché directement (pas de LoginScreen)
- Log dans la console : (pas de log spécifique pour ce cas)

---

### 5. Feature flag : bouton Skip (auth.enabled=false)

**Étapes :**
1. Modifier `assets/config.yaml` : `auth.enabled: false`
2. Supprimer l'app et réinstaller (ou vider données)
3. Lancer l'app
4. Vérifier la présence du bouton "Continuer sans compte"
5. Appuyer sur "Continuer sans compte"

**Résultat attendu :**
- Bouton "Continuer sans compte" visible sous le bouton Google
- Dashboard s'affiche après avoir appuyé sur Skip
- Aucun token stocké
- Icône logout **invisible** dans SettingsScreen (car `authProvider.isAuthenticated=false`)

---

### 6. Annulation du flow OAuth

**Étapes :**
1. Sur LoginScreen, appuyer sur "Se connecter avec Google"
2. Une fois le navigateur in-app ouvert, fermer manuellement sans s'authentifier (bouton X ou retour)

**Résultat attendu :**
- Retour au LoginScreen
- SnackBar rouge avec message d'erreur affiché
- Aucun token stocké

**Capture d'écran recommandée :** SnackBar d'erreur

---

### 7. Erreur réseau (backend inaccessible)

**Étapes :**
1. Couper la connexion réseau ou mettre `base_url` invalide dans config
2. Sur LoginScreen, appuyer sur "Se connecter avec Google"

**Résultat attendu :**
- CircularProgressIndicator affiché brièvement
- SnackBar rouge avec message d'erreur réseau
- Log d'erreur dans la console :
  ```
  [AUTH] Erreur lors de l authentification: <détails>
  ```

---

### 8. Token expiré (simulation)

**Étapes :**
1. Se connecter normalement
2. Modifier manuellement le token stocké pour le rendre invalide (via flutter_secure_storage debug tools)
3. Relancer l'app

**Résultat attendu :**
- App détecte le token invalide lors de `checkAuthStatus()`
- Token supprimé automatiquement
- LoginScreen affiché

**Note :** Ce scénario est difficile à tester manuellement. Privilégier les tests unitaires.

---

## Checklist de Test Complet

### iOS

- [ ] Scénario 1 : Premier lancement
- [ ] Scénario 2 : OAuth réussi
- [ ] Scénario 3 : Déconnexion
- [ ] Scénario 4 : Relance avec token valide
- [ ] Scénario 5 : Bouton Skip (auth.enabled=false)
- [ ] Scénario 6 : Annulation OAuth
- [ ] Scénario 7 : Erreur réseau

### Android

- [ ] Scénario 1 : Premier lancement
- [ ] Scénario 2 : OAuth réussi
- [ ] Scénario 3 : Déconnexion
- [ ] Scénario 4 : Relance avec token valide
- [ ] Scénario 5 : Bouton Skip (auth.enabled=false)
- [ ] Scénario 6 : Annulation OAuth
- [ ] Scénario 7 : Erreur réseau

---

## Debug et Troubleshooting

### Vérifier le token stocké

**iOS (simulateur) :**
```bash
# Trouver le bundle ID de l'app
xcrun simctl listapps booted | grep tir_sportif

# Accéder au container de l'app
open ~/Library/Developer/CoreSimulator/Devices/<DEVICE_ID>/data/Containers/Data/Application/<APP_ID>/
```

**Android (device avec adb) :**
```bash
# Vérifier le fichier de stockage (nécessite root ou app debuggable)
adb shell run-as com.example.tir_sportif ls files/
```

**Alternative (tous les OS) :** Ajouter temporairement des logs dans `AuthService.getToken()` pour afficher le token en clair.

### Logs utiles

Ajouter ces logs dans `AuthService` si besoin de debug :

```dart
print('[AUTH] Token récupéré: ${token?.substring(0, 20)}...');
print('[AUTH] Email récupéré: $email');
print('[AUTH] Token supprimé lors du logout');
```

### Erreurs courantes

**1. `PlatformException: Error while reading from the storage`**
- Cause : flutter_secure_storage non initialisé correctement
- Solution : Vérifier AndroidManifest.xml et Info.plist

**2. `No host specified in URI nextarget://callback#...`**
- Cause : URL scheme mal configuré
- Solution : Vérifier intent-filter (Android) et CFBundleURLTypes (iOS)

**3. `Connection refused`**
- Cause : Backend inaccessible ou mauvaise URL
- Solution : Vérifier `auth.base_url` dans config.yaml

---

## Tests Automatisés

En complément des tests manuels, lancer les tests unitaires :

```bash
flutter test test/services/auth_service_test.dart
flutter test test/services/authenticated_http_client_test.dart
```

---

## Annexe : Captures d'écran recommandées

1. **LoginScreen initial** (auth.enabled=true)
2. **LoginScreen avec bouton Skip** (auth.enabled=false)
3. **Google OAuth screen** (navigateur in-app)
4. **Dashboard après login**
5. **Settings avec icône logout**
6. **Popup de confirmation de déconnexion**
7. **SnackBar d'erreur** (annulation OAuth)

---

**Dernière mise à jour :** [Date de génération]
**Auteur :** GitHub Copilot
**Version OAuth :** v1.0 (flutter_web_auth_2)
