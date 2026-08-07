import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Brand Colors
  static const Color _lightPrimary = Color(0xFF16A34A);
  static const Color _lightPrimaryDark = Color(0xFF15803D);
  static const Color _lightSecondary = Color(0xFF2563EB);
  static const Color _lightTertiary = Color(0xFFF59E0B);

  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF0F172A);
  static const Color _lightMutedText = Color(0xFF64748B);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  static const Color _darkPrimary = Color(0xFF4ADE80);
  static const Color _darkSecondary = Color(0xFF60A5FA);
  static const Color _darkTertiary = Color(0xFFFBBF24);

  static const Color _darkBackground = Color(0xFF020617);
  static const Color _darkSurface = Color(0xFF0F172A);
  static const Color _darkSurfaceVariant = Color(0xFF1E293B);
  static const Color _darkText = Color(0xFFF8FAFC);
  static const Color _darkMutedText = Color(0xFF94A3B8);
  static const Color _darkBorder = Color(0xFF334155);

  // LIGHT THEME
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Roboto',

    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      secondary: _lightSecondary,
      tertiary: _lightTertiary,
      surface: _lightSurface,
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Color(0xFF111827),
      onSurface: _lightText,
    ),

    scaffoldBackgroundColor: _lightBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightText,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: _lightText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(
        color: _lightText,
      ),
    ),

    cardTheme: CardThemeData(
      color: _lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withOpacity(0.06),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: _lightBorder,
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withOpacity(0.12);
          }
          return null;
        }),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightText,
        side: const BorderSide(color: _lightBorder),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimaryDark,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: _lightMutedText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: _lightMutedText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: _lightMutedText,
      suffixIconColor: _lightMutedText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _lightPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: _lightBorder,
      thickness: 1,
      space: 1,
    ),

    iconTheme: const IconThemeData(
      color: _lightText,
      size: 22,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightText,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: _lightText,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        color: _lightText,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: _lightText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: _lightText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: _lightText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: _lightText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        color: _lightMutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: _lightText,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  // DARK THEME
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',

    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      secondary: _darkSecondary,
      tertiary: _darkTertiary,
      surface: _darkSurface,
      error: Color(0xFFF87171),
      onPrimary: Color(0xFF052E16),
      onSecondary: Color(0xFF082F49),
      onTertiary: Color(0xFF451A03),
      onSurface: _darkText,
    ),

    scaffoldBackgroundColor: _darkBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkText,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: _darkText,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(
        color: _darkText,
      ),
    ),

    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withOpacity(0.25),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: _darkBorder,
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF052E16),
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withOpacity(0.10);
          }
          return null;
        }),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkText,
        side: const BorderSide(color: _darkBorder),
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: _darkMutedText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: const TextStyle(
        color: _darkMutedText,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: _darkMutedText,
      suffixIconColor: _darkMutedText,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkPrimary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.6),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _darkPrimary,
      foregroundColor: Color(0xFF052E16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: _darkBorder,
      thickness: 1,
      space: 1,
    ),

    iconTheme: const IconThemeData(
      color: _darkText,
      size: 22,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkSurfaceVariant,
      contentTextStyle: const TextStyle(
        color: _darkText,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: _darkText,
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
      headlineMedium: TextStyle(
        color: _darkText,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: _darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: _darkText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: _darkText,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        color: _darkText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: TextStyle(
        color: _darkMutedText,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: TextStyle(
        color: _darkText,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}