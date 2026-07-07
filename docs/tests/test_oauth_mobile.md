# Test Manuel - Authentification OAuth Mobile

## Prérequis

- Backend déployé sur `https://nextarget-server.onrender.com`
- Endpoint `/auth/google/login` fonctionnel
- Backend configuré pour rediriger vers `nextarget://callback?token=XYZ`
- App installée sur émulateur/device Android ou iOS

## Cas de test

### ✅ Cas 1 : Connexion réussie (Happy Path)

**Étapes** :
1. Lancer l'app → Écran de login s'affiche
2. Cliquer sur "Se connecter avec Google"
3. **Vérifier** : Navigateur in-app s'ouvre sur la page Google
4. Sélectionner un compte Google
5. **Vérifier** : Page de consentement s'affiche
6. Cliquer sur "Continuer" / "Continue"
7. **Vérifier** : L'app se ferme et revient automatiquement
8. **Vérifier** : L'écran d'accueil (dashboard) s'affiche
9. **Vérifier** : Les statistiques/données utilisateur sont visibles

**Logs attendus** :
```
[AUTH] 🚀 Ouverture du flow OAuth: https://nextarget-server.onrender.com/auth/google/login
[AUTH] 📱 Callback attendu: nextarget://callback?token=...
[AUTH] ✅ Callback reçu: nextarget://callback?token=eyJhbGc...
[AUTH] ✅ Token stocké en sécurité
[AUTH_SERVICE] 📡 Récupération des infos utilisateur...
[AUTH_SERVICE] ✅ Infos utilisateur récupérées: user@example.com
[AUTH] ✅ Authentification réussie: user@example.com
[AUTH_PROVIDER] ✅ Authentification Google réussie
[AUTH_PROVIDER] 👤 Utilisateur connecté: user@example.com
[AUTH_PROVIDER] 🔔 Notification des listeners (isAuthenticated=true)
[AUTH_GATE] 🔄 Rebuild du Consumer<AuthProvider>
[AUTH_GATE] ✅ Navigation vers l'application
```

**Validation** :
- [ ] Aucune erreur visible
- [ ] Transition fluide vers le dashboard
- [ ] Token stocké dans flutter_secure_storage
- [ ] Email récupéré et affiché (si applicable)

---

### ❌ Cas 2 : Erreur backend

**Simulation** : Backend renvoie `nextarget://callback?error=invalid_request`

**Étapes** :
1. Lancer l'app → Écran de login
2. Cliquer sur "Se connecter avec Google"
3. Simuler une erreur (ex: fermer Google avant consentement)
4. **Vérifier** : Message d'erreur s'affiche
5. **Vérifier** : Reste sur l'écran de login

**Logs attendus** :
```
[AUTH] ✅ Callback reçu: nextarget://callback?error=invalid_request
[AUTH] ❌ Erreur du backend: invalid_request
[AUTH] ❌ Erreur lors de l'authentification: Exception: Erreur d'authentification: invalid_request
[LOGIN_SCREEN] ❌ Erreur d'authentification: Exception: Erreur d'authentification: invalid_request
```

**Validation** :
- [ ] Message d'erreur clair affiché
- [ ] Pas de crash
- [ ] Reste sur écran de login
- [ ] Peut retenter la connexion

---

### ❌ Cas 3 : Annulation utilisateur

**Étapes** :
1. Lancer l'app → Écran de login
2. Cliquer sur "Se connecter avec Google"
3. **Fermer le navigateur** avant de sélectionner un compte
4. **Vérifier** : Message "User canceled login"
5. **Vérifier** : Reste sur l'écran de login

**Logs attendus** :
```
[AUTH] ❌ Erreur lors de l'authentification: PlatformException(CANCELED, User canceled login, null, null)
[LOGIN_SCREEN] ❌ Erreur d'authentification: PlatformException(CANCELED, User canceled login, null, null)
```

**Validation** :
- [ ] Pas de crash
- [ ] Reste sur écran de login
- [ ] Peut retenter la connexion

---

### ✅ Cas 4 : Token persistant (relance app)

**Étapes** :
1. Se connecter avec succès (Cas 1)
2. **Fermer l'app complètement** (kill process)
3. **Relancer l'app**
4. **Vérifier** : Dashboard s'affiche directement (pas d'écran de login)
5. **Vérifier** : Données utilisateur présentes

**Logs attendus** :
```
[AUTH_GATE] 🚪 Vérification de l'authentification au démarrage...
[AUTH_PROVIDER] 🔍 Vérification du statut d'authentification...
[AUTH_PROVIDER] Token présent: true
[AUTH_SERVICE] 🔍 Vérification du token auprès de https://nextarget-server.onrender.com/users/me
[AUTH_SERVICE] ✅ Token valide
[AUTH_PROVIDER] ✅ Utilisateur authentifié: user@example.com
[AUTH_GATE] ✅ Navigation vers l'application
```

**Validation** :
- [ ] Pas d'écran de login
- [ ] Dashboard directement visible
- [ ] Token toujours valide

---

### 🔐 Cas 5 : Déconnexion

**Étapes** :
1. Se connecter avec succès
2. Aller dans **Paramètres**
3. Cliquer sur **Déconnexion**
4. **Vérifier** : Retour sur écran de login
5. **Vérifier** : Relancer l'app → Écran de login s'affiche

**Logs attendus** :
```
[AUTH_PROVIDER] 🔓 Déconnexion de l'utilisateur...
[AUTH_SERVICE] 🧹 Suppression du token et de l'email du stockage sécurisé
[AUTH_SERVICE] ✅ Données d'authentification supprimées
[AUTH_PROVIDER] ✅ Utilisateur déconnecté
```

**Validation** :
- [ ] Token supprimé
- [ ] Email supprimé
- [ ] Retour sur login
- [ ] Relance app → login affiché

---

## Tests de stabilité

### Test A : Connexions multiples successives
- Connexion → Déconnexion → Reconnexion (x5)
- **Vérifier** : Pas de fuite mémoire, pas de crash

### Test B : Rotation écran pendant OAuth
- Lancer OAuth → Tourner device → Continuer
- **Vérifier** : Flow OAuth continue normalement

### Test C : Connexion réseau coupée
- Couper WiFi/4G → Tenter connexion
- **Vérifier** : Message d'erreur réseau clair

---

## Commandes de test

### Android - Tester deep link manuellement
```bash
# Simuler un callback de succès
adb shell am start -W -a android.intent.action.VIEW \
  -d "nextarget://callback?token=test_token_123" \
  com.example.tir_sportif

# Simuler un callback d'erreur
adb shell am start -W -a android.intent.action.VIEW \
  -d "nextarget://callback?error=access_denied" \
  com.example.tir_sportif
```

### iOS - Tester deep link manuellement
```bash
# Simuler un callback de succès
xcrun simctl openurl booted "nextarget://callback?token=test_token_123"

# Simuler un callback d'erreur
xcrun simctl openurl booted "nextarget://callback?error=access_denied"
```

---

## Checklist finale

- [ ] Cas 1 : Connexion réussie ✅
- [ ] Cas 2 : Erreur backend ❌
- [ ] Cas 3 : Annulation utilisateur ❌
- [ ] Cas 4 : Token persistant ✅
- [ ] Cas 5 : Déconnexion 🔐
- [ ] Test A : Connexions multiples
- [ ] Test B : Rotation écran
- [ ] Test C : Pas de réseau
- [ ] Deep links Android testés
- [ ] Deep links iOS testés (si applicable)

---

## Rollback si échec

En cas de problème bloquant :

```bash
# Restaurer l'ancienne version
git checkout HEAD~1 -- lib/services/auth_service.dart
git checkout HEAD~1 -- assets/config.yaml
flutter clean
flutter pub get
flutter run
```
