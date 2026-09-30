import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/security_repository.dart';
import '../../domain/security_status.dart';

class SecurityNotifier extends StateNotifier<SecurityStatus> {
  SecurityNotifier(this._repository) : super(const SecurityStatus()) {
    _init();
  }

  final SecurityRepository _repository;

  Future<void> _init() async {
    final canBio = await _repository.canCheckBiometrics();
    state = state.copyWith(isBiometricsAvailable: canBio);
  }

  Future<bool> unlock() async {
    final success = await _repository.authenticate();
    if (success) {
      state = state.copyWith(isAppLocked: false, isAuthenticated: true);
    }
    return success;
  }

  void lock() {
    state = state.copyWith(isAppLocked: true, isAuthenticated: false);
  }
}

final securityProvider =
    StateNotifierProvider<SecurityNotifier, SecurityStatus>((ref) {
      final repo = ref.watch(securityRepositoryProvider);
      return SecurityNotifier(repo);
    });
