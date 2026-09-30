import 'package:flutter/material.dart';

/// Clean, distraction-free Material 3 light and dark theme definitions for ZeroScroll.
class AppTheme {
  AppTheme._();

  // Focus-oriented color palette (calm slate / steel / indigo accents)
  static const Color _primaryLight = Color(0xFF1E3A5F);
  static const Color _primaryDark = Color(0xFF90CAF9);

  static const Color _secondaryLight = Color(0xFF006D77);
  static const Color _secondaryDark = Color(0xFF83C5BE);

  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _surfaceLight = Color(0xFFFFFFFF);

  static const Color _backgroundDark = Color(0xFF121417);
  static const Color _surfaceDark = Color(0xFF1B1F24);

  /// Material 3 Light Theme.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: _secondaryLight,
      onSecondary: Colors.white,
      surface: _surfaceLight,
      onSurface: const Color(0xFF1A1C1E),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundLight,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _surfaceLight,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceLight,
        indicatorColor: _primaryLight.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E2EC), width: 1),
        ),
        color: _surfaceLight,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E2EC),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Material 3 Dark Theme.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: _primaryDark,
      onPrimary: const Color(0xFF003258),
      secondary: _secondaryDark,
      onSecondary: const Color(0xFF00373B),
      surface: _surfaceDark,
      onSurface: const Color(0xFFE2E2E6),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundDark,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _surfaceDark,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceDark,
        indicatorColor: _primaryDark.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2E3440), width: 1),
        ),
        color: _surfaceDark,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2E3440),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
