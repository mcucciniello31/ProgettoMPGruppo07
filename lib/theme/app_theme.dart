import 'package:flutter/material.dart';

class AppTheme {
  // Palette di colori del tema
  static const Color primaryLight = Color.fromARGB(255, 43, 156, 237); // Indaco moderno
  static const Color secondaryLight = Color(0xFF14B8A6); // Verde acqua / Teal
  static const Color backgroundLight = Color(0xFFF8FAFC); // Grigio/azzurro molto chiaro
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Ardesia scura
  static const Color textSecondaryLight = Color(0xFF64748B); // Grigio freddo

  static const Color primaryDark = Color.fromARGB(255, 43, 156, 237); // Indaco chiaro
  static const Color secondaryDark = Color(0xFF2DD4BF); // Verde acqua chiaro / Teal Light
  static const Color backgroundDark = Color(0xFF0F172A); // Ardesia notte scura
  static const Color cardDark = Color(0xFF1E293B); // Scheda ardesia scura
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Colori associati alle categorie di spesa
  static const Map<String, Color> categoryColors = {
    'Trasporto': Color(0xFF38BDF8), // Celeste
    'Alloggio': Color(0xFF34D399), // Smeraldo
    'Cibo': Color(0xFFF87171), // Rosso corallo
    'Attività': Color(0xFFC084FC), // Lavanda
    'Shopping': Color(0xFFF472B6), // Rosa
    'Spese Mediche': Color(0xFFE11D48), // Rosa cremisi
    'Altro': Color(0xFF94A3B8), // Ardesia fredda
  };

  // Icone associate alle categorie di attività
  static const Map<String, IconData> activityIcons = {
    'Visita': Icons.explore,
    'Escursione': Icons.hiking,
    'Prenotazione': Icons.confirmation_number,
    'Pasto': Icons.restaurant,
    'Spostamento': Icons.directions_bus,
    'Evento': Icons.event,
    'Momento Libero': Icons.beach_access,
    'Altro': Icons.local_activity,
  };

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        background: backgroundLight,
        surface: cardLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimaryLight,
        onSurface: textPrimaryLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryLight,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryLight,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        background: backgroundDark,
        surface: cardDark,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onBackground: textPrimaryDark,
        onSurface: textPrimaryDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryDark,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }
}
