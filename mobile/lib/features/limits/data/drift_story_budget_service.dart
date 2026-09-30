import '../../settings/data/feature_preferences_repository.dart';
import '../domain/story_budget_service.dart';
import 'database/app_database.dart';

/// Concrete implementation of [StoryBudgetService] backed by Drift SQLite.
/// Ensures all story analytics and quotas remain strictly on-device.
class DriftStoryBudgetService implements StoryBudgetService {
  DriftStoryBudgetService(this._db, this._prefsRepo);

  final AppDatabase _db;
  final FeaturePreferencesRepository _prefsRepo;

  @override
  Future<bool> canOpenStory([String? username, DateTime? now]) async {
    final prefs = await _prefsRepo.getPreferences();
    if (prefs.dailyStoryLimit == null) {
      return true;
    }
    final count = await getTodayStoryCount(username, now);
    return count < prefs.dailyStoryLimit!;
  }

  @override
  Future<void> recordStoryViewed([
    String? username,
    String? storyId,
    DateTime? now,
  ]) async {
    final currentTime = now ?? DateTime.now();
    await _db.recordStoryEvent(currentTime, username, storyId);
  }

  @override
  Future<int> getTodayStoryCount([String? username, DateTime? now]) async {
    final currentTime = now ?? DateTime.now();
    final startOfDay = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final endOfDay = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      23,
      59,
      59,
      999,
    );
    return _db.getStoryCount(startOfDay, endOfDay, username);
  }

  @override
  Future<int> getStoryCountForRange(
    DateTime from,
    DateTime to, [
    String? username,
  ]) async {
    return _db.getStoryCount(from, to, username);
  }
}

/// In-memory implementation of [StoryBudgetService] for testing.
class LocalStoryBudgetService implements StoryBudgetService {
  LocalStoryBudgetService({this.dailyLimit = 10});

  int? dailyLimit;
  int _count = 0;

  @override
  Future<bool> canOpenStory([String? username]) async {
    if (dailyLimit == null) return true;
    return _count < dailyLimit!;
  }

  @override
  Future<void> recordStoryViewed([String? username, String? storyId]) async {
    _count++;
  }

  @override
  Future<int> getTodayStoryCount([String? username]) async => _count;

  @override
  Future<int> getStoryCountForRange(
    DateTime from,
    DateTime to, [
    String? username,
  ]) async => _count;

  void reset() {
    _count = 0;
  }
}
