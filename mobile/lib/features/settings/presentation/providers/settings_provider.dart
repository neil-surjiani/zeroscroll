import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/settings_repository.dart';
import '../../domain/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    final settings = await _repository.getSettings();
    state = settings;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _repository.saveSettings(settings);
    state = settings;
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
      final repo = ref.watch(settingsRepositoryProvider);
      return SettingsNotifier(repo);
    });
