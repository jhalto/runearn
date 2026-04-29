import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppTheme {
  // 🌿 LIGHT THEME
  static final light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1B5E20), // deep green (actions, income)
      secondary: Color(0xFF1565C0), // blue (info, charts)
      tertiary: Color(0xFFFF8F00), // orange (warnings/highlights)

      surface: Color(0xFFFFFFFF), // card/background
      background: Color(0xFFF5F7FA), // app background

      error: Color(0xFFD32F2F),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A1A1A), // text on cards
    ),

    scaffoldBackgroundColor: const Color(0xFFF5F7FA),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
    ),
  );

  // 🌑 DARK THEME
  static final dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF66BB6A), // green
      secondary: Color(0xFF42A5F5), // blue
      tertiary: Color(0xFFFFB74D), // orange

      surface: Color(0xFF1E1E1E), // card
      background: Color(0xFF121212), // app background

      error: Color(0xFFEF5350),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white, // text on dark cards
    ),

    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
    ),
  );
}
