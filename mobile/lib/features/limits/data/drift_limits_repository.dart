import 'dart:convert';
import '../domain/limits_config.dart';
import '../domain/usage_limit.dart';
import '../domain/usage_stats.dart';
import 'database/app_database.dart';
import 'limits_repository.dart';

/// Concrete implementation of [LimitsRepository] backed by Drift SQLite.
/// Guarantees that all metrics, limits, and settings remain on-device.
class DriftLimitsRepository implements LimitsRepository {
  DriftLimitsRepository(this._db);

  final AppDatabase _db;
  static const String _limitsConfigKey = 'limits_config';

  @override
  Future<LimitsConfig> getLimitsConfig() async {
    final raw = await _db.getSetting(_limitsConfigKey);
    if (raw == null || raw.isEmpty) {
      return const LimitsConfig();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LimitsConfig.fromJson(json);
    } catch (_) {
      return const LimitsConfig();
    }
  }

  @override
  Future<void> saveLimitsConfig(LimitsConfig config) async {
    final raw = jsonEncode(config.toJson());
    await _db.setSetting(_limitsConfigKey, raw);
  }

  @override
  Future<int> getTodayUsageMinutes([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();
    final window = config.getDayWindow(currentTime);
    final seconds = await _db.getUsageDurationSeconds(window.start, window.end);
    return seconds ~/ 60;
  }

  @override
  Future<int> getTodayReelCount([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();
    final window = config.getDayWindow(currentTime);
    return _db.getReelsCount(window.start, window.end);
  }

  @override
  Future<bool> canOpenReel([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();
    if (!config.isReelBudgetEnabled) return true;

    final todayCount = await getTodayReelCount(currentTime);
    return todayCount < config.dailyReelBudget;
  }

  @override
  Future<void> recordReelOpened([DateTime? now, String? reelId]) async {
    final currentTime = now ?? DateTime.now();
    await _db.recordReelEvent(currentTime, reelId);
  }

  @override
  Future<void> incrementReelsAvoided() async {
    final config = await getLimitsConfig();
    await saveLimitsConfig(
      config.copyWith(reelsAvoidedCount: config.reelsAvoidedCount + 1),
    );
  }

  @override
  Future<bool> isEmergencyUnlockActive([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final raw = await _db.getSetting('emergency_unlock_expires_at');
    if (raw == null || raw.isEmpty) return false;
    final expiresAt = int.tryParse(raw);
    if (expiresAt == null) return false;
    return currentTime.millisecondsSinceEpoch < expiresAt;
  }

  @override
  Future<int> getEmergencyUnlocksUsedToday([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();
    final dayKey = config.getDayKey(currentTime);
    final raw = await _db.getSetting('emergency_unlocks_used_$dayKey');
    return int.tryParse(raw ?? '') ?? 0;
  }

  @override
  Future<bool> requestEmergencyUnlock([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();
    final used = await getEmergencyUnlocksUsedToday(currentTime);
    if (used >= config.maxEmergencyUnlocksPerDay) {
      return false;
    }

    final dayKey = config.getDayKey(currentTime);
    await _db.setSetting('emergency_unlocks_used_$dayKey', (used + 1).toString());

    final expiresAt = currentTime
        .add(Duration(minutes: config.emergencyUnlockMinutes))
        .millisecondsSinceEpoch;
    await _db.setSetting('emergency_unlock_expires_at', expiresAt.toString());
    return true;
  }

  @override
  Future<int> startSession(DateTime startTime) async {
    return _db.startUsageSession(startTime);
  }

  @override
  Future<void> endSession(int sessionId, DateTime endTime) async {
    await _db.endUsageSession(sessionId, endTime);
  }

  @override
  Future<void> closeOpenSessions(DateTime fallbackEndTime) async {
    await _db.closeOpenSessions(fallbackEndTime);
  }

  @override
  Future<Map<String, dynamic>> exportData() async {
    return _db.exportAllData();
  }

  @override
  Future<void> wipeAllData() async {
    await _db.deleteAllData();
  }

  @override
  Future<UsageStats> getUsageStats([DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final config = await getLimitsConfig();

    // 1. Today window
    final todayWindow = config.getDayWindow(currentTime);
    final todaySec = await _db.getUsageDurationSeconds(todayWindow.start, todayWindow.end);
    final todayReels = await _db.getReelsCount(todayWindow.start, todayWindow.end);

    // 2. 7-Day window (last 6 days + today)
    final start7d = todayWindow.start.subtract(const Duration(days: 6));
    final sec7d = await _db.getUsageDurationSeconds(start7d, todayWindow.end);
    final reels7d = await _db.getReelsCount(start7d, todayWindow.end);

    // 3. 30-Day window (last 29 days + today)
    final start30d = todayWindow.start.subtract(const Duration(days: 29));
    final sec30d = await _db.getUsageDurationSeconds(start30d, todayWindow.end);
    final reels30d = await _db.getReelsCount(start30d, todayWindow.end);

    // 4. Daily history for past 7 days (including today)
    final history = <DailyStatItem>[];
    for (int i = 6; i >= 0; i--) {
      final dayTarget = currentTime.subtract(Duration(days: i));
      final window = config.getDayWindow(dayTarget);
      final sec = await _db.getUsageDurationSeconds(window.start, window.end);
      final reels = await _db.getReelsCount(window.start, window.end);
      history.add(DailyStatItem(
        date: window.start,
        minutes: sec ~/ 60,
        reels: reels,
      ));
    }

    // 5. Streak calculation: consecutive days under limit (or with intentional sessions)
    int streak = 0;
    for (int i = 0; i < 30; i++) {
      final dayTarget = currentTime.subtract(Duration(days: i));
      final window = config.getDayWindow(dayTarget);
      final sec = await _db.getUsageDurationSeconds(window.start, window.end);
      final mins = sec ~/ 60;
      final reels = await _db.getReelsCount(window.start, window.end);

      final isWithinLimit = !config.isDailyTimeLimitEnabled || mins <= config.dailyTimeLimitMinutes;
      final isWithinBudget = !config.isReelBudgetEnabled || reels <= config.dailyReelBudget;

      if (isWithinLimit && isWithinBudget) {
        streak++;
      } else {
        break;
      }
    }

    return UsageStats(
      todayMinutes: todaySec ~/ 60,
      todayReels: todayReels,
      sevenDayMinutes: sec7d ~/ 60,
      sevenDayReels: reels7d,
      thirtyDayMinutes: sec30d ~/ 60,
      thirtyDayReels: reels30d,
      reelsAvoided: config.reelsAvoidedCount,
      currentStreakDays: streak,
      dailyHistory: history,
    );
  }

  // ==========================================
  // LEGACY / BACKWARD COMPATIBILITY
  // ==========================================

  @override
  Future<UsageLimit> getUsageLimit() async {
    final config = await getLimitsConfig();
    final todayUsage = await getTodayUsageMinutes();
    return UsageLimit(
      dailyLimitMinutes: config.dailyTimeLimitMinutes,
      currentUsageMinutes: todayUsage,
      isLimitEnabled: config.isDailyTimeLimitEnabled,
    );
  }

  @override
  Future<void> saveUsageLimit(UsageLimit limit) async {
    final config = await getLimitsConfig();
    await saveLimitsConfig(
      config.copyWith(
        dailyTimeLimitMinutes: limit.dailyLimitMinutes,
        isDailyTimeLimitEnabled: limit.isLimitEnabled,
      ),
    );
  }

  @override
  Future<void> incrementUsage(int minutes) async {
    final now = DateTime.now();
    await _db.startUsageSession(now.subtract(Duration(minutes: minutes)));
  }
}
