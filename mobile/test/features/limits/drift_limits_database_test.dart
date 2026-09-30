import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase (Drift SQLite in-memory)', () {
    test('tracks usage sessions and calculates duration within time window', () async {
      final base = DateTime(2026, 9, 30, 10, 0, 0);

      // Session 1: 10:00 to 10:15 (15 mins = 900s)
      final s1 = await db.startUsageSession(base);
      await db.endUsageSession(s1, base.add(const Duration(minutes: 15)));

      // Session 2: 11:00 to 11:10 (10 mins = 600s)
      final s2 = await db.startUsageSession(base.add(const Duration(hours: 1)));
      await db.endUsageSession(s2, base.add(const Duration(hours: 1, minutes: 10)));

      // Query whole day
      final startOfDay = DateTime(2026, 9, 30, 0, 0, 0);
      final endOfDay = DateTime(2026, 9, 30, 23, 59, 59);

      final totalSeconds = await db.getUsageDurationSeconds(startOfDay, endOfDay);
      expect(totalSeconds, 1500); // 15m + 10m = 25m = 1500s

      // Query sub-window (10:05 to 10:20): should clamp session 1 (10:05 to 10:15 = 10m = 600s)
      final subSeconds = await db.getUsageDurationSeconds(
        base.add(const Duration(minutes: 5)),
        base.add(const Duration(minutes: 20)),
      );
      expect(subSeconds, 600);
    });

    test('closeOpenSessions closes unended sessions on crash recovery', () async {
      final start = DateTime(2026, 9, 30, 12, 0, 0);
      await db.startUsageSession(start);

      // Verify open session exists
      final fallbackEnd = DateTime(2026, 9, 30, 12, 5, 0);
      await db.closeOpenSessions(fallbackEnd);

      final sessions = await db.getUsageSessions(
        DateTime(2026, 9, 30, 0, 0),
        DateTime(2026, 9, 30, 23, 59),
      );
      expect(sessions.length, 1);
      expect(sessions.first['endTime'], fallbackEnd.millisecondsSinceEpoch);
    });

    test('records reel events and queries counts within time window', () async {
      final t1 = DateTime(2026, 9, 30, 14, 0, 0);
      final t2 = DateTime(2026, 9, 30, 14, 30, 0);
      final t3 = DateTime(2026, 9, 30, 15, 0, 0);

      await db.recordReelEvent(t1, 'reel_1');
      await db.recordReelEvent(t2, 'reel_2');
      await db.recordReelEvent(t3, 'reel_3');

      final count = await db.getReelsCount(
        DateTime(2026, 9, 30, 14, 15, 0),
        DateTime(2026, 9, 30, 15, 30, 0),
      );
      expect(count, 2); // t2 and t3
    });

    test('persists key-value settings', () async {
      expect(await db.getSetting('test_key'), isNull);

      await db.setSetting('test_key', 'test_value');
      expect(await db.getSetting('test_key'), 'test_value');

      // Update existing
      await db.setSetting('test_key', 'updated_value');
      expect(await db.getSetting('test_key'), 'updated_value');

      await db.deleteSetting('test_key');
      expect(await db.getSetting('test_key'), isNull);
    });

    test('exportAllData and deleteAllData work completely', () async {
      final now = DateTime(2026, 9, 30, 10, 0, 0);
      await db.startUsageSession(now);
      await db.recordReelEvent(now, 'reel_abc');
      await db.setSetting('sample', 'val');

      final exported = await db.exportAllData();
      expect(exported['version'], 1);
      expect((exported['usageSessions'] as List).length, 1);
      expect((exported['reelEvents'] as List).length, 1);
      expect((exported['settings'] as Map)['sample'], 'val');

      // Wipe all data
      await db.deleteAllData();

      final exportedAfterWipe = await db.exportAllData();
      expect((exportedAfterWipe['usageSessions'] as List).isEmpty, isTrue);
      expect((exportedAfterWipe['reelEvents'] as List).isEmpty, isTrue);
      expect((exportedAfterWipe['settings'] as Map).isEmpty, isTrue);
    });
  });
}
