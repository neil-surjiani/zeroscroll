import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';
import 'package:zeroscroll/features/limits/data/drift_limits_repository.dart';
import 'package:zeroscroll/features/limits/domain/limits_config.dart';

void main() {
  late AppDatabase db;
  late DriftLimitsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftLimitsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftLimitsRepository', () {
    test('time tracking records sessions and returns today usage minutes', () async {
      final now = DateTime(2026, 9, 30, 11, 0, 0);

      // Session: 11:00 to 11:25 = 25 minutes
      final sid = await repo.startSession(now);
      await repo.endSession(sid, now.add(const Duration(minutes: 25)));

      final minutes = await repo.getTodayUsageMinutes(now);
      expect(minutes, 25);
    });

    test('emergency 5-minute unlock is limited to max per day and expires', () async {
      final now = DateTime(2026, 9, 30, 14, 0, 0);

      // Initially no unlock
      expect(await repo.isEmergencyUnlockActive(now), isFalse);
      expect(await repo.getEmergencyUnlocksUsedToday(now), 0);

      // 1st request -> success
      expect(await repo.requestEmergencyUnlock(now), isTrue);
      expect(await repo.isEmergencyUnlockActive(now), isTrue);
      expect(await repo.getEmergencyUnlocksUsedToday(now), 1);

      // 4 minutes later -> still active
      final fourMinsLater = now.add(const Duration(minutes: 4));
      expect(await repo.isEmergencyUnlockActive(fourMinsLater), isTrue);

      // 6 minutes later -> expired
      final sixMinsLater = now.add(const Duration(minutes: 6));
      expect(await repo.isEmergencyUnlockActive(sixMinsLater), isFalse);

      // 2nd request at 6 mins later -> success (max is 2)
      expect(await repo.requestEmergencyUnlock(sixMinsLater), isTrue);
      expect(await repo.getEmergencyUnlocksUsedToday(sixMinsLater), 2);

      // 3rd request -> rejected (max 2 per day)
      expect(await repo.requestEmergencyUnlock(sixMinsLater), isFalse);
      expect(await repo.getEmergencyUnlocksUsedToday(sixMinsLater), 2);
    });

    test('incrementReelsAvoided increments counter and preserves configuration', () async {
      final initial = await repo.getLimitsConfig();
      expect(initial.reelsAvoidedCount, 0);

      await repo.incrementReelsAvoided();
      await repo.incrementReelsAvoided();

      final updated = await repo.getLimitsConfig();
      expect(updated.reelsAvoidedCount, 2);
    });

    test('exportData and wipeAllData operate cleanly on-device', () async {
      final now = DateTime(2026, 9, 30, 10, 0, 0);
      await repo.startSession(now);
      await repo.recordReelOpened(now, 'test_reel');
      await repo.saveLimitsConfig(const LimitsConfig(dailyReelBudget: 5));

      final exported = await repo.exportData();
      expect(exported['version'], 1);
      expect((exported['usageSessions'] as List).length, 1);
      expect((exported['reelEvents'] as List).length, 1);

      // Wipe everything
      await repo.wipeAllData();

      final exportedAfter = await repo.exportData();
      expect((exportedAfter['usageSessions'] as List).isEmpty, isTrue);
      expect((exportedAfter['reelEvents'] as List).isEmpty, isTrue);
    });

    test('getUsageStats aggregates 1d, 7d, 30d, streaks, and history', () async {
      final now = DateTime(2026, 9, 30, 12, 0, 0);

      // Record 30 mins session today
      final sid = await repo.startSession(now);
      await repo.endSession(sid, now.add(const Duration(minutes: 30)));
      await repo.recordReelOpened(now);
      await repo.recordReelOpened(now);

      // Record 10 mins yesterday
      final yesterday = now.subtract(const Duration(days: 1));
      final sidY = await repo.startSession(yesterday);
      await repo.endSession(sidY, yesterday.add(const Duration(minutes: 10)));

      final stats = await repo.getUsageStats(now);
      expect(stats.todayMinutes, 30);
      expect(stats.todayReels, 2);
      expect(stats.sevenDayMinutes, 40); // 30 + 10
      expect(stats.dailyHistory.length, 7);
      expect(stats.currentStreakDays, greaterThanOrEqualTo(1));
    });
  });
}
