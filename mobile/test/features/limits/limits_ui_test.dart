import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';
import 'package:zeroscroll/features/limits/data/drift_limits_repository.dart';
import 'package:zeroscroll/features/limits/data/limits_repository.dart';
import 'package:zeroscroll/features/limits/domain/focus_schedule.dart';
import 'package:zeroscroll/features/limits/domain/limits_status.dart';
import 'package:zeroscroll/features/limits/domain/usage_stats.dart';
import 'package:zeroscroll/features/limits/presentation/providers/limits_state_provider.dart';
import 'package:zeroscroll/features/limits/presentation/screens/limits_screen.dart';
import 'package:zeroscroll/features/limits/presentation/screens/stats_screen.dart';
import 'package:zeroscroll/features/limits/presentation/widgets/done_for_today_overlay.dart';
import 'package:zeroscroll/features/limits/presentation/widgets/focus_locked_overlay.dart';
import 'package:zeroscroll/features/limits/presentation/widgets/reply_friction_dialog.dart';

void main() {
  group('Limits UI & Overlays', () {
    testWidgets('DoneForTodayOverlay displays time reached and emergency unlock', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DoneForTodayOverlay(
              status: DoneForTodayStatus(
                usedMinutes: 45,
                limitMinutes: 30,
                emergencyUnlocksRemaining: 2,
                maxEmergencyUnlocks: 2,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Done for Today'), findsOneWidget);
      expect(find.textContaining('30 minutes'), findsOneWidget);
      expect(find.byKey(const ValueKey('emergency_unlock_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('close_app_button')), findsOneWidget);
    });

    testWidgets('FocusLockedOverlay displays schedule title, time, and explanation', (tester) async {
      final schedule = FocusSchedule(
        id: '1',
        name: 'Deep Sleep',
        startHour: 22,
        startMinute: 0,
        endHour: 6,
        endMinute: 0,
        weekdays: [1, 2, 3, 4, 5, 6, 7],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FocusLockedOverlay(schedule: schedule),
        ),
      );

      expect(find.text('Focus Mode Active'), findsOneWidget);
      expect(find.text('Deep Sleep'), findsOneWidget);
      expect(find.text('22:00 – 06:00'), findsOneWidget);
      expect(find.byKey(const ValueKey('focus_close_app_button')), findsOneWidget);
    });

    testWidgets('ReplyFrictionDialog disables open button until countdown finishes', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReplyFrictionDialog(),
            ),
          ),
        ),
      );

      expect(find.text('Mindful Pause'), findsOneWidget);
      expect(find.byKey(const ValueKey('reply_friction_cancel_button')), findsOneWidget);

      final openBtnFinder = find.byKey(const ValueKey('reply_friction_continue_button'));
      expect(openBtnFinder, findsOneWidget);

      // Initially disabled
      final btnBefore = tester.widget<FilledButton>(openBtnFinder);
      expect(btnBefore.onPressed, isNull);

      // Advance time by 5 seconds
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Now enabled
      final btnAfter = tester.widget<FilledButton>(openBtnFinder);
      expect(btnAfter.onPressed, isNotNull);
    });

    testWidgets('StatsScreen renders metrics, streaks, and weekly bar chart', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftLimitsRepository(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            limitsRepositoryProvider.overrideWithValue(repo),
            usageStatsProvider.overrideWith((ref) async => UsageStats(
                  todayMinutes: 22,
                  todayReels: 3,
                  sevenDayMinutes: 110,
                  sevenDayReels: 14,
                  thirtyDayMinutes: 450,
                  thirtyDayReels: 55,
                  reelsAvoided: 8,
                  currentStreakDays: 5,
                  dailyHistory: [
                    DailyStatItem(date: DateTime(2026, 9, 24), minutes: 15, reels: 2),
                    DailyStatItem(date: DateTime(2026, 9, 25), minutes: 20, reels: 3),
                    DailyStatItem(date: DateTime(2026, 9, 26), minutes: 10, reels: 1),
                    DailyStatItem(date: DateTime(2026, 9, 27), minutes: 25, reels: 4),
                    DailyStatItem(date: DateTime(2026, 9, 28), minutes: 18, reels: 2),
                    DailyStatItem(date: DateTime(2026, 9, 29), minutes: 0, reels: 0),
                    DailyStatItem(date: DateTime(2026, 9, 30), minutes: 22, reels: 3),
                  ],
                )),
          ],
          child: const MaterialApp(
            home: StatsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Intentional Stats'), findsOneWidget);
      expect(find.text('5-Day Intentional Streak'), findsOneWidget);
      expect(find.text('8 Reels Avoided'), findsOneWidget);
      expect(find.text('7-Day App Usage'), findsOneWidget);
      expect(find.text('22m'), findsWidgets); // Today stat and chart

      await db.close();
    });

    testWidgets('LimitsScreen renders all configuration sections', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DriftLimitsRepository(db);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            limitsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: LimitsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Limits & Focus'), findsOneWidget);
      expect(find.text('Daily App Limit'), findsOneWidget);
      expect(find.text('Reel Budget'), findsOneWidget);
      expect(find.text('Reply-Friction Pause'), findsOneWidget);
      expect(find.text('Reset Day at 4:00 AM'), findsOneWidget);
      expect(find.text('Export My Data (JSON)'), findsOneWidget);
      expect(find.text('Delete All My Data'), findsOneWidget);

      await db.close();
    });
  });
}
