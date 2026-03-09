# Tests Manuels - Authentification Optionnelle

## Contexte
L'authentification est maintenant optionnelle. L'utilisateur peut utiliser l'app sans se connecter et peut se connecter/déconnecter depuis l'écran Paramètres.

## Modifications apportées

### Changements fonctionnels
1. **Démarrage de l'app** : L'utilisateur arrive directement sur l'onglet "Tableau de bord" (stats) au lieu de l'écran de login
2. **Bouton Login** : Ajout d'un bouton "Se connecter" dans la topbar de l'écran Paramètres (visible uniquement si non connecté)
3. **Bouton Logout** : Le bouton "Se déconnecter" dans la topbar de l'écran Paramètres est visible uniquement si connecté
4. **Pas de redirection** : Après déconnexion, l'utilisateur reste sur l'écran Paramètres avec un message de confirmation

### Changements techniques
- `_AuthGate` ne bloque plus sur `LoginScreen` si l'utilisateur n'est pas authentifié
- `NavigationProvider` démarre sur l'index 2 (Tableau de bord)
- `SettingsScreen` utilise maintenant `Consumer<AuthProvider>` pour réagir aux changements d'état d'authentification
- Tests unitaires mis à jour avec mock d'`AuthService`

---

## Scénarios de test

### ✅ Test 1 : Démarrage de l'app (utilisateur non connecté)

**Prérequis :**
- Aucun token stocké (ou application fraîchement installée)

**Étapes :**
1. Lancer l'application
2. Observer l'écran affiché

**Résultat attendu :**
- ✅ L'app démarre directement sur l'onglet "Tableau de bord" (3e icône sélectionnée)
- ✅ Pas d'écran de login affiché
- ✅ Toutes les fonctionnalités sont accessibles

**Logs console attendus :**
```
[AUTH_GATE] 🔄 Rebuild du Consumer<AuthProvider>
[AUTH_GATE] Consumer.builder appelé
[AUTH_GATE] isLoading=false, isAuthenticated=false
[AUTH_GATE] ✅ Navigation vers l'application (authentification optionnelle)
```

---

### ✅ Test 2 : Bouton Login visible dans Paramètres (non connecté)

**Prérequis :**
- Utilisateur non connecté

**Étapes :**
1. Naviguer vers l'onglet "Paramètres" (5e icône)
2. Observer la topbar (AppBar)

**Résultat attendu :**
- ✅ Un bouton avec l'icône "login" (flèche entrante) est visible dans la topbar à droite
- ✅ Le tooltip indique "Se connecter"
- ✅ Aucun bouton "logout" n'est visible

---

### ✅ Test 3 : Connexion depuis l'écran Paramètres

**Prérequis :**
- Utilisateur non connecté
- Backend NexTarget accessible (https://nextarget-server.onrender.com)

**Étapes :**
1. Aller dans "Paramètres"
2. Cliquer sur le bouton "login" dans la topbar
3. Compléter l'authentification Google dans le navigateur
4. Revenir à l'app après la redirection

**Résultat attendu :**
- ✅ Le navigateur s'ouvre sur la page d'authentification Google
- ✅ Après authentification réussie, retour à l'app
- ✅ Le bouton "login" disparaît de la topbar
- ✅ Un bouton "logout" apparaît à sa place dans la topbar
- ✅ Snackbar de confirmation (optionnel selon implémentation AuthProvider)

**Logs console attendus :**
```
[AUTH] Ouverture du navigateur pour OAuth...
[AUTH] ✅ Token stocké en sécurité
[AUTH] ✅ Authentification réussie: user@example.com
```

---

### ✅ Test 4 : Bouton Logout visible dans Paramètres (connecté)

**Prérequis :**
- Utilisateur connecté

**Étapes :**
1. Naviguer vers l'onglet "Paramètres"
2. Observer la topbar

**Résultat attendu :**
- ✅ Un bouton avec l'icône "logout" (flèche sortante) est visible dans la topbar à droite
- ✅ Le tooltip indique "Se deconnecter"
- ✅ Aucun bouton "login" n'est visible

---

### ✅ Test 5 : Déconnexion depuis l'écran Paramètres

**Prérequis :**
- Utilisateur connecté

**Étapes :**
1. Aller dans "Paramètres"
2. Cliquer sur le bouton "logout" dans la topbar
3. Une popup de confirmation apparaît
4. Cliquer sur "Deconnexion"

**Résultat attendu :**
- ✅ Popup de confirmation affichée avec titre "Deconnexion" et message "Voulez-vous vraiment vous deconnecter ?"
- ✅ Deux boutons : "Annuler" et "Deconnexion"
- ✅ Après confirmation, l'utilisateur reste sur l'écran Paramètres
- ✅ Un snackbar vert avec le message "Déconnexion réussie" s'affiche
- ✅ Le bouton "logout" disparaît de la topbar
- ✅ Le bouton "login" réapparaît dans la topbar

**Logs console attendus :**
```
[AUTH_PROVIDER] 🔓 Déconnexion de l'utilisateur...
[AUTH_SERVICE] 🧹 Suppression du token et de l'email du stockage sécurisé
```

---

### ✅ Test 6 : Annulation de la déconnexion

**Prérequis :**
- Utilisateur connecté

**Étapes :**
1. Aller dans "Paramètres"
2. Cliquer sur le bouton "logout"
3. Dans la popup, cliquer sur "Annuler"

**Résultat attendu :**
- ✅ La popup se ferme
- ✅ L'utilisateur reste connecté
- ✅ Le bouton "logout" reste visible
- ✅ Aucun snackbar ne s'affiche

---

### ✅ Test 7 : Persistance de la session après redémarrage (connecté)

**Prérequis :**
- Utilisateur connecté avec un token valide

**Étapes :**
1. Fermer complètement l'application (kill process)
2. Relancer l'application

**Résultat attendu :**
- ✅ L'app démarre sur l'onglet "Tableau de bord"
- ✅ L'utilisateur est toujours connecté (token persistant)
- ✅ Dans Paramètres, le bouton "logout" est visible

**Logs console attendus :**
```
[AUTH_GATE] 🚪 Vérification de l'authentification au démarrage...
[AUTH_PROVIDER] 🔍 Vérification du statut d'authentification...
[AUTH_PROVIDER] Token présent: true
[AUTH_SERVICE] ✅ Token valide
```

---

### ✅ Test 8 : Navigation entre les onglets (non connecté)

**Prérequis :**
- Utilisateur non connecté

**Étapes :**
1. Naviguer entre tous les onglets : Coach, Exercices, Tableau de bord, Sessions, Paramètres
2. Vérifier que toutes les fonctionnalités sont accessibles

**Résultat attendu :**
- ✅ Tous les onglets sont accessibles
- ✅ Aucune restriction de navigation
- ✅ Pas de redirection vers un écran de login

---

### ✅ Test 9 : Fonctionnalités de l'app sans authentification

**Prérequis :**
- Utilisateur non connecté

**Étapes :**
1. Créer une session de tir
2. Consulter les statistiques
3. Créer/modifier un exercice
4. Créer/modifier un objectif
5. Exporter les données
6. Importer des données

**Résultat attendu :**
- ✅ Toutes les fonctionnalités locales fonctionnent normalement
- ✅ Les données sont sauvegardées en local (Hive)
- ✅ Export/import fonctionnent

**Note :**
Les fonctionnalités nécessitant le backend (sync cloud, analyse coach avec API, etc.) peuvent afficher des messages appropriés si elles nécessitent l'authentification.

---

## Régression à vérifier

### Tests automatiques
```bash
flutter test
```

**Résultat attendu :**
- ✅ Tous les tests passent (204 tests)
- ✅ Aucune régression détectée

### Fonctionnalités existantes à retester
1. **Coach** : Analyse des sessions avec l'API coach
2. **Exercices** : CRUD des exercices
3. **Statistiques** : Cartes de synthèse, graphiques
4. **Sessions** : CRUD des sessions, filtres, tri
5. **Objectifs** : CRUD des objectifs, suivi de progression
6. **Backup** : Export/Import JSON

---

## Checklist de validation

Avant de considérer cette feature comme complète, vérifier :

- [x] L'app démarre sur l'onglet Tableau de bord
- [x] Bouton login visible dans Paramètres si non connecté
- [x] Bouton logout visible dans Paramètres si connecté
- [x] Connexion fonctionne depuis le bouton login
- [x] Déconnexion fonctionne depuis le bouton logout
- [x] Snackbar de confirmation après déconnexion
- [x] Pas de redirection vers /login après déconnexion
- [x] Tous les tests automatiques passent
- [x] Aucune régression fonctionnelle
- [x] Documentation mise à jour

---

## Notes techniques pour les développeurs

### Fichiers modifiés
- `lib/app/my_app.dart` : `_AuthGate` ne bloque plus sur `LoginScreen`
- `lib/screens/settings_screen.dart` : Ajout du bouton login et modification du bouton logout
- `lib/providers/navigation_provider.dart` : Démarre sur index 2 (inchangé, déjà configuré)
- `test/widget_test.dart` : Mock de `AuthService` pour les tests

### Architecture
- L'authentification reste gérée par `AuthProvider` et `AuthService`
- Le Consumer dans `SettingsScreen` permet de réagir aux changements d'état
- Les boutons login/logout sont conditionnels via `if (!authProvider.isAuthenticated)` et `if (authProvider.isAuthenticated)`

### Points d'attention pour futures évolutions
1. Si on ajoute des fonctionnalités nécessitant l'authentification obligatoire, gérer les cas où l'utilisateur n'est pas connecté
2. Le bouton login dans Paramètres est temporaire - prévoir un parcours UX complet plus tard
3. Considérer l'ajout d'un indicateur d'état de connexion ailleurs dans l'UI (ex: avatar dans l'AppBar)
