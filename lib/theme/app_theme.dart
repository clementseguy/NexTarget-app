import 'package:flutter/material.dart';

/// Les thèmes disponibles dans l'application
enum AppThemeType {
  classique,
  bleuBlancRouge,
}

/// Classe qui gère les thèmes de l'application
/// 
/// Permet de centraliser la configuration du thème et de faciliter sa personnalisation
class AppTheme {
  // Couleurs primaires (classique)
  static const Color amber = Colors.amber;
  static const Color neonGreen = Color(0xFF16FF8B);
  static const Color darkSurface = Color(0xFF23272F);
  static const Color darkBackground = Color(0xFF181A20);
  static const Color darkAppBar = Colors.black;

  // Couleurs Bleu-Blanc-Rouge
  static const Color bleuRoyal = Color(0xFF002395);
  static const Color rougeFrance = Color(0xFFED2939);
  static const Color blancCasse = Color(0xFFF5F5F5);
  static const Color bleuClair = Color(0xFFE8EDF5);

  /// Retourne le thème correspondant au type demandé
  static ThemeData forType(AppThemeType type) {
    switch (type) {
      case AppThemeType.classique:
        return darkTheme;
      case AppThemeType.bleuBlancRouge:
        return bleuBlancRougeTheme;
    }
  }

  /// Retourne le thème principal de l'application (sombre)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: neonGreen,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),
      cardColor: darkSurface,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      textTheme: ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonGreen, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: amber, width: 2),
        ),
        labelStyle: const TextStyle(color: neonGreen),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      iconTheme: const IconThemeData(color: neonGreen, size: 24),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonGreen,
        foregroundColor: Colors.black,
      ),
      dividerColor: Colors.grey[800],
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: amber,
        unselectedItemColor: Colors.white70,
      ),
    );
  }

  /// Thème Bleu-Blanc-Rouge (couleurs de la France)
  static ThemeData get bleuBlancRougeTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: bleuRoyal,
        secondary: rougeFrance,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A1A2E),
      ),
      scaffoldBackgroundColor: blancCasse,
      appBarTheme: const AppBarTheme(
        backgroundColor: bleuRoyal,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 1.2,
        ),
      ),
      cardColor: Colors.white,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bleuRoyal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 2,
        ),
      ),
      textTheme: ThemeData.light().textTheme.copyWith(
        bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
        bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF3A3A4E)),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF1A1A2E)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bleuClair,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bleuRoyal, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rougeFrance, width: 2),
        ),
        labelStyle: const TextStyle(color: bleuRoyal),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      iconTheme: const IconThemeData(color: bleuRoyal, size: 24),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: rougeFrance,
        foregroundColor: Colors.white,
      ),
      dividerColor: Colors.grey[300],
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: bleuRoyal,
        unselectedItemColor: Color(0xFF7A7A8E),
      ),
    );
  }
}