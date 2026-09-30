import 'package:flutter/material.dart';

/// Calm, minimal Material 3 light and dark theme definitions for ZeroScroll.
/// Built around a neutral slate palette with a single focus accent color.
class AppTheme {
  AppTheme._();

  // Accent Colors: Calm, single accent color (Steel / Slate Blue)
  static const Color accentLight = Color(0xFF2563EB);
  static const Color accentDark = Color(0xFF60A5FA);

  // Red is strictly reserved for unread badges and danger/logout confirmations
  static const Color unreadBadgeColor = Color(0xFFDC2626);

  // Light Neutral Palette (Slate 50 to 900)
  static const Color _bgLight = Color(0xFFF8FAFC);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Color _textPrimaryLight = Color(0xFF0F172A);
  static const Color _textSecondaryLight = Color(0xFF64748B);

  // Dark Neutral Palette (Deep Slate to Dark Charcoal)
  static const Color _bgDark = Color(0xFF0B0F17);
  static const Color _surfaceDark = Color(0xFF131B26);
  static const Color _borderDark = Color(0xFF283548);
  static const Color _textPrimaryDark = Color(0xFFF8FAFC);
  static const Color _textSecondaryDark = Color(0xFF94A3B8);

  /// Material 3 Light Theme.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: accentLight,
      onPrimary: Colors.white,
      secondary: const Color(0xFF475569),
      onSecondary: Colors.white,
      surface: _surfaceLight,
      onSurface: _textPrimaryLight,
      onSurfaceVariant: _textSecondaryLight,
      outlineVariant: _borderLight,
      error: unreadBadgeColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgLight,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _surfaceLight,
        foregroundColor: _textPrimaryLight,
        titleTextStyle: const TextStyle(
          color: _textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceLight,
        indicatorColor: accentLight.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderLight, width: 1),
        ),
        color: _surfaceLight,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderLight,
        thickness: 1,
        space: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }

  /// Material 3 Dark Theme.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: accentDark,
      onPrimary: const Color(0xFF0B192C),
      secondary: const Color(0xFF94A3B8),
      onSecondary: const Color(0xFF0F172A),
      surface: _surfaceDark,
      onSurface: _textPrimaryDark,
      onSurfaceVariant: _textSecondaryDark,
      outlineVariant: _borderDark,
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgDark,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: _surfaceDark,
        foregroundColor: _textPrimaryDark,
        titleTextStyle: const TextStyle(
          color: _textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceDark,
        indicatorColor: accentDark.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _borderDark, width: 1),
        ),
        color: _surfaceDark,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderDark,
        thickness: 1,
        space: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}
