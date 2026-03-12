# Affichage des données utilisateur connecté

> **Version** : v0.4 — **Statut** : À développer

## Règles métier

- **Non connecté** : seul un bouton "Se connecter" est visible dans l'AppBar (à droite) des Paramètres (comportement existant, inchangé).
- **Connecté** : le bouton logout est remplacé par un `CircleAvatar` cliquable (photo ou initiale) qui ouvre la page Profil en modale.
- **Zéro stockage local** : toutes les données profil viennent de `AuthProvider._currentUser` (alimenté par `GET /users/me`). Aucune persistence Hive ajoutée.
- **Modification V1** : seul `experience_level` est modifiable. Le pseudo (`display_name`) reste en lecture seule.
- **Erreur réseau** : sur échec du `PATCH`, afficher un `SnackBar` d'erreur. Pas de mise à jour optimiste.
- **Theme-aware** : utiliser `Theme.of(context).colorScheme` partout (compatible Classique / France / ASCII).

---

## Contrat API

### `GET /users/me` → `UserPublic`

| Champ | Type | Nullable | Description |
|---|---|---|---|
| `id` | uuid | Non | Identifiant unique |
| `email` | string (email) | Non | Email utilisateur |
| `is_active` | boolean | Non | Compte actif |
| `provider` | `google` \| `facebook` | Non | Fournisseur OAuth |
| `display_name` | string | Oui | Nom affiché (initialisé depuis l'IdP) |
| `avatar_url` | string (uri) | Oui | Photo de profil (depuis l'IdP) |
| `experience_level` | `beginner` \| `advanced` \| `expert` | Oui | Niveau choisi par l'utilisateur |
| `created_at` | date-time | Non | Date d'inscription |

### `PATCH /users/me/profile` → `UserPublic`

| Champ body | Type | Description |
|---|---|---|
| `experience_level` | `beginner` \| `advanced` \| `expert` \| `null` | Niveau d'expérience (`null` pour réinitialiser) |

- Auth : `Authorization: Bearer <JWT>`
- Réponses : `200` (profil mis à jour), `401` (token invalide), `422` (validation error)

---

## Mapping données UI

| Champ UI | Source (`_currentUser`) | Modifiable V1 |
|---|---|---|
| Photo circulaire | `avatar_url` | Non |
| Nom affiché | `display_name` | Non |
| Email | `email` | Non |
| Niveau d'expérience | `experience_level` | **Oui** → `PATCH` |
| Date d'inscription | `created_at` | Non |
| Connexion via | `provider` | Non |

---

## Maquette ProfileScreen

```
┌─ AppBar ─────────────────────────┐
│  ←  Mon profil                   │
├──────────────────────────────────┤
│       ┌─────────┐               │
│       │  Photo  │  ← NetworkImage(avatar_url)
│       │  80x80  │    ou Icon(person) si null
│       └─────────┘               │
│     display_name                 │
│     email@gmail.com              │  ← style secondaire
│                                  │
│  ── Niveau d'expérience ──────── │
│  SegmentedButton:                │
│  [ Débutant | Confirmé | Expert ]│  ← PATCH au changement
│                                  │
│  ── Informations ─────────────── │
│  Membre depuis    15 janv. 2026  │
│  Connexion via    Google         │
│                                  │
│  [Se déconnecter]                │  ← bouton rouge/outline
└──────────────────────────────────┘
```

### Navigation

```
SettingsScreen AppBar
├── Non connecté → IconButton "Se connecter" (inchangé)
└── Connecté → CircleAvatar → tap → Navigator.push(ProfileScreen, fullscreenDialog)
```

---

## Architecture

```
AuthService (existant)
├── getUserInfo()         ← existant
└── updateProfile()       ← NOUVEAU : PATCH /users/me/profile

AuthProvider (existant)
├── _currentUser          ← existant
├── refreshUserInfo()     ← existant
└── updateExperienceLevel() ← NOUVEAU

ProfileScreen             ← NOUVEAU (lib/screens/profile_screen.dart)
└── context.watch<AuthProvider>().currentUser

SettingsScreen (modifié)
└── AppBar : CircleAvatar remplace IconButton(logout)
```

---

## Plan de développement

| # | Tâche | Fichier(s) | Description |
|---|---|---|---|
| 1 | `AuthService.updateProfile()` | `lib/services/auth_service.dart` | Méthode `PATCH /users/me/profile` avec body `{experience_level}` |
| 2 | `AuthProvider.updateExperienceLevel()` | `lib/providers/auth_provider.dart` | Appelle `updateProfile()` + `refreshUserInfo()` |
| 3 | Créer `ProfileScreen` | `lib/screens/profile_screen.dart` | Scaffold fullscreenDialog, avatar/nom/email/niveau/date, `SegmentedButton`, bouton déconnexion |
| 4 | Modifier AppBar Paramètres | `lib/screens/settings_screen.dart` | Connecté : `CircleAvatar` → ouvre ProfileScreen. Non connecté : inchangé. Retirer le bouton logout (migré dans ProfileScreen) |
| 5 | Tests widget ProfileScreen | `test/screens/profile_screen_test.dart` | Affichage infos, changement niveau, état non connecté |
| 6 | Tests `AuthService.updateProfile` | `test/services/auth_service_test.dart` | Mock HTTP pour `PATCH /users/me/profile` |

### Dépendances

```
1 → 2 → 3 ← 4
         ↓
       5, 6
```

Tâches 1→2→3 séquentielles. Tâche 4 en parallèle de 3. Tests (5, 6) à la fin.

---

## Points d'attention

- **`avatar_url` null** : `CircleAvatar` avec initiale de `display_name` ou `Icon(Icons.person)`
- **`experience_level` null** : aucun segment sélectionné dans le `SegmentedButton`
- **Erreur PATCH** : `SnackBar` d'erreur, pas de mise à jour optimiste
- **Déconnexion** : le bouton "Se déconnecter" migre de l'AppBar Paramètres vers le bas de ProfileScreen
