import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/onboarding_repository.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier(this._repository) : super(false) {
    _load();
  }

  final OnboardingRepository _repository;

  Future<void> _load() async {
    final completed = await _repository.isOnboardingCompleted();
    state = completed;
  }

  Future<void> complete() async {
    await _repository.completeOnboarding();
    state = true;
  }
}

final onboardingStateProvider = StateNotifierProvider<OnboardingNotifier, bool>(
  (ref) {
    final repo = ref.watch(onboardingRepositoryProvider);
    return OnboardingNotifier(repo);
  },
);
