import 'package:flutter/material.dart';

/// Available timeouts before requiring biometric / device unlock after backgrounding.
enum LockTimeout {
  immediate(0, 'Immediately'),
  oneMinute(60, '1 minute'),
  fiveMinutes(300, '5 minutes');

  const LockTimeout(this.seconds, this.label);
  final int seconds;
  final String label;

  static LockTimeout fromSeconds(int? seconds) {
    if (seconds == null) return LockTimeout.immediate;
    if (seconds >= 300) return LockTimeout.fiveMinutes;
    if (seconds >= 60) return LockTimeout.oneMinute;
    return LockTimeout.immediate;
  }
}

/// User configurable settings entity.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.biometricLockEnabled = false,
    this.lockTimeout = LockTimeout.immediate,
    this.blockScreenshotsEnabled = false,
    this.autoCheckUpdates = true,
  });

  final ThemeMode themeMode;
  final bool biometricLockEnabled;
  final LockTimeout lockTimeout;
  final bool blockScreenshotsEnabled;
  final bool autoCheckUpdates;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? biometricLockEnabled,
    LockTimeout? lockTimeout,
    bool? blockScreenshotsEnabled,
    bool? autoCheckUpdates,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      lockTimeout: lockTimeout ?? this.lockTimeout,
      blockScreenshotsEnabled:
          blockScreenshotsEnabled ?? this.blockScreenshotsEnabled,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
    );
  }
}
