import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_settings.dart';

/// Repository interface for app settings persistence.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

/// In-memory settings repository for initialization.
class LocalSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return LocalSettingsRepository();
});
