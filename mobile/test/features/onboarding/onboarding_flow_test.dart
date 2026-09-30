import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';
import 'package:zeroscroll/features/limits/data/drift_limits_repository.dart';
import 'package:zeroscroll/features/limits/data/limits_repository.dart';
import 'package:zeroscroll/features/notifications/data/notifications_repository.dart';
import 'package:zeroscroll/features/onboarding/data/onboarding_repository.dart';
import 'package:zeroscroll/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:zeroscroll/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:zeroscroll/features/security/data/security_repository.dart';
import 'package:zeroscroll/features/settings/data/feature_preferences_repository.dart';
import 'package:zeroscroll/features/settings/data/settings_repository.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';
import '../../helpers/test_webview_platform.dart';

class FakeSecurityRepository extends MockSecurityRepository {
  FakeSecurityRepository({
    super.canCheck = true,
    super.authResult = true,
  });
}

class TestNotificationsRepository extends LocalNotificationsRepository {
  TestNotificationsRepository({
    bool listenerEnabled = false,
    bool postNotifGranted = false,
    bool batteryIgnored = false,
    int sdkVersion = 33,
  })  : _listener = listenerEnabled,
        _postNotif = postNotifGranted,
        _battery = batteryIgnored,
        _sdk = sdkVersion;

  bool _listener;
  bool _postNotif;
  final bool _battery;
  final int _sdk;

  int openListenerSettingsCalls = 0;
  int openAppInfoSettingsCalls = 0;
  int requestPostNotifCalls = 0;
  int openBatterySettingsCalls = 0;
  int isListenerEnabledCalls = 0;

  @override
  Future<bool> isListenerEnabled() async {
    isListenerEnabledCalls++;
    return _listener;
  }

  @override
  Future<void> openListenerSettings() async {
    openListenerSettingsCalls++;
  }

  @override
  Future<void> openAppInfoSettings() async {
    openAppInfoSettingsCalls++;
  }

  @override
  Future<bool> isPostNotificationsGranted() async => _postNotif;

  @override
  Future<void> requestPostNotificationsPermission() async {
    requestPostNotifCalls++;
    _postNotif = true;
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async => _battery;

  @override
  Future<void> openBatteryOptimizationSettings() async {
    openBatterySettingsCalls++;
  }

  @override
  Future<int> getAndroidSdkVersion() async => _sdk;

  void setListener(bool enabled) {
    _listener = enabled;
  }
}

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('OnboardingRepository & Provider Unit Tests', () {
    test('LocalOnboardingRepository tracks completion state', () async {
      final repo = LocalOnboardingRepository(initialCompleted: false);
      expect(await repo.isOnboardingCompleted(), isFalse);

      await repo.completeOnboarding();
      expect(await repo.isOnboardingCompleted(), isTrue);

      await repo.resetOnboarding();
      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('SharedPreferencesOnboardingRepository persists state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesOnboardingRepository(prefs);

      expect(await repo.isOnboardingCompleted(), isFalse);
      await repo.completeOnboarding();
      expect(await repo.isOnboardingCompleted(), isTrue);

      await repo.resetOnboarding();
      expect(await repo.isOnboardingCompleted(), isFalse);
    });

    test('OnboardingNotifier updates state and repository', () async {
      final repo = LocalOnboardingRepository();
      final notifier = OnboardingNotifier(repo);

      await notifier.load();
      expect(notifier.state, isFalse);

      await notifier.complete();
      expect(notifier.state, isTrue);
      expect(await repo.isOnboardingCompleted(), isTrue);

      await notifier.reset();
      expect(notifier.state, isFalse);
      expect(await repo.isOnboardingCompleted(), isFalse);
    });
  });

  group('OnboardingScreen Widget Tests', () {
    late LocalOnboardingRepository onboardingRepo;
    late TestNotificationsRepository notifRepo;
    late FakeSecurityRepository securityRepo;
    late AppDatabase db;
    late LimitsRepository limitsRepo;
    late LocalSettingsRepository settingsRepo;
    late LocalFeaturePreferencesRepository featureRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      onboardingRepo = LocalOnboardingRepository();
      notifRepo = TestNotificationsRepository();
      securityRepo = FakeSecurityRepository();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      limitsRepo = DriftLimitsRepository(db);
      settingsRepo = LocalSettingsRepository();
      featureRepo = LocalFeaturePreferencesRepository();
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestApp({
      Widget? home,
      GoRouter? router,
    }) {
      final defaultRouter = router ??
          GoRouter(
            initialLocation: '/onboarding',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Text('Home Screen Content')),
              ),
              GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingScreen(),
              ),
            ],
          );

      return ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
          notificationsRepositoryProvider.overrideWithValue(notifRepo),
          securityRepositoryProvider.overrideWithValue(securityRepo),
          limitsRepositoryProvider.overrideWithValue(limitsRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          featurePreferencesRepositoryProvider.overrideWithValue(featureRepo),
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
        ],
        child: MaterialApp.router(
          routerConfig: defaultRouter,
        ),
      );
    }

    testWidgets('Step 1 (Welcome) displays privacy guarantee and copy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Step indicator and title
      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Direct Messages, Zero Clutter'), findsOneWidget);

      // Exact phrase from AGENTS.md / Prompt
      expect(
        find.text("We can't see your messages and nothing leaves your phone."),
        findsOneWidget,
      );

      // What it does vs What it blocks
      expect(find.text('What It Does'), findsOneWidget);
      expect(find.text('What It Blocks'), findsOneWidget);
      expect(find.text('No algorithmic home feed'), findsOneWidget);

      // No back button on Step 1
      expect(find.byKey(const ValueKey('onboarding_back_nav_btn')), findsNothing);
      // Skip button present
      expect(find.byKey(const ValueKey('onboarding_skip_btn')), findsOneWidget);
    });

    testWidgets('Skip button marks onboarding completed and navigates home', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 6'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('onboarding_skip_btn')));
      await tester.pumpAndSettle();

      expect(await onboardingRepo.isOnboardingCompleted(), isTrue);
      expect(find.text('Home Screen Content'), findsOneWidget);
    });

    testWidgets('Walks through all 6 steps and completes onboarding', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Step 1: Welcome
      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 2: Login Guide
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 6'), findsOneWidget);
      expect(find.text('Official, Secure Login'), findsOneWidget);
      expect(
        find.text('Log in on the next screen using the official login page.'),
        findsOneWidget,
      );

      // Back button works
      expect(find.byKey(const ValueKey('onboarding_back_nav_btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_back_nav_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 6'), findsOneWidget);

      // Advance back to Step 2 then to Step 3: Preferences
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      // Step 3: Preferences
      expect(find.text('Step 3 of 6'), findsOneWidget);
      expect(find.text('Choose your preferences'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_preset_balanced')));
      await tester.pumpAndSettle();
      expect(find.text("Here's how ZeroScroll will work for you"), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_preferences_confirm_btn')));
      await tester.pumpAndSettle();

      // Step 4: Notifications Access
      expect(find.text('Step 4 of 6'), findsOneWidget);
      expect(find.text('Stay Updated, Calmly'), findsOneWidget);
      expect(
        find.textContaining('Requirement: This feature requires the official Instagram app installed'),
        findsOneWidget,
      );

      // Tapping Open Listener Settings
      await tester.tap(find.byKey(const ValueKey('open_listener_settings_btn')));
      await tester.pump();
      expect(notifRepo.openListenerSettingsCalls, equals(1));

      // Android 13+ Restricted Settings Guide expansion
      expect(find.byKey(const ValueKey('toggle_restricted_guide_btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('toggle_restricted_guide_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Android 13+ Restricts Sideloaded Apps:'), findsOneWidget);
      expect(find.text('Tap the top-right three dots menu (⋮)'), findsOneWidget);

      // Tap Open App Info
      await tester.tap(find.byKey(const ValueKey('open_app_info_btn')));
      await tester.pump();
      expect(notifRepo.openAppInfoSettingsCalls, equals(1));

      // POST_NOTIFICATIONS permission
      expect(find.byKey(const ValueKey('request_post_notif_btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('request_post_notif_btn')));
      await tester.pumpAndSettle();
      expect(notifRepo.requestPostNotifCalls, equals(1));

      // Battery Optimization Settings
      await tester.tap(find.byKey(const ValueKey('battery_optimization_btn')));
      await tester.pump();
      expect(notifRepo.openBatterySettingsCalls, equals(1));

      // Test lifecycle resume polling
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(notifRepo.isListenerEnabledCalls, greaterThan(1));

      // Advance to Step 5: Biometrics
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 6'), findsOneWidget);
      expect(find.text('Keep It Private'), findsOneWidget);
      expect(find.byKey(const ValueKey('biometrics_toggle_switch')), findsOneWidget);

      // Toggle biometrics on: triggers authenticate() and confirms
      await tester.tap(find.byKey(const ValueKey('biometrics_toggle_switch')));
      await tester.pumpAndSettle();
      expect(securityRepo.authCalls, equals(1));
      expect(find.text('Active: Your messages are protected.'), findsOneWidget);

      // Dismiss snackbar so bottom button is unobstructed
      ScaffoldMessenger.of(tester.element(find.byType(OnboardingScreen))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Advance to Step 6: Limits
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Step 6 of 6'), findsOneWidget);
      expect(find.text('Set Mindful Limits'), findsOneWidget);
      expect(find.text('Daily Reel Budget'), findsOneWidget);
      expect(find.text('3 / day'), findsOneWidget);

      // Check daily time limit switch
      expect(find.byKey(const ValueKey('daily_time_limit_switch')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('daily_time_limit_switch')));
      await tester.pumpAndSettle();
      expect(find.text('30 minutes'), findsOneWidget);

      // Button on last step is "Get Started"
      expect(find.text('Get Started'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      // Onboarding marked completed and navigated to Home
      expect(await onboardingRepo.isOnboardingCompleted(), isTrue);
      expect(find.text('Home Screen Content'), findsOneWidget);
    });

    testWidgets('Step 5 handles biometric authentication failure gracefully', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Configure security repo to fail authentication
      securityRepo.authResult = false;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Advance to Step 5 (Biometrics)
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_preset_strict')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_preferences_confirm_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Step 5 of 6'), findsOneWidget);

      // Attempt to toggle on
      await tester.tap(find.byKey(const ValueKey('biometrics_toggle_switch')));
      await tester.pumpAndSettle();

      expect(securityRepo.authCalls, equals(1));
      expect(
        find.text('Authentication was not completed. Biometrics remained off.'),
        findsOneWidget,
      );
      expect(find.text('Active: Your messages are protected.'), findsNothing);
    });

    testWidgets('Step 5 displays unsupported card when device has no biometrics', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      securityRepo.canCheck = false;

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Advance to Step 5 (Biometrics)
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_preset_strict')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_preferences_confirm_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_next_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Biometrics Not Available'), findsOneWidget);
      expect(find.byKey(const ValueKey('biometrics_toggle_switch')), findsNothing);
    });

    testWidgets('Welcome Guide in Settings screen opens Onboarding flow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SettingsScreen()),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
            notificationsRepositoryProvider.overrideWithValue(notifRepo),
            securityRepositoryProvider.overrideWithValue(securityRepo),
            limitsRepositoryProvider.overrideWithValue(limitsRepo),
            flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
            settingsRepositoryProvider.overrideWithValue(LocalSettingsRepository()),
            featurePreferencesRepositoryProvider.overrideWithValue(featureRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Welcome Guide tile
      final welcomeGuideFinder = find.byKey(const ValueKey('settings_welcome_guide_tile'));
      await tester.scrollUntilVisible(welcomeGuideFinder, 300);
      expect(welcomeGuideFinder, findsOneWidget);

      await tester.tap(welcomeGuideFinder);
      await tester.pumpAndSettle();

      // Onboarding screen is displayed
      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Direct Messages, Zero Clutter'), findsOneWidget);
    });
  });
}
