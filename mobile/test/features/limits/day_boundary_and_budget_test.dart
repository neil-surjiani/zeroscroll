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

  group('Day Boundaries & 4 AM Reset', () {
    test('standard midnight day boundary partitions days correctly', () {
      const config = LimitsConfig(resetDayAt4AM: false);

      final lateNight = DateTime(2026, 9, 30, 23, 59, 30);
      final earlyMorning = DateTime(2026, 10, 1, 0, 0, 30);

      final lateWindow = config.getDayWindow(lateNight);
      final earlyWindow = config.getDayWindow(earlyMorning);

      expect(lateWindow.start, DateTime(2026, 9, 30, 0, 0, 0));
      expect(lateWindow.end, DateTime(2026, 9, 30, 23, 59, 59, 999));

      expect(earlyWindow.start, DateTime(2026, 10, 1, 0, 0, 0));
      expect(earlyWindow.end, DateTime(2026, 10, 1, 23, 59, 59, 999));
    });

    test('4 AM reset day boundary keeps late night in previous day cycle', () {
      const config = LimitsConfig(resetDayAt4AM: true);

      // 03:30 AM on Oct 1 belongs to the Sep 30 cycle (04:00 Sep 30 to 03:59:59 Oct 1)
      final nightOwlTime = DateTime(2026, 10, 1, 3, 30, 0);
      final nightWindow = config.getDayWindow(nightOwlTime);

      expect(nightWindow.start, DateTime(2026, 9, 30, 4, 0, 0));
      expect(nightWindow.end, DateTime(2026, 10, 1, 3, 59, 59, 999));

      // 04:05 AM on Oct 1 begins the Oct 1 cycle (04:00 Oct 1 to 03:59:59 Oct 2)
      final dawnTime = DateTime(2026, 10, 1, 4, 5, 0);
      final dawnWindow = config.getDayWindow(dawnTime);

      expect(dawnWindow.start, DateTime(2026, 10, 1, 4, 0, 0));
      expect(dawnWindow.end, DateTime(2026, 10, 2, 3, 59, 59, 999));
    });

    test('reels opened at 2 AM count toward previous day when 4 AM reset is enabled', () async {
      await repo.saveLimitsConfig(
        const LimitsConfig(
          resetDayAt4AM: true,
          dailyReelBudget: 2,
        ),
      );

      // User opens 2 reels at 2:00 AM and 2:30 AM on Oct 1
      final reelTime1 = DateTime(2026, 10, 1, 2, 0, 0);
      final reelTime2 = DateTime(2026, 10, 1, 2, 30, 0);

      await repo.recordReelOpened(reelTime1);
      await repo.recordReelOpened(reelTime2);

      // Check count at 3:00 AM on Oct 1: budget should be full (2 reels)
      final at3AM = DateTime(2026, 10, 1, 3, 0, 0);
      expect(await repo.getTodayReelCount(at3AM), 2);
      expect(await repo.canOpenReel(at3AM), isFalse);

      // At 4:01 AM on Oct 1: new cycle begins, budget automatically resets!
      final at401AM = DateTime(2026, 10, 1, 4, 1, 0);
      expect(await repo.getTodayReelCount(at401AM), 0);
      expect(await repo.canOpenReel(at401AM), isTrue);
    });

    test('daily reel budget enforces default allowance (3) and blocks 4th reel', () async {
      // Default budget is 3
      final now = DateTime(2026, 9, 30, 14, 0, 0);

      expect(await repo.canOpenReel(now), isTrue);
      await repo.recordReelOpened(now);

      expect(await repo.canOpenReel(now), isTrue);
      await repo.recordReelOpened(now);

      expect(await repo.canOpenReel(now), isTrue);
      await repo.recordReelOpened(now);

      // 3 opened, 4th must be blocked
      expect(await repo.getTodayReelCount(now), 3);
      expect(await repo.canOpenReel(now), isFalse);

      // If budget is disabled, opening is unrestricted
      await repo.saveLimitsConfig(const LimitsConfig(isReelBudgetEnabled: false));
      expect(await repo.canOpenReel(now), isTrue);
    });
  });
}
