import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../settings/domain/app_settings.dart';
import '../../data/security_repository.dart';
import '../../domain/security_status.dart';

class SecurityNotifier extends StateNotifier<SecurityStatus> {
  SecurityNotifier(
    this._repository, [
    this._settingsRepository,
  ]) : super(const SecurityStatus()) {
    _init();
  }

  final SecurityRepository _repository;
  final SettingsRepository? _settingsRepository;
  DateTime? _lastBackgroundedAt;

  Future<void> _init() async {
    final canBio = await _repository.canCheckBiometrics();
    final isSecure = await _repository.isSecureFlagEnabled();
    bool shouldLock = false;

    if (_settingsRepository != null) {
      final settings = await _settingsRepository.getSettings();
      if (settings.biometricLockEnabled) {
        shouldLock = true;
        if (settings.blockScreenshotsEnabled) {
          await _repository.setSecureFlag(true);
        }
      }
    }

    state = state.copyWith(
      isBiometricsAvailable: canBio,
      isSecureFlagEnabled: isSecure,
      isAppLocked: shouldLock,
      isAuthenticated: !shouldLock,
    );
  }

  Future<bool> unlock() async {
    final success = await _repository.authenticate();
    if (success) {
      state = state.copyWith(isAppLocked: false, isAuthenticated: true);
      _lastBackgroundedAt = null;
    }
    return success;
  }

  void lock() {
    state = state.copyWith(isAppLocked: true, isAuthenticated: false);
  }

  Future<void> setSecureFlag(bool enabled) async {
    await _repository.setSecureFlag(enabled);
    state = state.copyWith(isSecureFlagEnabled: enabled);
  }

  void onAppBackgrounded([DateTime? now]) {
    _lastBackgroundedAt = now ?? DateTime.now();
  }

  /// Checks if background duration exceeds the user-configured [lockTimeout].
  /// If so, locks the app immediately.
  void checkTimeoutAndLock({
    required bool biometricLockEnabled,
    required LockTimeout lockTimeout,
    DateTime? now,
  }) {
    if (!biometricLockEnabled) return;

    if (_lastBackgroundedAt == null) {
      lock();
      return;
    }

    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(_lastBackgroundedAt!);
    if (elapsed.inSeconds >= lockTimeout.seconds) {
      lock();
    }
  }
}

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityStatus>((ref) {
  final repo = ref.watch(securityRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return SecurityNotifier(repo, settingsRepo);
});
