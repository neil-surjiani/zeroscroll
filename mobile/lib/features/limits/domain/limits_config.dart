import 'package:flutter/material.dart';
import 'focus_schedule.dart';

/// Configuration entity governing daily screen time, reel budgets,
/// focus schedules, and intentional friction.
class LimitsConfig {
  const LimitsConfig({
    this.dailyTimeLimitMinutes = 30,
    this.isDailyTimeLimitEnabled = false,
    this.dailyReelBudget = 3,
    this.isReelBudgetEnabled = true,
    this.maxEmergencyUnlocksPerDay = 2,
    this.emergencyUnlockMinutes = 5,
    this.resetDayAt4AM = false,
    this.isReplyFrictionEnabled = false,
    this.reelsAvoidedCount = 0,
    this.focusSchedules = const [],
    this.deactivatedUntil,
  });

  /// Configured daily app limit in minutes (default 30).
  final int dailyTimeLimitMinutes;

  /// Whether the daily app time limit is actively enforced (default off).
  final bool isDailyTimeLimitEnabled;

  /// When non-null and in the future, the app is strictly deactivated/hard-locked.
  /// No emergency unlocks, extensions, or ignores are permitted until this timestamp.
  final DateTime? deactivatedUntil;

  /// Daily reel consumption budget (default 3, range 0–20).
  final int dailyReelBudget;

  /// Whether reel budget tracking is active (default true).
  final bool isReelBudgetEnabled;

  /// Max emergency 5-min unlock extensions allowed per day (default 2).
  final int maxEmergencyUnlocksPerDay;

  /// Duration of each emergency unlock in minutes (default 5).
  final int emergencyUnlockMinutes;

  /// When true, daily usage counters reset at 4:00 AM instead of midnight.
  final bool resetDayAt4AM;

  /// When true, displays a 5-second hesitation modal before opening reels from DM.
  final bool isReplyFrictionEnabled;

  /// Total count of times the user decided not to open a reel during reply-friction.
  final int reelsAvoidedCount;

  /// List of recurring scheduled focus blocks.
  final List<FocusSchedule> focusSchedules;

  /// Computes the start and end of the active tracking day for [now].
  DateTimeRange getDayWindow(DateTime now) {
    if (resetDayAt4AM) {
      if (now.hour < 4) {
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day, 4, 0, 0);
        final end = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      } else {
        final tomorrow = now.add(const Duration(days: 1));
        final start = DateTime(now.year, now.month, now.day, 4, 0, 0);
        final end = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 3, 59, 59, 999);
        return DateTimeRange(start: start, end: end);
      }
    } else {
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }
  }

  /// Unique key representing the current day cycle (for emergency unlock counting).
  String getDayKey(DateTime now) {
    final window = getDayWindow(now);
    final s = window.start;
    final m = s.month.toString().padLeft(2, '0');
    final d = s.day.toString().padLeft(2, '0');
    return '${s.year}-$m-$d${resetDayAt4AM ? '_4am' : ''}';
  }

  /// Returns the currently active focus schedule at [now], if any.
  FocusSchedule? getActiveFocusSchedule(DateTime now) {
    for (final schedule in focusSchedules) {
      if (schedule.isActiveAt(now)) {
        return schedule;
      }
    }
    return null;
  }

  /// Whether the app is currently in a strict deactivation/lockdown state.
  bool isDeactivated([DateTime? now]) {
    if (deactivatedUntil == null) return false;
    final current = now ?? DateTime.now();
    return deactivatedUntil!.isAfter(current);
  }

  /// Remaining duration of the active deactivation period, or null if not deactivated.
  Duration? getRemainingDeactivation([DateTime? now]) {
    if (!isDeactivated(now)) return null;
    final current = now ?? DateTime.now();
    return deactivatedUntil!.difference(current);
  }

  Map<String, dynamic> toJson() => {
        'dailyTimeLimitMinutes': dailyTimeLimitMinutes,
        'isDailyTimeLimitEnabled': isDailyTimeLimitEnabled,
        'dailyReelBudget': dailyReelBudget,
        'isReelBudgetEnabled': isReelBudgetEnabled,
        'maxEmergencyUnlocksPerDay': maxEmergencyUnlocksPerDay,
        'emergencyUnlockMinutes': emergencyUnlockMinutes,
        'resetDayAt4AM': resetDayAt4AM,
        'isReplyFrictionEnabled': isReplyFrictionEnabled,
        'reelsAvoidedCount': reelsAvoidedCount,
        'focusSchedules': focusSchedules.map((s) => s.toJson()).toList(),
        'deactivatedUntil': deactivatedUntil?.toIso8601String(),
      };

  factory LimitsConfig.fromJson(Map<String, dynamic> json) {
    return LimitsConfig(
      dailyTimeLimitMinutes: json['dailyTimeLimitMinutes'] as int? ?? 30,
      isDailyTimeLimitEnabled: json['isDailyTimeLimitEnabled'] as bool? ?? false,
      dailyReelBudget: json['dailyReelBudget'] as int? ?? 3,
      isReelBudgetEnabled: json['isReelBudgetEnabled'] as bool? ?? true,
      maxEmergencyUnlocksPerDay: json['maxEmergencyUnlocksPerDay'] as int? ?? 2,
      emergencyUnlockMinutes: json['emergencyUnlockMinutes'] as int? ?? 5,
      resetDayAt4AM: json['resetDayAt4AM'] as bool? ?? false,
      isReplyFrictionEnabled: json['isReplyFrictionEnabled'] as bool? ?? false,
      reelsAvoidedCount: json['reelsAvoidedCount'] as int? ?? 0,
      focusSchedules: (json['focusSchedules'] as List<dynamic>?)
              ?.map((e) => FocusSchedule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      deactivatedUntil: json['deactivatedUntil'] != null
          ? DateTime.tryParse(json['deactivatedUntil'] as String)
          : null,
    );
  }

  LimitsConfig copyWith({
    int? dailyTimeLimitMinutes,
    bool? isDailyTimeLimitEnabled,
    int? dailyReelBudget,
    bool? isReelBudgetEnabled,
    int? maxEmergencyUnlocksPerDay,
    int? emergencyUnlockMinutes,
    bool? resetDayAt4AM,
    bool? isReplyFrictionEnabled,
    int? reelsAvoidedCount,
    List<FocusSchedule>? focusSchedules,
    DateTime? deactivatedUntil,
    bool clearDeactivatedUntil = false,
  }) {
    return LimitsConfig(
      dailyTimeLimitMinutes: dailyTimeLimitMinutes ?? this.dailyTimeLimitMinutes,
      isDailyTimeLimitEnabled:
          isDailyTimeLimitEnabled ?? this.isDailyTimeLimitEnabled,
      dailyReelBudget: dailyReelBudget ?? this.dailyReelBudget,
      isReelBudgetEnabled: isReelBudgetEnabled ?? this.isReelBudgetEnabled,
      maxEmergencyUnlocksPerDay:
          maxEmergencyUnlocksPerDay ?? this.maxEmergencyUnlocksPerDay,
      emergencyUnlockMinutes:
          emergencyUnlockMinutes ?? this.emergencyUnlockMinutes,
      resetDayAt4AM: resetDayAt4AM ?? this.resetDayAt4AM,
      isReplyFrictionEnabled:
          isReplyFrictionEnabled ?? this.isReplyFrictionEnabled,
      reelsAvoidedCount: reelsAvoidedCount ?? this.reelsAvoidedCount,
      focusSchedules: focusSchedules ?? this.focusSchedules,
      deactivatedUntil: clearDeactivatedUntil
          ? null
          : (deactivatedUntil ?? this.deactivatedUntil),
    );
  }
}
