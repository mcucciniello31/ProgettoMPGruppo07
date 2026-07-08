import 'package:flutter/material.dart';

class AppTheme {
  // Palette di colori del tema unico — azzurrino chiaro con contrasto blu scuro
  static const Color primary = Color(0xFF4DA8DA); // Azzurro cielo
  static const Color secondary = Color(0xFF14B8A6); // Verde acqua / Teal
  static const Color background = Color(0xFFCBE0F0); // Sfondo azzurro pastello (leggermente più scuro/intenso per maggior contrasto con le card bianche)
  static const Color card = Color(0xFFFFFFFF); // Bianco puro per le card
  static const Color textPrimary = Color(0xFF0D2137); // Blu notte scuro
  static const Color textSecondary = Color(0xFF3B6A8A); // Blu medio/grigio

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

  // Colori associati alle categorie di attività
  static const Map<String, Color> activityColors = {
    'Visita': Color(0xFF38BDF8), // Celeste
    'Escursione': Color(0xFF34D399), // Smeraldo
    'Prenotazione': Color(0xFFF87171), // Rosso corallo
    'Pasto': Color(0xFFFB923C), // Arancione
    'Spostamento': Color(0xFF818CF8), // Indaco
    'Evento': Color(0xFFF472B6), // Rosa
    'Momento Libero': Color(0xFF2DD4BF), // Teal
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
        primary: primary,
        secondary: secondary,
        background: background,
        surface: card,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFADCDE2), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFADCDE2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFADCDE2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      dividerColor: const Color(0xFFADCDE2),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
      ),
    );
  }
}
