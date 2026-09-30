import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';
import 'package:zeroscroll/features/limits/data/drift_limits_repository.dart';
import 'package:zeroscroll/features/limits/data/limits_repository.dart';
import 'package:zeroscroll/features/notifications/data/notifications_repository.dart';
import 'package:zeroscroll/features/onboarding/data/onboarding_repository.dart';
import 'package:zeroscroll/features/security/data/security_repository.dart';
import 'package:zeroscroll/features/security/presentation/providers/security_provider.dart';
import 'package:zeroscroll/features/security/presentation/screens/app_lock_screen.dart';
import 'package:zeroscroll/features/security/presentation/screens/privacy_screen.dart';
import 'package:zeroscroll/features/settings/data/settings_repository.dart';
import 'package:zeroscroll/features/settings/domain/app_settings.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';
import 'package:zeroscroll/features/shell/presentation/screens/home_screen.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('Security Unit Tests', () {
    late MockSecurityRepository securityRepo;
    late LocalSettingsRepository settingsRepo;

    setUp(() {
      securityRepo = MockSecurityRepository();
      settingsRepo = LocalSettingsRepository();
    });

    test('SecurityNotifier initializes with biometrics and secure flag', () async {
      securityRepo = MockSecurityRepository(canCheck: true, initialSecureFlag: false);
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      await Future.delayed(Duration.zero);
      expect(notifier.state.isBiometricsAvailable, isTrue);
      expect(notifier.state.isSecureFlagEnabled, isFalse);
      expect(notifier.state.isAppLocked, isFalse);
    });

    test('SecurityNotifier locks on launch if biometricLockEnabled is true', () async {
      settingsRepo = LocalSettingsRepository(
        const AppSettings(biometricLockEnabled: true, blockScreenshotsEnabled: true),
      );
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      await Future.delayed(Duration.zero);
      expect(notifier.state.isAppLocked, isTrue);
      expect(notifier.state.isAuthenticated, isFalse);
      expect(securityRepo.setSecureFlagCalls, greaterThanOrEqualTo(1));
    });

    test('SecurityNotifier unlocks on successful authentication', () async {
      securityRepo.authResult = true;
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      notifier.lock();
      expect(notifier.state.isAppLocked, isTrue);

      final success = await notifier.unlock();
      expect(success, isTrue);
      expect(notifier.state.isAppLocked, isFalse);
      expect(notifier.state.isAuthenticated, isTrue);
    });

    test('SecurityNotifier remains locked on failed authentication', () async {
      securityRepo.authResult = false;
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      notifier.lock();
      final success = await notifier.unlock();
      expect(success, isFalse);
      expect(notifier.state.isAppLocked, isTrue);
    });

    test('FLAG_SECURE toggle sets native flag and state', () async {
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      await notifier.setSecureFlag(true);
      expect(notifier.state.isSecureFlagEnabled, isTrue);
      expect(securityRepo.setSecureFlagCalls, equals(1));

      await notifier.setSecureFlag(false);
      expect(notifier.state.isSecureFlagEnabled, isFalse);
      expect(securityRepo.setSecureFlagCalls, equals(2));
    });

    test('checkTimeoutAndLock respects configured LockTimeout durations', () async {
      final notifier = SecurityNotifier(securityRepo, settingsRepo);

      // 1. Immediate timeout: locks even after 0 seconds
      final now0 = DateTime.now();
      notifier.onAppBackgrounded(now0);
      notifier.checkTimeoutAndLock(
        biometricLockEnabled: true,
        lockTimeout: LockTimeout.immediate,
        now: now0,
      );
      expect(notifier.state.isAppLocked, isTrue);

      // Reset
      await notifier.unlock();
      expect(notifier.state.isAppLocked, isFalse);

      // 2. 1-minute timeout: does not lock if elapsed < 60s
      final now1 = DateTime.now();
      notifier.onAppBackgrounded(now1);
      notifier.checkTimeoutAndLock(
        biometricLockEnabled: true,
        lockTimeout: LockTimeout.oneMinute,
        now: now1.add(const Duration(seconds: 30)),
      );
      expect(notifier.state.isAppLocked, isFalse);

      // Locks if elapsed >= 60s
      notifier.checkTimeoutAndLock(
        biometricLockEnabled: true,
        lockTimeout: LockTimeout.oneMinute,
        now: now1.add(const Duration(seconds: 61)),
      );
      expect(notifier.state.isAppLocked, isTrue);

      // Reset
      await notifier.unlock();

      // 3. 5-minute timeout: does not lock if elapsed < 300s, locks if >= 300s
      final now5 = DateTime.now();
      notifier.onAppBackgrounded(now5);
      notifier.checkTimeoutAndLock(
        biometricLockEnabled: true,
        lockTimeout: LockTimeout.fiveMinutes,
        now: now5.add(const Duration(minutes: 3)),
      );
      expect(notifier.state.isAppLocked, isFalse);

      notifier.checkTimeoutAndLock(
        biometricLockEnabled: true,
        lockTimeout: LockTimeout.fiveMinutes,
        now: now5.add(const Duration(minutes: 5, seconds: 1)),
      );
      expect(notifier.state.isAppLocked, isTrue);
    });
  });

  group('AppLockScreen Widget Tests', () {
    testWidgets('AppLockScreen renders shield, title, and triggers unlock', (
      tester,
    ) async {
      final securityRepo = MockSecurityRepository(authResult: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityRepositoryProvider.overrideWithValue(securityRepo),
          ],
          child: const MaterialApp(
            home: AppLockScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ZeroScroll is Locked'), findsOneWidget);
      expect(find.byKey(const ValueKey('app_lock_unlock_button')), findsOneWidget);

      // Verify automatic unlock triggered on mount
      expect(securityRepo.authCalls, equals(1));
    });

    testWidgets('AppLockScreen shows error message when authentication fails', (
      tester,
    ) async {
      final securityRepo = MockSecurityRepository(authResult: false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityRepositoryProvider.overrideWithValue(securityRepo),
          ],
          child: const MaterialApp(
            home: AppLockScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZeroScroll is Locked'), findsOneWidget);
      expect(
        find.text('Authentication required to access your messages and notifications.'),
        findsOneWidget,
      );

      // Tapping unlock retries authentication
      await tester.tap(find.byKey(const ValueKey('app_lock_unlock_button')));
      await tester.pumpAndSettle();
      expect(securityRepo.authCalls, equals(2));
    });
  });

  group('PrivacyScreen Widget Tests', () {
    late LocalNotificationsRepository notifRepo;
    late AppDatabase db;
    late LimitsRepository limitsRepo;
    late LocalSettingsRepository settingsRepo;
    late LocalOnboardingRepository onboardingRepo;

    setUp(() {
      notifRepo = LocalNotificationsRepository();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      limitsRepo = DriftLimitsRepository(db);
      settingsRepo = LocalSettingsRepository();
      onboardingRepo = LocalOnboardingRepository(initialCompleted: true);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createPrivacyApp() {
      final router = GoRouter(
        initialLocation: '/privacy',
        routes: [
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: '/onboarding',
            builder: (context, state) =>
                const Scaffold(body: Text('Onboarding Screen Landing')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(notifRepo),
          limitsRepositoryProvider.overrideWithValue(limitsRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('PrivacyScreen lists local storage items and non-collection guarantees', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createPrivacyApp());
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data Security'), findsOneWidget);
      expect(find.text('Strictly On-Device Architecture'), findsOneWidget);

      // Local storage items
      expect(find.text('Sandboxed WebView Session'), findsOneWidget);
      expect(find.text('Captured Message Alerts'), findsOneWidget);
      expect(find.text('Mindful Limits & Schedules'), findsOneWidget);

      // Never collected guarantees
      expect(find.text('No Remote Backend Servers'), findsOneWidget);
      expect(find.text('No Analytics or Trackers'), findsOneWidget);
      expect(find.text('No Message or Thread Logging'), findsOneWidget);
      expect(find.text('Excluded From Device Backups'), findsOneWidget);
    });

    testWidgets('Clear Captured Notifications displays dialog and clears records', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createPrivacyApp());
      await tester.pumpAndSettle();

      final clearBtnFinder = find.byKey(const ValueKey('clear_notifications_tile'));
      await tester.scrollUntilVisible(clearBtnFinder, 300);
      expect(clearBtnFinder, findsOneWidget);

      await tester.tap(clearBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Clear Captured Notifications?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_clear_notifications_btn')));
      await tester.pumpAndSettle();

      expect(find.text('All captured notifications have been deleted.'), findsOneWidget);
    });

    testWidgets('Log Out and Wipe Data wipes all databases and resets app', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createPrivacyApp());
      await tester.pumpAndSettle();

      final wipeBtnFinder = find.byKey(const ValueKey('logout_and_wipe_tile'));
      await tester.scrollUntilVisible(wipeBtnFinder, 300);
      expect(wipeBtnFinder, findsOneWidget);

      await tester.tap(wipeBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Log Out and Wipe All Data?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm_wipe_all_data_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Onboarding Screen Landing'), findsOneWidget);
      expect(await onboardingRepo.isOnboardingCompleted(), isFalse);
    });
  });

  group('HomeScreen & Settings Security Integration', () {
    testWidgets('HomeScreen renders AppLockScreen when app is locked', (
      tester,
    ) async {
      final securityRepo = MockSecurityRepository(authResult: false);
      final settingsRepo = LocalSettingsRepository(
        const AppSettings(biometricLockEnabled: true),
      );
      final onboardingRepo = LocalOnboardingRepository(initialCompleted: true);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityRepositoryProvider.overrideWithValue(securityRepo),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
            limitsRepositoryProvider.overrideWithValue(DriftLimitsRepository(db)),
            flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lock screen shown, no HomeScreen or WebView
      expect(find.text('ZeroScroll is Locked'), findsOneWidget);
      expect(find.text('Messages'), findsNothing);
    });

    testWidgets('SettingsScreen configures App Lock, Lock Timeout, and FLAG_SECURE', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final securityRepo = MockSecurityRepository(authResult: true);
      final settingsRepo = LocalSettingsRepository();
      final onboardingRepo = LocalOnboardingRepository(initialCompleted: true);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SettingsScreen()),
          ),
          GoRoute(
            path: '/privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            securityRepositoryProvider.overrideWithValue(securityRepo),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
            limitsRepositoryProvider.overrideWithValue(DriftLimitsRepository(db)),
            flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Security section
      final lockTileFinder = find.byKey(const ValueKey('settings_biometric_lock_tile'));
      await tester.scrollUntilVisible(lockTileFinder, 300);
      expect(lockTileFinder, findsOneWidget);

      // Toggle App Lock ON: authenticates and activates
      await tester.tap(lockTileFinder);
      await tester.pumpAndSettle();
      expect(securityRepo.authCalls, equals(1));
      expect(find.text('App lock verified and enabled.'), findsOneWidget);

      // Sub-options appear: Lock Timeout & Block Screenshots
      expect(find.byKey(const ValueKey('settings_lock_timeout_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_block_screenshots_tile')), findsOneWidget);

      // Toggle Block Screenshots ON
      await tester.tap(find.byKey(const ValueKey('settings_block_screenshots_tile')));
      await tester.pumpAndSettle();
      expect(securityRepo.setSecureFlagCalls, greaterThanOrEqualTo(1));

      // Tap Privacy & Data Security tile
      final privacyTileFinder = find.byKey(const ValueKey('settings_privacy_details_tile'));
      await tester.scrollUntilVisible(privacyTileFinder, 200);
      await tester.tap(privacyTileFinder);
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Data Security'), findsOneWidget);
      expect(find.text('Strictly On-Device Architecture'), findsOneWidget);
    });
  });
}
