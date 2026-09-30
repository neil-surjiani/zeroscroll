import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/limits_repository.dart';
import 'package:zeroscroll/features/limits/domain/limits_config.dart';
import 'package:zeroscroll/features/limits/domain/limits_status.dart';
import 'package:zeroscroll/features/limits/domain/usage_limit.dart';
import 'package:zeroscroll/features/limits/domain/usage_stats.dart';
import 'package:zeroscroll/features/limits/presentation/providers/limits_state_provider.dart';
import 'package:zeroscroll/features/limits/presentation/screens/limits_screen.dart';
import 'package:zeroscroll/features/limits/presentation/widgets/deactivate_app_dialog.dart';
import 'package:zeroscroll/features/limits/presentation/widgets/deactivated_overlay.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';

class FakeLimitsRepository implements LimitsRepository {
  FakeLimitsRepository([LimitsConfig? initialConfig])
      : config = initialConfig ?? const LimitsConfig();

  LimitsConfig config;
  bool emergencyUnlockActive = false;
  int emergencyUnlocksUsed = 0;

  @override
  Future<LimitsConfig> getLimitsConfig() async => config;

  @override
  Future<void> saveLimitsConfig(LimitsConfig newConfig) async {
    config = newConfig;
  }

  @override
  Future<UsageStats> getUsageStats([DateTime? now]) async => const UsageStats(
        todayMinutes: 10,
        todayReels: 2,
        sevenDayMinutes: 50,
        sevenDayReels: 10,
        thirtyDayMinutes: 200,
        thirtyDayReels: 40,
        reelsAvoided: 5,
        currentStreakDays: 3,
        dailyHistory: [],
      );

  @override
  Future<int> getTodayUsageMinutes([DateTime? now]) async => 10;

  @override
  Future<int> getTodayReelCount([DateTime? now]) async => 2;

  @override
  Future<bool> canOpenReel([DateTime? now]) async => true;

  @override
  Future<void> recordReelOpened([DateTime? now, String? reelId]) async {}

  @override
  Future<void> incrementReelsAvoided() async {}

  @override
  Future<bool> isEmergencyUnlockActive([DateTime? now]) async => emergencyUnlockActive;

  @override
  Future<int> getEmergencyUnlocksUsedToday([DateTime? now]) async => emergencyUnlocksUsed;

  @override
  Future<bool> requestEmergencyUnlock([DateTime? now]) async {
    emergencyUnlockActive = true;
    emergencyUnlocksUsed++;
    return true;
  }

  @override
  Future<int> startSession(DateTime startTime) async => 1;

  @override
  Future<void> endSession(int sessionId, DateTime endTime) async {}

  @override
  Future<void> closeOpenSessions(DateTime fallbackEndTime) async {}

  @override
  Future<Map<String, dynamic>> exportData() async => {};

  @override
  Future<void> wipeAllData() async {}

  @override
  Future<UsageLimit> getUsageLimit() async => const UsageLimit(
        dailyLimitMinutes: 30,
        currentUsageMinutes: 10,
        isLimitEnabled: true,
      );

  @override
  Future<void> saveUsageLimit(UsageLimit limit) async {}

  @override
  Future<void> incrementUsage(int minutes) async {}
}

void main() {
  group('LimitsConfig - Deactivation Domain Logic', () {
    test('isDeactivated and getRemainingDeactivation evaluate correctly against now', () {
      const configInactive = LimitsConfig();
      expect(configInactive.isDeactivated(), isFalse);
      expect(configInactive.getRemainingDeactivation(), isNull);

      final now = DateTime(2026, 9, 30, 12, 0, 0);
      final futureTime = now.add(const Duration(hours: 4));
      final pastTime = now.subtract(const Duration(hours: 1));

      final configActive = LimitsConfig(deactivatedUntil: futureTime);
      expect(configActive.isDeactivated(now), isTrue);
      expect(configActive.getRemainingDeactivation(now), const Duration(hours: 4));

      final configExpired = LimitsConfig(deactivatedUntil: pastTime);
      expect(configExpired.isDeactivated(now), isFalse);
      expect(configExpired.getRemainingDeactivation(now), isNull);
    });

    test('copyWith handles clearDeactivatedUntil properly', () {
      final lockTime = DateTime.now().add(const Duration(days: 2));
      final config = LimitsConfig(deactivatedUntil: lockTime);
      expect(config.deactivatedUntil, equals(lockTime));

      final cleared = config.copyWith(clearDeactivatedUntil: true);
      expect(cleared.deactivatedUntil, isNull);

      final updatedTime = DateTime.now().add(const Duration(days: 5));
      final modified = config.copyWith(deactivatedUntil: updatedTime);
      expect(modified.deactivatedUntil, equals(updatedTime));
    });

    test('toJson and fromJson serialize and deserialize deactivatedUntil correctly', () {
      final lockTime = DateTime(2026, 10, 5, 14, 30, 0);
      final original = LimitsConfig(
        dailyTimeLimitMinutes: 45,
        deactivatedUntil: lockTime,
      );

      final json = original.toJson();
      expect(json['deactivatedUntil'], equals(lockTime.toIso8601String()));

      final restored = LimitsConfig.fromJson(json);
      expect(restored.deactivatedUntil, equals(lockTime));
      expect(restored.dailyTimeLimitMinutes, equals(45));
    });
  });

  group('LimitsStatus - DeactivatedStatus & Precedence', () {
    test('DeactivatedStatus is categorized as locked', () {
      final until = DateTime.now().add(const Duration(hours: 8));
      final status = DeactivatedStatus(deactivatedUntil: until);

      expect(status.isLocked, isTrue);
      expect(status.deactivatedUntil, equals(until));
    });

    test('activeLimitsStatusProvider prioritizes DeactivatedStatus above all others', () async {
      final futureUntil = DateTime.now().add(const Duration(hours: 24));
      final fakeRepo = FakeLimitsRepository(
        LimitsConfig(
          isDailyTimeLimitEnabled: true,
          dailyTimeLimitMinutes: 5,
          deactivatedUntil: futureUntil,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          limitsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(limitsConfigProvider.notifier).loadConfig();
      final status = container.read(activeLimitsStatusProvider);

      expect(status, isA<DeactivatedStatus>());
      final deactivatedStatus = status as DeactivatedStatus;
      expect(deactivatedStatus.deactivatedUntil, equals(futureUntil));
    });
  });

  group('DeactivatedOverlay UI', () {
    testWidgets('renders lock screen, countdown, no-bypass notice, and exit button', (tester) async {
      final unlockTime = DateTime.now().add(const Duration(hours: 4, minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: DeactivatedOverlay(deactivatedUntil: unlockTime),
        ),
      );

      // Verify title & messaging
      expect(find.text('ZeroScroll Deactivated'), findsOneWidget);
      expect(find.textContaining('Self-imposed lock active until'), findsOneWidget);
      expect(find.byKey(const ValueKey('deactivated_countdown_text')), findsOneWidget);
      expect(find.text('No overrides or extensions'), findsOneWidget);
      expect(
        find.textContaining('cannot be bypassed, paused, or postponed by "one more minute"'),
        findsOneWidget,
      );

      // Verify exit app button
      expect(find.byKey(const ValueKey('deactivated_exit_button')), findsOneWidget);

      // Verify NO bypass mechanisms, emergency unlock buttons, or ignore options exist
      expect(find.byKey(const ValueKey('emergency_unlock_button')), findsNothing);
      expect(find.text('Emergency Unlock'), findsNothing);
      expect(find.text('One More Minute'), findsNothing);
      expect(find.text('Ignore Limit'), findsNothing);
      expect(find.text('Bypass'), findsNothing);

      // Verify PopScope is configured to prevent back navigation
      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);

      // Clean up the periodic timer
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('DeactivateAppDialog Flow', () {
    testWidgets('controls unit, presets, checkbox confirmation gating, and submission', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeLimitsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            limitsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => DeactivateAppDialog.show(ctx),
                  child: const Text('Open Deactivate Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the modal bottom sheet
      await tester.tap(find.text('Open Deactivate Dialog'));
      await tester.pumpAndSettle();

      // Dialog title and initial state
      expect(find.text('Deactivate ZeroScroll'), findsOneWidget);
      expect(find.textContaining('Zero-Bypass Lockout'), findsOneWidget);

      final confirmBtnFinder = find.byKey(const ValueKey('deactivate_confirm_button'));
      expect(confirmBtnFinder, findsOneWidget);

      // Initially disabled because confirmation checkbox is unchecked
      var confirmBtn = tester.widget<FilledButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull);

      // Find and toggle the confirmation checkbox
      final checkboxFinder = find.byKey(const ValueKey('deactivate_confirm_checkbox'));
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Now enabled
      confirmBtn = tester.widget<FilledButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNotNull);

      // Switch unit to Days
      await tester.tap(find.text('Days'));
      await tester.pumpAndSettle();

      // Expect day presets (e.g. 1 Day, 2 Days, 3 Days, 7 Days, etc.)
      expect(find.text('7 Days'), findsOneWidget);
      await tester.tap(find.text('7 Days'));
      await tester.pumpAndSettle();

      // Submit deactivation
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      // Verify that repo now has deactivatedUntil set approximately 7 days from now
      final savedConfig = await fakeRepo.getLimitsConfig();
      expect(savedConfig.deactivatedUntil, isNotNull);
      final remaining = savedConfig.deactivatedUntil!.difference(DateTime.now());
      expect(remaining.inDays, inInclusiveRange(6, 7));
    });
  });

  group('Entry Points in Limits & Settings screens', () {
    testWidgets('LimitsScreen contains App Deactivation button', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeLimitsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            limitsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LimitsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('limits_deactivate_app_button')), findsOneWidget);
      expect(find.text('Deactivate ZeroScroll...'), findsOneWidget);
    });

    testWidgets('SettingsScreen contains Deactivate App tile', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeLimitsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            limitsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('settings_deactivate_app_tile')), findsOneWidget);
      expect(find.text('Deactivate App (Hard Lock)'), findsOneWidget);
    });
  });
}
