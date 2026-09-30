import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme has Material 3 enabled and valid colorScheme', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, isNotNull);
    });

    test('darkTheme has Material 3 enabled and valid colorScheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, isNotNull);
    });
  });
}
