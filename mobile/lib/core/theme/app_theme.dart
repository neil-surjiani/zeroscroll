import 'package:flutter/material.dart';

/// Instagram-inspired Material 3 light and dark theme definitions for ZeroScroll.
/// Built around the brand color palette extracted from logo.png:
/// - Primary: Deep Forest Teal (#016256) for Light Mode
/// - Primary Accent: Radiant Emerald Teal (#2DD4BF) for Dark Mode
/// - Neutral Light: Instagram crisp white (#FAFAFA & #FFFFFF) with hairline borders (#DBDBDB)
/// - Neutral Dark: Instagram AMOLED true black (#000000 & #121212) with dark borders (#262626)
/// - Notification Red: Instagram signature badge red (#ED4956)
class AppTheme {
  AppTheme._();

  // Primary brand accent colors extracted from logo.png
  static const Color accentLight = Color(0xFF016256); // Deep Teal / Pine Emerald
  static const Color accentDark = Color(0xFF2DD4BF);  // Radiant Mint / Teal

  // Instagram signature red reserved strictly for unread badges and danger actions
  static const Color unreadBadgeColor = Color(0xFFED4956);

  // Light Neutral Palette (Instagram style)
  static const Color _bgLight = Color(0xFFFAFAFA);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _borderLight = Color(0xFFDBDBDB);
  static const Color _textPrimaryLight = Color(0xFF262626);
  static const Color _textSecondaryLight = Color(0xFF737373);

  // Dark Neutral Palette (Instagram AMOLED true black)
  static const Color _bgDark = Color(0xFF000000);
  static const Color _surfaceDark = Color(0xFF121212);
  static const Color _borderDark = Color(0xFF262626);
  static const Color _textPrimaryDark = Color(0xFFF5F5F5);
  static const Color _textSecondaryDark = Color(0xFFA8A8A8);

  /// Material 3 Light Theme.
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: accentLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6F5F2),
      onPrimaryContainer: const Color(0xFF003831),
      secondary: const Color(0xFF475569),
      onSecondary: Colors.white,
      surface: _surfaceLight,
      onSurface: _textPrimaryLight,
      onSurfaceVariant: _textSecondaryLight,
      outline: const Color(0xFFB0B7C3),
      outlineVariant: _borderLight,
      error: unreadBadgeColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgLight,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surfaceLight,
        foregroundColor: _textPrimaryLight,
        titleTextStyle: TextStyle(
          color: _textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _surfaceLight,
        indicatorColor: Colors.transparent,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentLight, size: 24);
          }
          return const IconThemeData(color: _textSecondaryLight, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentLight,
              letterSpacing: -0.1,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textSecondaryLight,
            letterSpacing: -0.1,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _borderLight, width: 0.5),
        ),
        color: _surfaceLight,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderLight,
        thickness: 0.5,
        space: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: accentLight.withValues(alpha: 0.12),
          selectedForegroundColor: accentLight,
          foregroundColor: _textSecondaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: _borderLight, width: 0.5),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentLight,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _surfaceLight,
          foregroundColor: _textPrimaryLight,
          elevation: 0,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _borderLight, width: 0.5),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimaryLight,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _borderLight, width: 1),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentLight,
          minimumSize: const Size(48, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _textPrimaryLight,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentLight;
          }
          return null;
        }),
      ),
    );
  }

  /// Material 3 Dark Theme.
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: accentDark,
      onPrimary: const Color(0xFF003831),
      primaryContainer: const Color(0xFF003831),
      onPrimaryContainer: const Color(0xFFCCFBF1),
      secondary: const Color(0xFF94A3B8),
      onSecondary: const Color(0xFF0F172A),
      surface: _surfaceDark,
      onSurface: _textPrimaryDark,
      onSurfaceVariant: _textSecondaryDark,
      outline: const Color(0xFF4B5563),
      outlineVariant: _borderDark,
      error: const Color(0xFFFF3040),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _bgDark,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _bgDark,
        foregroundColor: _textPrimaryDark,
        titleTextStyle: TextStyle(
          color: _textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: _bgDark,
        indicatorColor: Colors.transparent,
        height: 56,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentDark, size: 24);
          }
          return const IconThemeData(color: _textSecondaryDark, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentDark,
              letterSpacing: -0.1,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _textSecondaryDark,
            letterSpacing: -0.1,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _borderDark, width: 0.5),
        ),
        color: _surfaceDark,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderDark,
        thickness: 0.5,
        space: 1,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: accentDark.withValues(alpha: 0.16),
          selectedForegroundColor: accentDark,
          foregroundColor: _textSecondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: _borderDark, width: 0.5),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentDark,
          foregroundColor: const Color(0xFF003831),
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _surfaceDark,
          foregroundColor: _textPrimaryDark,
          elevation: 0,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _borderDark, width: 0.5),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _textPrimaryDark,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _borderDark, width: 1),
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentDark,
          minimumSize: const Size(48, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _textPrimaryDark,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentDark;
          }
          return null;
        }),
      ),
    );
  }
}
