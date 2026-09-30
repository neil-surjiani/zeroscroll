import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository interface for onboarding persistence.
abstract class OnboardingRepository {
  Future<bool> isOnboardingCompleted();
  Future<void> completeOnboarding();
  Future<void> resetOnboarding();
}

/// SharedPreferences-backed implementation of [OnboardingRepository].
class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  SharedPreferencesOnboardingRepository([SharedPreferences? prefs])
      : _prefs = prefs;

  SharedPreferences? _prefs;
  static const String _keyCompleted = 'zeroscroll_onboarding_completed';

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyCompleted, true);
  }

  @override
  Future<void> resetOnboarding() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyCompleted, false);
  }
}

/// In-memory implementation of [OnboardingRepository] for tests and fallbacks.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository({bool initialCompleted = false})
      : _completed = initialCompleted;

  bool _completed;

  @override
  Future<bool> isOnboardingCompleted() async => _completed;

  @override
  Future<void> completeOnboarding() async {
    _completed = true;
  }

  @override
  Future<void> resetOnboarding() async {
    _completed = false;
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SharedPreferencesOnboardingRepository();
});
