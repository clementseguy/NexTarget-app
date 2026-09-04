# Spécification : Thème "ASCII Art" pour NexTarget

**Auteur** : GitHub Copilot  
**Date** : 30 octobre 2025  
**Version** : 1.0  
**Statut** : Proposition

---

## 📋 Résumé exécutif

Cette spécification détaille l'implémentation d'un thème "ASCII Art" rétro-terminal pour l'application NexTarget. L'objectif est d'offrir une expérience visuelle unique inspirée des terminaux classiques années 80-90, tout en préservant l'ergonomie et les fonctionnalités existantes.

**Verdict** : ✅ **FAISABLE** avec un effort de développement estimé à **3-5 jours**.

---

## 🎯 Objectifs

### Objectifs principaux
1. Permettre aux utilisateurs de choisir entre le thème sombre actuel et un thème ASCII Art
2. Créer une identité visuelle distinctive et nostalgique
3. Maintenir l'accessibilité et l'ergonomie de l'application
4. Faciliter l'ajout de thèmes supplémentaires à l'avenir

### Objectifs secondaires
- Offrir une expérience "easter egg" pour les utilisateurs fans de rétro-computing
- Différencier NexTarget des autres applications de tir sportif
- Démontrer la flexibilité de l'architecture Flutter

---

## 📊 Analyse de l'existant

### Architecture actuelle

#### Système de thèmes
- **Fichier** : [`lib/theme/app_theme.dart`](../../lib/theme/app_theme.dart)
- **État** : Un seul thème implémenté (`darkTheme`)
- **Application** : Thème statique défini dans [`lib/app/my_app.dart`](../../lib/app/my_app.dart)
- **Points positifs** :
  - Centralisation de la configuration
  - Utilisation de `ThemeData` Flutter standard
  - Bonne séparation des responsabilités

#### Système de préférences
- **Provider** : [`lib/providers/settings_provider.dart`](../../lib/providers/settings_provider.dart)
- **Stockage** : Hive (`app_preferences`)
- **Préférences existantes** :
  - `default_hand_method` (string)
  - `default_caliber` (string)
- **Points positifs** :
  - Persistance déjà fonctionnelle
  - Pattern Provider déjà en place
  - Infrastructure prête pour de nouvelles préférences

#### Utilisation des couleurs dans les widgets
- **Constat** : Mélange de `Theme.of(context)` et couleurs hardcodées
- **Exemples de couleurs hardcodées** :
  - `Colors.amber`, `Colors.blueAccent` dans [`lib/widgets/series_cards.dart`](../../lib/widgets/series_cards.dart)
  - `Colors.orangeAccent`, `Colors.tealAccent` dans plusieurs widgets
  - Gradients complexes dans les cards

**Impact** : Nécessite un refactoring partiel pour une compatibilité totale avec les thèmes.

---

## 🎨 Design du thème ASCII Art

### Inspiration
- Terminaux VT100, Commodore 64, IBM PC DOS
- Films : *WarGames*, *The Matrix*, *Hackers*
- Jeux : *Fallout* (Pip-Boy), terminaux Unix

### Palette de couleurs

#### Couleurs principales
```dart
// Couleurs inspirées des terminaux phosphore vert
static const Color terminalGreen = Color(0xFF00FF00);      // Vert phosphore
static const Color terminalDarkGreen = Color(0xFF008800); // Vert sombre
static const Color terminalBlack = Color(0xFF000000);      // Noir pur
static const Color terminalYellow = Color(0xFFFFFF00);    // Jaune vif
static const Color terminalCyan = Color(0xFF00FFFF);      // Cyan
static const Color terminalRed = Color(0xFFFF0000);       // Rouge vif
static const Color terminalAmber = Color(0xFFFFAA00);     // Ambre
```

#### Mapping fonctionnel
| Fonction | Thème Dark actuel | Thème ASCII |
|----------|-------------------|-------------|
| Primary | Amber (`#FFC107`) | Vert terminal (`#00FF00`) |
| Secondary | Neon Green (`#16FF8B`) | Jaune (`#FFFF00`) |
| Background | Dark (`#181A20`) | Noir pur (`#000000`) |
| Surface | Dark Surface (`#23272F`) | Noir avec bordure verte |
| Error | Rouge standard | Rouge vif (`#FF0000`) |
| Success | Vert standard | Vert terminal (`#00FF00`) |

### Typographie

#### Police principale
```dart
fontFamily: 'Courier', // Fallback: 'Courier New', 'Monaco', 'Inconsolata'
```

**Rationale** : 
- Police monospace native (pas de dépendance externe)
- Évoque les terminaux classiques
- Lisibilité élevée même en petite taille

#### Tailles de texte
```dart
bodyLarge: TextStyle(fontSize: 16, fontFamily: 'Courier', color: terminalGreen),
bodyMedium: TextStyle(fontSize: 14, fontFamily: 'Courier', color: terminalGreen),
titleLarge: TextStyle(fontSize: 20, fontFamily: 'Courier', color: terminalYellow, fontWeight: FontWeight.bold),
```

### Composants UI

#### Cards
```dart
CardTheme(
  color: terminalBlack,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.zero, // Coins carrés !
    side: BorderSide(color: terminalGreen, width: 2),
  ),
  elevation: 0, // Pas d'ombre dans un terminal
)
```

**Effet visuel** :
```
┌────────────────────────┐
│ SESSION #042           │
│ DATE: 2025-10-30       │
│ SCORE: 245 pts         │
└────────────────────────┘
```

#### Boutons
```dart
ElevatedButtonTheme(
  style: ElevatedButton.styleFrom(
    backgroundColor: terminalBlack,
    foregroundColor: terminalGreen,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
      side: BorderSide(color: terminalGreen, width: 2),
    ),
    textStyle: TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold),
  ),
)
```

#### Inputs
```dart
InputDecorationTheme(
  filled: true,
  fillColor: terminalBlack,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: terminalGreen, width: 2),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: terminalYellow, width: 3),
  ),
  labelStyle: TextStyle(color: terminalGreen, fontFamily: 'Courier'),
)
```

### Effets spéciaux

#### 1. Scanlines (lignes horizontales)
```dart
class ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

**Utilisation** :
```dart
Stack(
  children: [
    // Contenu de la card
    YourCardContent(),
    // Overlay scanlines
    Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: ScanlinesPainter()),
      ),
    ),
  ],
)
```

#### 2. Clignotement de texte (optionnel)
```dart
class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const BlinkingText({required this.text, required this.style});
  
  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(widget.text, style: widget.style),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

#### 3. Bordures ASCII
```dart
Widget buildAsciiCard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: terminalBlack,
      border: Border.all(color: terminalGreen, width: 2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('┌────────────────────────┐', style: asciiStyle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: child,
        ),
        Text('└────────────────────────┘', style: asciiStyle),
      ],
    ),
  );
}
```

---

## 🛠️ Plan d'implémentation

### Phase 1 : Infrastructure (1 jour)

#### Tâche 1.1 : Créer l'enum pour les thèmes
**Fichier** : `lib/theme/app_theme.dart`

```dart
/// Types de thèmes disponibles
enum AppThemeMode {
  dark('dark', 'Sombre'),
  ascii('ascii', 'ASCII Art');
  
  const AppThemeMode(this.id, this.label);
  final String id;
  final String label;
  
  static AppThemeMode fromId(String id) {
    return values.firstWhere((e) => e.id == id, orElse: () => dark);
  }
}
```

#### Tâche 1.2 : Implémenter `asciiTheme`
**Fichier** : `lib/theme/app_theme.dart`

```dart
static ThemeData get asciiTheme {
  return ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Courier',
    colorScheme: const ColorScheme.dark(
      primary: terminalGreen,
      secondary: terminalYellow,
      surface: terminalBlack,
      background: terminalBlack,
      error: terminalRed,
    ),
    scaffoldBackgroundColor: terminalBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: terminalBlack,
      foregroundColor: terminalGreen,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: terminalYellow,
        fontWeight: FontWeight.bold,
        fontSize: 22,
        fontFamily: 'Courier',
        letterSpacing: 2.0,
      ),
    ),
    cardTheme: CardThemeData(
      color: terminalBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: terminalGreen, width: 2),
      ),
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: terminalBlack,
        foregroundColor: terminalGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: terminalGreen, width: 2),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFamily: 'Courier',
        ),
        elevation: 0,
      ),
    ),
    textTheme: ThemeData.dark().textTheme.copyWith(
      bodyLarge: const TextStyle(fontSize: 16, color: terminalGreen, fontFamily: 'Courier'),
      bodyMedium: const TextStyle(fontSize: 14, color: terminalGreen, fontFamily: 'Courier'),
      titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: terminalYellow, fontFamily: 'Courier'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: terminalBlack,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: terminalGreen, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: terminalYellow, width: 3),
      ),
      labelStyle: const TextStyle(color: terminalGreen, fontFamily: 'Courier'),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    ),
    iconTheme: const IconThemeData(color: terminalGreen, size: 24),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: terminalGreen,
      foregroundColor: terminalBlack,
    ),
    dividerColor: terminalGreen,
  );
}
```

#### Tâche 1.3 : Étendre `SettingsProvider`
**Fichier** : `lib/providers/settings_provider.dart`

```dart
// Ajouter après les getters existants
AppThemeMode get selectedTheme {
  final themeId = _preferencesBox.get('selected_theme', defaultValue: 'dark');
  return AppThemeMode.fromId(themeId);
}

Future<void> updateSelectedTheme(AppThemeMode theme) async {
  await _preferencesBox.put('selected_theme', theme.id);
  notifyListeners();
}
```

#### Tâche 1.4 : Modifier `MyApp` pour réagir aux changements
**Fichier** : `lib/app/my_app.dart`

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        // Sélectionner le thème en fonction de la préférence
        final theme = settingsProvider.selectedTheme == AppThemeMode.ascii
            ? AppTheme.asciiTheme
            : AppTheme.darkTheme;
        
        return MaterialApp(
          title: 'NexTarget',
          theme: theme,
          home: FadeInWrapper(
            duration: Duration(milliseconds: AppConfig.I.splashFadeDurationMs),
            child: const _AuthGate(),
          ),
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRouter.home,
        );
      },
    );
  }
}
```

**Validation** : Changement de thème en temps réel sans redémarrage de l'app.

---

### Phase 2 : UI du sélecteur (0.5 jour)

#### Tâche 2.1 : Ajouter le sélecteur dans les paramètres
**Fichier** : `lib/screens/settings_screen.dart`

**Localisation** : Après le ListTile "Méthode de tir par défaut"

```dart
// Sélecteur de thème
Consumer<SettingsProvider>(
  builder: (context, settingsProvider, _) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Apparence'),
      subtitle: Text(settingsProvider.selectedTheme.label),
      trailing: DropdownButton<AppThemeMode>(
        value: settingsProvider.selectedTheme,
        underline: const SizedBox(), // Pas de ligne sous le dropdown
        items: AppThemeMode.values.map((mode) {
          return DropdownMenuItem(
            value: mode,
            child: Text(mode.label),
          );
        }).toList(),
        onChanged: (AppThemeMode? newMode) {
          if (newMode != null) {
            settingsProvider.updateSelectedTheme(newMode);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Thème "${newMode.label}" activé'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  },
),
```

**Validation** : Sélection dans les paramètres → changement immédiat de l'UI.

---

### Phase 3 : Adaptation des widgets (1-2 jours)

#### Widgets prioritaires à adapter

##### 3.1 : `SeriesCard`
**Fichier** : `lib/widgets/series_cards.dart`

**Problème** : Couleurs hardcodées (`Colors.amberAccent`, `Colors.tealAccent`, etc.)

**Solution** :
```dart
// Avant
final borderColor = highlightBestPoints 
    ? Colors.amberAccent 
    : highlightBestGroup ? Colors.tealAccent : Colors.white12;

// Après
final theme = Theme.of(context);
final borderColor = highlightBestPoints 
    ? theme.colorScheme.primary 
    : highlightBestGroup ? theme.colorScheme.secondary : theme.dividerColor;
```

##### 3.2 : `ValueChip` dans les séries
**Problème** : Couleurs spécifiques (`Colors.orangeAccent`, `Colors.pinkAccent`)

**Solution** : Créer une palette de couleurs dérivées du thème
```dart
class ThemeColors {
  static Color forMetric(BuildContext context, String metric) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (metric) {
      case 'shots': return colorScheme.primary;
      case 'distance': return colorScheme.secondary;
      case 'points': return colorScheme.tertiary ?? colorScheme.primary;
      case 'group': return colorScheme.secondary;
      default: return colorScheme.primary;
    }
  }
}

// Utilisation
ValueChip(
  icon: Icons.bolt,
  label: 'Coups',
  value: '${series.shotCount}',
  color: ThemeColors.forMetric(context, 'shots'),
)
```

##### 3.3 : Gradients
**Problème** : `LinearGradient` complexes dans les cards

**Solution** : Remplacer par couleur unie en mode ASCII
```dart
decoration: BoxDecoration(
  gradient: Theme.of(context).brightness == Brightness.dark && 
            Theme.of(context).fontFamily != 'Courier'
      ? LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade800],
        )
      : null,
  color: Theme.of(context).fontFamily == 'Courier' 
      ? Theme.of(context).cardColor 
      : null,
)
```

##### 3.4 : Graphiques `fl_chart`
**Problème** : Les graphiques FL Chart ne s'adaptent pas automatiquement

**Option A** : Adapter les couleurs des graphiques
```dart
FlChart.lineChart(
  LineChartData(
    gridData: FlGridData(
      show: true,
      drawVerticalLine: true,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(context).dividerColor,
          strokeWidth: 1,
        );
      },
    ),
    lineBarsData: [
      LineChartBarData(
        spots: data,
        isCurved: Theme.of(context).fontFamily != 'Courier', // Lignes droites en ASCII
        color: Theme.of(context).colorScheme.primary,
      ),
    ],
  ),
)
```

**Option B** : Créer des graphiques ASCII textuels (ambitieux)
```dart
class AsciiBarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  
  @override
  Widget build(BuildContext context) {
    final max = values.reduce((a, b) => a > b ? a : b);
    const maxHeight = 10;
    
    return Column(
      children: [
        for (var i = maxHeight; i > 0; i--)
          Row(
            children: values.map((value) {
              final normalized = (value / max * maxHeight).round();
              return Text(
                normalized >= i ? '█ ' : '  ',
                style: TextStyle(
                  fontFamily: 'Courier',
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }).toList(),
          ),
        Row(
          children: labels.map((label) {
            return Text(
              label.substring(0, 2),
              style: TextStyle(
                fontFamily: 'Courier',
                color: Theme.of(context).colorScheme.secondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

---

### Phase 4 : Effets spéciaux (optionnel, 1 jour)

#### Tâche 4.1 : Scanlines overlay
**Fichier** : `lib/theme/ascii_effects.dart` (nouveau)

```dart
import 'package:flutter/material.dart';

class ScanlinesPainter extends CustomPainter {
  final double opacity;
  
  const ScanlinesPainter({this.opacity = 0.05});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;
    
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(ScanlinesPainter oldDelegate) {
    return opacity != oldDelegate.opacity;
  }
}

class ScanlinesOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  
  const ScanlinesOverlay({
    super.key,
    required this.child,
    this.opacity = 0.05,
  });
  
  @override
  Widget build(BuildContext context) {
    // N'appliquer que pour le thème ASCII
    if (Theme.of(context).fontFamily != 'Courier') {
      return child;
    }
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: ScanlinesPainter(opacity: opacity)),
          ),
        ),
      ],
    );
  }
}
```

**Utilisation** :
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ScanlinesOverlay(
      child: YourContent(),
    ),
  );
}
```

#### Tâche 4.2 : Clignotement de texte
**Fichier** : `lib/theme/ascii_effects.dart`

```dart
class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  
  const BlinkingText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });
  
  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(widget.text, style: widget.style),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Utilisation** : Pour les alertes importantes
```dart
BlinkingText(
  text: '>>> NOUVEAU RECORD <<<',
  style: TextStyle(
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.bold,
  ),
)
```

---

### Phase 5 : Tests (0.5 jour)

#### Tests unitaires à ajouter

**Fichier** : `test/theme/ascii_theme_test.dart` (nouveau)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tir_sportif/theme/app_theme.dart';

void main() {
  group('ASCII Theme', () {
    test('asciiTheme uses Courier font', () {
      final theme = AppTheme.asciiTheme;
      expect(theme.textTheme.bodyLarge?.fontFamily, 'Courier');
      expect(theme.fontFamily, 'Courier');
    });
    
    test('asciiTheme has zero border radius on cards', () {
      final theme = AppTheme.asciiTheme;
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.zero);
    });
    
    test('asciiTheme has green primary color', () {
      final theme = AppTheme.asciiTheme;
      expect(theme.colorScheme.primary, const Color(0xFF00FF00));
    });
  });
}
```

#### Tests de préférences

**Fichier** : `test/providers/settings_provider_theme_test.dart` (nouveau)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tir_sportif/providers/settings_provider.dart';
import 'package:tir_sportif/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
    await Hive.openBox('app_preferences');
  });
  
  tearDownAll(() async {
    await Hive.box('app_preferences').clear();
    await Hive.close();
  });
  
  group('Theme Preferences', () {
    test('default theme is dark', () {
      final provider = SettingsProvider();
      expect(provider.selectedTheme, AppThemeMode.dark);
    });
    
    test('can update theme to ASCII', () async {
      final provider = SettingsProvider();
      await provider.updateSelectedTheme(AppThemeMode.ascii);
      expect(provider.selectedTheme, AppThemeMode.ascii);
    });
    
    test('theme preference persists', () async {
      final provider1 = SettingsProvider();
      await provider1.updateSelectedTheme(AppThemeMode.ascii);
      
      // Créer un nouveau provider (simule redémarrage app)
      final provider2 = SettingsProvider();
      expect(provider2.selectedTheme, AppThemeMode.ascii);
    });
  });
}
```

#### Tests de widgets

**Mise à jour de** : `test/widget_test.dart`

```dart
// Ajouter un test pour vérifier que l'app démarre avec les deux thèmes
testWidgets('App boots with ASCII theme', (WidgetTester tester) async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen('app_preferences')) {
    await Hive.openBox('app_preferences');
  }
  
  // Définir le thème ASCII
  final box = Hive.box('app_preferences');
  await box.put('selected_theme', 'ascii');
  
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    )
  );
  
  await tester.pumpAndSettle();
  
  // Vérifier que le thème est appliqué
  final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
  expect(materialApp.theme?.fontFamily, 'Courier');
});
```

---

## 🎯 Critères d'acceptation

### Fonctionnels
- [ ] L'utilisateur peut choisir entre "Sombre" et "ASCII Art" dans les paramètres
- [ ] Le changement de thème est immédiat (pas de redémarrage)
- [ ] Le thème sélectionné persiste après redémarrage de l'app
- [ ] Tous les écrans sont fonctionnels avec le thème ASCII
- [ ] Les formulaires restent utilisables (inputs, boutons)

### Non-fonctionnels
- [ ] Performance : Pas de lag visible lors du changement de thème
- [ ] Accessibilité : Contraste suffisant (WCAG AA minimum)
- [ ] Cohérence : Tous les widgets respectent la charte ASCII
- [ ] Tests : Couverture > 80% pour le nouveau code

### UX
- [ ] Le thème ASCII est visuellement distinct du thème sombre
- [ ] Les informations importantes restent lisibles
- [ ] Les interactions (tap, swipe) fonctionnent normalement
- [ ] Aucune régression sur les fonctionnalités existantes

---

## ⚠️ Risques et mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Performance dégradée (scanlines) | Moyenne | Faible | Rendre les scanlines optionnelles, utiliser `RepaintBoundary` |
| Contraste insuffisant | Faible | Moyen | Tests d'accessibilité, option "High Contrast" |
| Graphiques fl_chart non compatibles | Élevée | Moyen | Fallback vers version simplifiée ou désactivation |
| Régressions sur widgets complexes | Moyenne | Élevé | Tests exhaustifs, code review approfondi |
| Effet "gimmick" (lassitude) | Faible | Faible | Communication claire (thème optionnel) |

---

## 📈 Métriques de succès

### Adoption
- **Objectif** : 20% des utilisateurs activent le thème ASCII dans les 2 semaines
- **Mesure** : Analytics sur `selected_theme` dans les préférences

### Satisfaction
- **Objectif** : 80% de feedback positif sur les stores
- **Mesure** : Reviews mentionnant "ASCII", "rétro", "terminal"

### Performance
- **Objectif** : Temps de rendu < 16ms (60 FPS)
- **Mesure** : Flutter DevTools Performance tab

### Qualité
- **Objectif** : 0 bug critique, < 5 bugs mineurs
- **Mesure** : Issues GitHub avec label `theme:ascii`

---

## 🚀 Roadmap

### Version 0.5.0 (MVP)
- ✅ Infrastructure (enum, provider)
- ✅ Thème ASCII de base (couleurs, typo)
- ✅ Sélecteur dans les paramètres
- ✅ Adaptation des widgets principaux
- ✅ Tests unitaires

**Effort** : 3 jours  
**Livraison** : Novembre 2025

### Version 0.5.1 (Polish)
- ✅ Effets scanlines
- ✅ Bordures ASCII sur les cards importantes
- ✅ Animation de transition entre thèmes
- ✅ Tests d'accessibilité

**Effort** : 1 jour  
**Livraison** : Novembre 2025

### Version 0.6.0 (Avancé - optionnel)
- 🔮 Graphiques ASCII (barres textuelles)
- 🔮 Mode "High Contrast" pour accessibilité
- 🔮 Thème light "Retro Paper" (fond blanc, texte noir)
- 🔮 Easter egg "Matrix rain" en arrière-plan

**Effort** : 2-3 jours  
**Livraison** : Décembre 2025

---

## 📚 Références

### Inspiration design
- [Cool Retro Term](https://github.com/Swordfish90/cool-retro-term) - Émulateur de terminal vintage
- [Fallout UI Design](https://fallout.fandom.com/wiki/Pip-Boy) - Interface Pip-Boy
- [ASCII Art Archive](https://www.asciiart.eu/) - Ressources ASCII

### Documentation technique
- [Flutter ThemeData](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [Custom Painter](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)
- [Material Design Color System](https://m3.material.io/styles/color/system/overview)

### Accessibilité
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)

---

## 🎬 Conclusion

L'implémentation d'un thème ASCII Art est **techniquement faisable** avec l'architecture actuelle de NexTarget. L'effort de développement est **raisonnable** (3-5 jours) et apporterait une **différenciation significative** par rapport aux applications concurrentes.

### Points clés
✅ Architecture Flutter favorable  
✅ Système de préférences déjà en place  
✅ Effort de développement maîtrisé  
✅ Potentiel de différenciation élevé  
⚠️ Nécessite refactoring partiel des couleurs hardcodées  
⚠️ Tests d'accessibilité essentiels  

### Recommandation
**GO pour la version 0.5.0** avec un déploiement progressif :
1. Beta test auprès de 10-20 utilisateurs
2. Collecte de feedback
3. Ajustements et polish
4. Release publique

---

**Prochaines étapes** :
1. Validation de cette spec par l'équipe
2. Création des issues GitHub avec estimation détaillée
3. Sprint planning pour intégration dans la v0.5.0
4. Kick-off développement

---

*Document créé le 30 octobre 2025*  
*Prochaine révision : Après feedback équipe*