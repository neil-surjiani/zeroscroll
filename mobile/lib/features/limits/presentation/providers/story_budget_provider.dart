import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/drift_story_budget_service.dart';
import '../../data/limits_repository.dart';
import '../../domain/story_budget_service.dart';
import '../../../settings/data/feature_preferences_repository.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';

/// Provider for [StoryBudgetService] backed by Drift.
final storyBudgetServiceProvider = Provider<StoryBudgetService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefsRepo = ref.watch(featurePreferencesRepositoryProvider);
  return DriftStoryBudgetService(db, prefsRepo);
});

/// StateNotifier providing reactive updates for today's watched stories.
final todayStoryCountProvider =
    StateNotifierProvider<TodayStoryCountNotifier, int>((ref) {
      final service = ref.watch(storyBudgetServiceProvider);
      return TodayStoryCountNotifier(service);
    });

class TodayStoryCountNotifier extends StateNotifier<int> {
  TodayStoryCountNotifier(this._service) : super(0) {
    loadCount();
  }

  final StoryBudgetService _service;

  Future<void> loadCount([String? username]) async {
    state = await _service.getTodayStoryCount(username);
  }

  Future<void> recordStoryViewed([String? username, String? storyId]) async {
    await _service.recordStoryViewed(username, storyId);
    state = await _service.getTodayStoryCount();
  }

  Future<void> recordStoryOpened([String? username, String? storyId]) =>
      recordStoryViewed(username, storyId);
}

/// Statistics model for Story consumption windows.
class StoryStats {
  const StoryStats({
    required this.todayStories,
    required this.sevenDayStories,
    required this.thirtyDayStories,
    required this.storiesAvoided,
  });

  final int todayStories;
  final int sevenDayStories;
  final int thirtyDayStories;
  final int storiesAvoided;
}

/// Provider computing aggregated story usage across today, 7d, 30d, and avoided counts.
final storyStatsProvider = FutureProvider<StoryStats>((ref) async {
  final service = ref.watch(storyBudgetServiceProvider);
  final prefs = ref.watch(featurePreferencesProvider);
  final today = ref.watch(todayStoryCountProvider);

  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  final sevenDay = await service.getStoryCountForRange(sevenDaysAgo, now);
  final thirtyDay = await service.getStoryCountForRange(thirtyDaysAgo, now);

  final limit = prefs.dailyStoryLimit;
  final avoided = (limit != null && limit > today) ? (limit - today) : 0;

  return StoryStats(
    todayStories: today,
    sevenDayStories: sevenDay,
    thirtyDayStories: thirtyDay,
    storiesAvoided: avoided,
  );
});
