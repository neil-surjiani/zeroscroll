/// Entity representing daily time usage and focus thresholds.
class UsageLimit {
  const UsageLimit({
    required this.dailyLimitMinutes,
    required this.currentUsageMinutes,
    required this.isLimitEnabled,
  });

  final int dailyLimitMinutes;
  final int currentUsageMinutes;
  final bool isLimitEnabled;

  bool get isLimitExceeded =>
      isLimitEnabled && currentUsageMinutes >= dailyLimitMinutes;

  int get remainingMinutes {
    if (!isLimitEnabled) return -1;
    final diff = dailyLimitMinutes - currentUsageMinutes;
    return diff > 0 ? diff : 0;
  }

  UsageLimit copyWith({
    int? dailyLimitMinutes,
    int? currentUsageMinutes,
    bool? isLimitEnabled,
  }) {
    return UsageLimit(
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      currentUsageMinutes: currentUsageMinutes ?? this.currentUsageMinutes,
      isLimitEnabled: isLimitEnabled ?? this.isLimitEnabled,
    );
  }
}
