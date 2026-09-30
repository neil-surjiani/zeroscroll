/// Individual day's usage statistics for chart rendering and trends.
class DailyStatItem {
  const DailyStatItem({
    required this.date,
    required this.minutes,
    required this.reels,
  });

  final DateTime date;
  final int minutes;
  final int reels;
}

/// Aggregated usage statistics across multiple time windows.
class UsageStats {
  const UsageStats({
    required this.todayMinutes,
    required this.todayReels,
    required this.sevenDayMinutes,
    required this.sevenDayReels,
    required this.thirtyDayMinutes,
    required this.thirtyDayReels,
    required this.reelsAvoided,
    required this.currentStreakDays,
    required this.dailyHistory,
  });

  final int todayMinutes;
  final int todayReels;
  final int sevenDayMinutes;
  final int sevenDayReels;
  final int thirtyDayMinutes;
  final int thirtyDayReels;
  final int reelsAvoided;
  final int currentStreakDays;
  final List<DailyStatItem> dailyHistory;

  double get averageDailyMinutes7d =>
      sevenDayMinutes == 0 ? 0 : (sevenDayMinutes / 7.0);

  double get averageDailyMinutes30d =>
      thirtyDayMinutes == 0 ? 0 : (thirtyDayMinutes / 30.0);
}
