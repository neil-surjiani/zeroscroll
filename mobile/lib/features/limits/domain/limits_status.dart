import 'focus_schedule.dart';

/// Represents the active access state of the app under current limits.
sealed class LimitsStatus {
  const LimitsStatus();

  bool get isLocked => this is FocusLockedStatus || this is DoneForTodayStatus;
}

/// Normal operation: app is unlocked and accessible.
class AllowedStatus extends LimitsStatus {
  const AllowedStatus();
}

/// Active focus schedule is in effect: access is locked and notifications muted.
class FocusLockedStatus extends LimitsStatus {
  const FocusLockedStatus(this.schedule);

  final FocusSchedule schedule;
}

/// Daily screen time budget has been reached: access is locked unless
/// an emergency unlock is active.
class DoneForTodayStatus extends LimitsStatus {
  const DoneForTodayStatus({
    required this.usedMinutes,
    required this.limitMinutes,
    required this.emergencyUnlocksRemaining,
    required this.maxEmergencyUnlocks,
  });

  final int usedMinutes;
  final int limitMinutes;
  final int emergencyUnlocksRemaining;
  final int maxEmergencyUnlocks;
}
