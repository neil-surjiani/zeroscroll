import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/limits_repository.dart';
import '../../domain/focus_schedule.dart';
import '../../domain/limits_config.dart';
import '../../domain/limits_status.dart';
import '../../domain/usage_stats.dart';

/// StateNotifier managing [LimitsConfig] persistence and state.
class LimitsConfigNotifier extends StateNotifier<AsyncValue<LimitsConfig>> {
  LimitsConfigNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConfig();
  }

  final LimitsRepository _repository;

  Future<void> loadConfig() async {
    try {
      final config = await _repository.getLimitsConfig();
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateConfig(LimitsConfig newConfig) async {
    try {
      await _repository.saveLimitsConfig(newConfig);
      state = AsyncValue.data(newConfig);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTimeLimit(bool enabled) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(isDailyTimeLimitEnabled: enabled));
  }

  Future<void> setTimeLimitMinutes(int minutes) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(dailyTimeLimitMinutes: minutes));
  }

  Future<void> toggleReelBudget(bool enabled) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(isReelBudgetEnabled: enabled));
  }

  Future<void> setReelBudget(int budget) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(dailyReelBudget: budget));
  }

  Future<void> setResetDayAt4AM(bool reset) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(resetDayAt4AM: reset));
  }

  Future<void> toggleReplyFriction(bool enabled) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(isReplyFrictionEnabled: enabled));
  }

  Future<void> setMaxEmergencyUnlocks(int max) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    await updateConfig(current.copyWith(maxEmergencyUnlocksPerDay: max));
  }

  Future<void> addFocusSchedule(FocusSchedule schedule) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    final updated = List<FocusSchedule>.from(current.focusSchedules)..add(schedule);
    await updateConfig(current.copyWith(focusSchedules: updated));
  }

  Future<void> updateFocusSchedule(FocusSchedule schedule) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    final updated = current.focusSchedules.map((s) => s.id == schedule.id ? schedule : s).toList();
    await updateConfig(current.copyWith(focusSchedules: updated));
  }

  Future<void> removeFocusSchedule(String scheduleId) async {
    final current = state.valueOrNull ?? const LimitsConfig();
    final updated = current.focusSchedules.where((s) => s.id != scheduleId).toList();
    await updateConfig(current.copyWith(focusSchedules: updated));
  }

  Future<void> recordReelsAvoided() async {
    final current = state.valueOrNull ?? const LimitsConfig();
    final updated = current.copyWith(reelsAvoidedCount: current.reelsAvoidedCount + 1);
    await updateConfig(updated);
  }
}

/// Provider for reactive [LimitsConfig] updates.
final limitsConfigProvider =
    StateNotifierProvider<LimitsConfigNotifier, AsyncValue<LimitsConfig>>((ref) {
  final repo = ref.watch(limitsRepositoryProvider);
  return LimitsConfigNotifier(repo);
});

/// Provider for aggregated usage statistics across 1d, 7d, and 30d windows.
final usageStatsProvider = FutureProvider<UsageStats>((ref) async {
  // Re-fetch when config changes
  ref.watch(limitsConfigProvider);
  final repo = ref.watch(limitsRepositoryProvider);
  return repo.getUsageStats();
});

/// State representation of emergency unlocks.
class EmergencyUnlockState {
  const EmergencyUnlockState({
    required this.isActive,
    required this.usedCount,
    required this.maxCount,
  });

  final bool isActive;
  final int usedCount;
  final int maxCount;

  int get remaining => (maxCount - usedCount).clamp(0, maxCount);
}

/// Notifier managing emergency unlock activation and state.
class EmergencyUnlockNotifier extends StateNotifier<EmergencyUnlockState> {
  EmergencyUnlockNotifier(this._repository)
      : super(const EmergencyUnlockState(isActive: false, usedCount: 0, maxCount: 2)) {
    refresh();
  }

  final LimitsRepository _repository;

  Future<void> refresh() async {
    final config = await _repository.getLimitsConfig();
    final isActive = await _repository.isEmergencyUnlockActive();
    final used = await _repository.getEmergencyUnlocksUsedToday();
    state = EmergencyUnlockState(
      isActive: isActive,
      usedCount: used,
      maxCount: config.maxEmergencyUnlocksPerDay,
    );
  }

  Future<bool> requestUnlock() async {
    final success = await _repository.requestEmergencyUnlock();
    await refresh();
    return success;
  }
}

final emergencyUnlockProvider =
    StateNotifierProvider<EmergencyUnlockNotifier, EmergencyUnlockState>((ref) {
  final repo = ref.watch(limitsRepositoryProvider);
  return EmergencyUnlockNotifier(repo);
});

/// Reactive provider determining whether app access is currently permitted,
/// blocked by focus schedule, or blocked by daily limit.
final activeLimitsStatusProvider = Provider<LimitsStatus>((ref) {
  final configAsync = ref.watch(limitsConfigProvider);
  final emergencyState = ref.watch(emergencyUnlockProvider);

  final config = configAsync.valueOrNull;
  if (config == null) return const AllowedStatus();

  final now = DateTime.now();

  // 1. Focus schedule check (takes precedence)
  final activeSchedule = config.getActiveFocusSchedule(now);
  if (activeSchedule != null) {
    return FocusLockedStatus(activeSchedule);
  }

  // 2. Daily time limit check
  if (config.isDailyTimeLimitEnabled) {
    // If emergency unlock is active, allow access
    if (emergencyState.isActive) {
      return const AllowedStatus();
    }

    final stats = ref.watch(usageStatsProvider).valueOrNull;
    if (stats != null && stats.todayMinutes >= config.dailyTimeLimitMinutes) {
      return DoneForTodayStatus(
        usedMinutes: stats.todayMinutes,
        limitMinutes: config.dailyTimeLimitMinutes,
        emergencyUnlocksRemaining: emergencyState.remaining,
        maxEmergencyUnlocks: config.maxEmergencyUnlocksPerDay,
      );
    }
  }

  return const AllowedStatus();
});
