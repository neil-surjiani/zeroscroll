import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/database/app_database.dart';
import 'package:zeroscroll/features/limits/data/drift_story_budget_service.dart';
import 'package:zeroscroll/features/settings/data/feature_preferences_repository.dart';
import 'package:zeroscroll/features/settings/domain/feature_preferences.dart';

void main() {
  late AppDatabase db;
  late FeaturePreferencesRepository prefsRepo;
  late DriftStoryBudgetService storyBudgetService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    prefsRepo = DriftFeaturePreferencesRepository(db);
    storyBudgetService = DriftStoryBudgetService(db, prefsRepo);
  });

  tearDown(() async {
    await db.close();
  });

  group('FeaturePreferences Domain & Persistence', () {
    test('defaults are mindful and privacy-safe (Stories strictly OFF by default)', () async {
      final prefs = await prefsRepo.getPreferences();

      expect(prefs.storiesViewMode, StoriesViewMode.off);
      expect(prefs.areStoriesEnabled, isFalse);
      expect(prefs.areStoriesFromFollowingEnabled, isFalse);
      expect(prefs.dailyStoryLimit, 10);
      expect(prefs.reelsFromDmsEnabled, isTrue);
      expect(prefs.sharedPostsFromDmsEnabled, isTrue);
      expect(prefs.storiesPostingEnabled, isFalse);
    });

    test('can update preferences and persist them across reads', () async {
      const updated = FeaturePreferences(
        reelsFromDmsEnabled: false,
        storiesViewMode: StoriesViewMode.fromFollowing,
        storiesPostingEnabled: true,
        sharedPostsFromDmsEnabled: false,
        dailyStoryLimit: 5,
      );

      await prefsRepo.savePreferences(updated);
      final retrieved = await prefsRepo.getPreferences();

      expect(retrieved.storiesViewMode, StoriesViewMode.fromFollowing);
      expect(retrieved.areStoriesEnabled, isTrue);
      expect(retrieved.areStoriesFromFollowingEnabled, isTrue);
      expect(retrieved.dailyStoryLimit, 5);
      expect(retrieved.reelsFromDmsEnabled, isFalse);
      expect(retrieved.sharedPostsFromDmsEnabled, isFalse);
      expect(retrieved.storiesPostingEnabled, isTrue);
    });

    test('supports setting dailyStoryLimit to null (unlimited)', () async {
      final current = await prefsRepo.getPreferences();
      final updated = current.copyWith(clearDailyStoryLimit: true);

      await prefsRepo.savePreferences(updated);
      final retrieved = await prefsRepo.getPreferences();

      expect(retrieved.dailyStoryLimit, isNull);
    });
  });

  group('DriftStoryBudgetService', () {
    test('enforces daily story limit', () async {
      await prefsRepo.savePreferences(
        const FeaturePreferences(
          storiesViewMode: StoriesViewMode.fromFollowing,
          dailyStoryLimit: 2,
        ),
      );

      expect(await storyBudgetService.canOpenStory(), isTrue);
      expect(await storyBudgetService.getTodayStoryCount(), 0);

      // Open 1st story
      await storyBudgetService.recordStoryViewed('user_a', 's1');
      expect(await storyBudgetService.getTodayStoryCount(), 1);
      expect(await storyBudgetService.canOpenStory(), isTrue);

      // Open 2nd story
      await storyBudgetService.recordStoryViewed('user_a', 's2');
      expect(await storyBudgetService.getTodayStoryCount(), 2);

      // Budget reached!
      expect(await storyBudgetService.canOpenStory(), isFalse);
    });

    test('unlimited stories when dailyStoryLimit is null', () async {
      await prefsRepo.savePreferences(
        const FeaturePreferences(
          storiesViewMode: StoriesViewMode.fromFollowing,
          dailyStoryLimit: null,
        ),
      );

      for (int i = 0; i < 20; i++) {
        await storyBudgetService.recordStoryViewed('user_test', 's$i');
      }

      expect(await storyBudgetService.getTodayStoryCount(), 20);
      expect(await storyBudgetService.canOpenStory(), isTrue);
    });

    test('getStoryCountForRange calculates correct window count', () async {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));

      await storyBudgetService.recordStoryViewed('user_old', 's_old', twoDaysAgo);
      await storyBudgetService.recordStoryViewed('user_today', 's_today', now);

      final todayCount = await storyBudgetService.getTodayStoryCount();
      expect(todayCount, 1);

      final totalRange = await storyBudgetService.getStoryCountForRange(
        now.subtract(const Duration(days: 5)),
        now.add(const Duration(hours: 1)),
      );
      expect(totalRange, 2);
    });
  });
}
