/// Service contract for checking and recording daily story consumption.
abstract class StoryBudgetService {
  /// Checks whether a new story can be opened today based on budget limits.
  Future<bool> canOpenStory([String? username]);

  /// Records that a story was opened today.
  Future<void> recordStoryViewed([String? username, String? storyId]);

  /// Returns total count of stories opened today (optionally for a specific [username]).
  Future<int> getTodayStoryCount([String? username]);

  /// Returns total count of stories opened between [from] and [to] (optionally for a specific [username]).
  Future<int> getStoryCountForRange(DateTime from, DateTime to, [String? username]);
}
