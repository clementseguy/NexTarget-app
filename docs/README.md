# Documentation NexTarget

## 📁 Organisation

### 📋 `specs/` - Spécifications des versions
Spécifications fonctionnelles et techniques des versions **en cours** ou **à venir**.

- `backlog.md` - Backlog général du projet
- `cahier_recette.yaml` - Template pour les recettes de test
- `v0.3/` - Spécifications de la version 0.3
- `v0.4/` - Spécifications de la version 0.4

**Quand ajouter ici :** Pour toute nouvelle fonctionnalité planifiée ou en cours de développement.

---

### 📰 `release_notes/` - Notes de version
Release notes des versions **passées** et de la version **en préparation**.

- `.release_notes_v0.2.0.md` - Notes de version 0.2.0
- `.release_notes_v0.3.0.md` - Notes de version 0.3.0

**Quand ajouter ici :** Avant chaque release pour documenter les changements.

---

### ✨ `features/` - Documentation des fonctionnalités
Documentation détaillée des **fonctionnalités implémentées** et en production.

- `objectifs_tendance.md` - Calcul des tendances des objectifs (hausse/baisse/neutre)
- `statistiques.md` - Système de statistiques et métriques
- `stats_explicatives.md` - Explications détaillées des statistiques affichées

**Quand ajouter ici :** Pour documenter une fonctionnalité terminée et déployée.  
**Quand mettre à jour :** Lorsqu'une fonctionnalité existante est modifiée.

---

### 🔧 `tech/` - Documentation technique
Documentation purement technique : architecture, build, déploiement, intégrations.

- `build_apk_guide.md` - Guide de compilation d'APK Android
- `backend_oauth_spec.md` - Spécifications OAuth pour le backend
- `evolution_chart.md` - Composant de graphe réutilisable

**Quand ajouter ici :** Pour toute documentation technique (CI/CD, architecture, configuration).

---

### 🧪 `tests/` - Documentation de tests
Guides de tests manuels, automatiques et cahiers de recette.

- `testing_auth.md` - Guide de test manuel pour l'authentification OAuth
- `cahier_recette.md` - Cahier de recette complet pour toutes les fonctionnalités

**Quand ajouter ici :** Pour tout nouveau scénario de test ou procédure de validation.

---

## 📝 Règles de contribution

### Créer une nouvelle fonctionnalité
1. Créer la spec dans `specs/vX.Y/`
2. Développer la fonctionnalité
3. Ajouter les tests dans `tests/`
4. À la release : déplacer la spec pertinente vers `features/` et mettre à jour
5. Ajouter les release notes dans `release_notes/`

### Modifier une fonctionnalité existante
1. Mettre à jour la documentation dans `features/`
2. Mettre à jour les tests dans `tests/` si nécessaire
3. Documenter dans les release notes

### Ajouter de la documentation technique
- Toujours dans `tech/`
- Exemples : guides de déploiement, architecture, configuration serveur

---

## 🗂️ Structure complète

```
docs/
├── README.md           # Ce fichier - guide d'organisation
├── specs/              # Spécifications versions futures/en cours
├── release_notes/      # Notes de versions passées
├── features/           # Fonctionnalités en production
├── tech/               # Documentation technique
└── tests/              # Tests et validation
```
