import 'package:flutter/material.dart';

/// User configurable settings entity.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.biometricLockEnabled = false,
    this.autoCheckUpdates = true,
  });

  final ThemeMode themeMode;
  final bool biometricLockEnabled;
  final bool autoCheckUpdates;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? biometricLockEnabled,
    bool? autoCheckUpdates,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
    );
  }
}
