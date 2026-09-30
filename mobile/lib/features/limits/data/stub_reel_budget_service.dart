import '../domain/reel_budget_service.dart';

/// Stub implementation of [ReelBudgetService] that allows reel playback by default,
/// with configurable limit support for testing and future Prompt 7 integration.
class StubReelBudgetService implements ReelBudgetService {
  StubReelBudgetService({this.budgetLimit});

  /// Maximum reels allowed per day (null indicates unlimited budget).
  int? budgetLimit;
  int _todayCount = 0;

  @override
  Future<bool> canOpenReel() async {
    if (budgetLimit != null && _todayCount >= budgetLimit!) {
      return false;
    }
    return true;
  }

  @override
  Future<void> recordReelOpened() async {
    _todayCount++;
  }

  @override
  Future<int> getTodayReelCount() async => _todayCount;

  /// Resets daily count (useful for testing).
  void reset() {
    _todayCount = 0;
  }
}
