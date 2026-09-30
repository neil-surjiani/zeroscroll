import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository interface for onboarding persistence.
abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();
}

/// Local implementation of [OnboardingRepository].
class LocalOnboardingRepository implements OnboardingRepository {
  bool _completed = false;

  @override
  Future<bool> isOnboardingCompleted() async => _completed;

  @override
  Future<void> completeOnboarding() async {
    _completed = true;
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return LocalOnboardingRepository();
});
