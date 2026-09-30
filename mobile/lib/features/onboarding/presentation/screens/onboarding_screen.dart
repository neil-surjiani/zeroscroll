import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../settings/data/feature_preferences_repository.dart';
import '../../../settings/domain/feature_preferences.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/biometrics_step_view.dart';
import '../widgets/limits_step_view.dart';
import '../widgets/login_guide_step_view.dart';
import '../widgets/notifications_step_view.dart';
import '../widgets/preferences_step_view.dart';
import '../widgets/welcome_step_view.dart';

/// Six-step onboarding orchestrator presented on first launch
/// and re-accessible from Settings.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  final GlobalKey<NotificationsStepViewState> _notificationsStepKey =
      GlobalKey<NotificationsStepViewState>();

  int _currentPage = 0;
  static const int _totalPages = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-query permission statuses when user returns from Android Settings
      _notificationsStepKey.currentState?.refreshStatus();
    }
  }

  Future<void> _completeAndExit() async {
    // When skipping onboarding, apply balanced defaults with hasChosenFeatures = true
    final repo = ref.read(featurePreferencesRepositoryProvider);
    final current = await repo.getPreferences();
    if (!current.hasChosenFeatures) {
      final safeDefault = FeaturePreferences.balanced.copyWith(
        hasChosenFeatures: true,
      );
      await repo.savePreferences(safeDefault);
      await ref
          .read(featurePreferencesProvider.notifier)
          .updatePreferences(safeDefault);
    }
    await ref.read(onboardingStateProvider.notifier).complete();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAndExit();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _totalPages - 1;

    return Scaffold(
      appBar: AppBar(
        leading: _currentPage > 0
            ? IconButton(
                key: const ValueKey('onboarding_back_nav_btn'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _previousPage,
                tooltip: 'Back',
              )
            : null,
        title: Text(
          'Step ${_currentPage + 1} of $_totalPages',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            key: const ValueKey('onboarding_skip_btn'),
            onPressed: _completeAndExit,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
              minHeight: 3,
              backgroundColor:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),

            // Page views
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  const WelcomeStepView(),
                  const LoginGuideStepView(),
                  PreferencesStepView(
                    onConfirmed: (prefs) async {
                      await ref
                          .read(featurePreferencesRepositoryProvider)
                          .savePreferences(prefs);
                      await ref
                          .read(featurePreferencesProvider.notifier)
                          .updatePreferences(prefs);
                      _nextPage();
                    },
                    onBackToPreviousStep: _previousPage,
                  ),
                  NotificationsStepView(key: _notificationsStepKey),
                  const BiometricsStepView(),
                  const LimitsStepView(),
                ],
              ),
            ),

            // Bottom Navigation Area (Only show on steps that don't manage their own controls)
            if (_currentPage != 2) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Dot indicator
                    Row(
                      children: List.generate(_totalPages, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),

                    // Continue / Get Started Action Button
                    FilledButton(
                      key: const ValueKey('onboarding_next_btn'),
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
