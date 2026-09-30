import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/limits_config.dart';
import '../domain/reel_budget_service.dart';
import '../domain/usage_limit.dart';
import '../domain/usage_stats.dart';
import 'database/app_database.dart';
import 'drift_limits_repository.dart';

/// Comprehensive repository contract for managing screen time limits,
/// reel budgets, focus schedules, foreground tracking, and data export.
abstract class LimitsRepository implements ReelBudgetService {
  Future<LimitsConfig> getLimitsConfig();
  Future<void> saveLimitsConfig(LimitsConfig config);
  Future<UsageStats> getUsageStats([DateTime? now]);
  Future<int> getTodayUsageMinutes([DateTime? now]);
  @override
  Future<int> getTodayReelCount([DateTime? now]);
  @override
  Future<bool> canOpenReel([DateTime? now]);
  @override
  Future<void> recordReelOpened([DateTime? now, String? reelId]);
  Future<void> incrementReelsAvoided();
  Future<bool> isEmergencyUnlockActive([DateTime? now]);
  Future<int> getEmergencyUnlocksUsedToday([DateTime? now]);
  Future<bool> requestEmergencyUnlock([DateTime? now]);
  Future<int> startSession(DateTime startTime);
  Future<void> endSession(int sessionId, DateTime endTime);
  Future<void> closeOpenSessions(DateTime fallbackEndTime);
  Future<Map<String, dynamic>> exportData();
  Future<void> wipeAllData();

  // Backward compatibility helpers
  Future<UsageLimit> getUsageLimit();
  Future<void> saveUsageLimit(UsageLimit limit);
  Future<void> incrementUsage(int minutes);
}

/// Provider for local Drift database instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Default provider for [LimitsRepository] backed by Drift SQLite.
final limitsRepositoryProvider = Provider<LimitsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftLimitsRepository(db);
});
