/// Service contract for checking and recording daily reel consumption.
abstract class ReelBudgetService {
  /// Checks whether a new reel can be opened today based on budget limits.
  Future<bool> canOpenReel();

  /// Records that a reel was opened today.
  Future<void> recordReelOpened();

  /// Returns total count of reels opened today.
  Future<int> getTodayReelCount();
}
