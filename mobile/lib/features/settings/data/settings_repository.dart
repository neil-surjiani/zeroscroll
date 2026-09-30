import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_settings.dart';

/// Repository interface for app settings persistence.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

/// SharedPreferences-backed settings repository.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository([SharedPreferences? prefs])
      : _prefs = prefs;

  SharedPreferences? _prefs;

  static const String _keyThemeMode = 'zeroscroll_theme_mode';
  static const String _keyBiometricLock = 'zeroscroll_biometric_lock';
  static const String _keyLockTimeout = 'zeroscroll_lock_timeout';
  static const String _keyBlockScreenshots = 'zeroscroll_block_screenshots';
  static const String _keyAutoUpdates = 'zeroscroll_auto_updates';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<AppSettings> getSettings() async {
    final prefs = await _getPrefs();
    final themeIndex = prefs.getInt(_keyThemeMode) ?? ThemeMode.system.index;
    final biometric = prefs.getBool(_keyBiometricLock) ?? false;
    final timeoutSec = prefs.getInt(_keyLockTimeout) ?? 0;
    final screenshots = prefs.getBool(_keyBlockScreenshots) ?? false;
    final updates = prefs.getBool(_keyAutoUpdates) ?? true;

    return AppSettings(
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      biometricLockEnabled: biometric,
      lockTimeout: LockTimeout.fromSeconds(timeoutSec),
      blockScreenshotsEnabled: screenshots,
      autoCheckUpdates: updates,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_keyThemeMode, settings.themeMode.index);
    await prefs.setBool(_keyBiometricLock, settings.biometricLockEnabled);
    await prefs.setInt(_keyLockTimeout, settings.lockTimeout.seconds);
    await prefs.setBool(_keyBlockScreenshots, settings.blockScreenshotsEnabled);
    await prefs.setBool(_keyAutoUpdates, settings.autoCheckUpdates);
  }
}

/// In-memory settings repository for testing and fallback.
class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository([AppSettings? initialSettings])
      : _settings = initialSettings ?? const AppSettings();

  AppSettings _settings;

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPreferencesSettingsRepository();
});
