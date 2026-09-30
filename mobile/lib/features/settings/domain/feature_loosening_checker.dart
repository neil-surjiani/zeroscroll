import 'feature_preferences.dart';

/// Helper to determine whether an updated [FeaturePreferences] loosens restrictions
/// compared to the current active preferences.
///
/// Loosening requires a confirmation modal and a 10-second pause, and can be optionally
/// delayed for 24 hours. Tightening restrictions applies immediately.
class FeatureLooseningChecker {
  const FeatureLooseningChecker._();

  /// Evaluates whether [target] contains any loosened restriction compared to [current].
  static bool isLoosening({
    required FeaturePreferences current,
    required FeaturePreferences target,
  }) {
    // 1. Reels: off -> on
    if (!current.reelsFromDmsEnabled && target.reelsFromDmsEnabled) {
      return true;
    }

    // 1b. Reels budget: increased or made unlimited
    if (current.reelsFromDmsEnabled && target.reelsFromDmsEnabled) {
      if (current.dailyReelLimit != null && target.dailyReelLimit == null) {
        return true;
      }
      if (current.dailyReelLimit != null &&
          target.dailyReelLimit != null &&
          target.dailyReelLimit! > current.dailyReelLimit!) {
        return true;
      }
    }

    // 2. Stories: off -> any active mode
    if (current.storiesViewMode == StoriesViewMode.off &&
        target.storiesViewMode != StoriesViewMode.off) {
      return true;
    }

    // 2b. Stories: from DMs only -> from following
    if (current.storiesViewMode == StoriesViewMode.fromDmsOnly &&
        target.storiesViewMode == StoriesViewMode.fromFollowing) {
      return true;
    }

    // 2c. Stories budget: increased or made unlimited
    if (current.storiesViewMode != StoriesViewMode.off &&
        target.storiesViewMode != StoriesViewMode.off) {
      if (current.dailyStoryLimit != null && target.dailyStoryLimit == null) {
        return true;
      }
      if (current.dailyStoryLimit != null &&
          target.dailyStoryLimit != null &&
          target.dailyStoryLimit! > current.dailyStoryLimit!) {
        return true;
      }
    }

    // 3. Story posting: off -> on
    if (!current.storiesPostingEnabled && target.storiesPostingEnabled) {
      return true;
    }

    // 4. Shared posts from DMs: off -> on
    if (!current.sharedPostsFromDmsEnabled && target.sharedPostsFromDmsEnabled) {
      return true;
    }

    // 5. Notifications: messages only -> messages and activity
    if (current.messagesOnlyNotifications && !target.messagesOnlyNotifications) {
      return true;
    }

    return false;
  }

  /// Returns a human-readable list of specific restrictions being loosened.
  static List<String> describeLooseningChanges({
    required FeaturePreferences current,
    required FeaturePreferences target,
  }) {
    final changes = <String>[];

    if (!current.reelsFromDmsEnabled && target.reelsFromDmsEnabled) {
      changes.add('Enabling reels from DMs');
    } else if (current.reelsFromDmsEnabled && target.reelsFromDmsEnabled) {
      if (current.dailyReelLimit != null && target.dailyReelLimit == null) {
        changes.add('Removing daily reel limit (unlimited)');
      } else if (current.dailyReelLimit != null &&
          target.dailyReelLimit != null &&
          target.dailyReelLimit! > current.dailyReelLimit!) {
        changes.add('Increasing daily reel limit from ${current.dailyReelLimit} to ${target.dailyReelLimit}');
      }
    }

    if (current.storiesViewMode == StoriesViewMode.off &&
        target.storiesViewMode != StoriesViewMode.off) {
      changes.add('Enabling stories (${target.storiesViewMode.label})');
    } else if (current.storiesViewMode == StoriesViewMode.fromDmsOnly &&
        target.storiesViewMode == StoriesViewMode.fromFollowing) {
      changes.add('Enabling stories from Following');
    }

    if (current.storiesViewMode != StoriesViewMode.off &&
        target.storiesViewMode != StoriesViewMode.off) {
      if (current.dailyStoryLimit != null && target.dailyStoryLimit == null) {
        changes.add('Removing daily story limit (unlimited)');
      } else if (current.dailyStoryLimit != null &&
          target.dailyStoryLimit != null &&
          target.dailyStoryLimit! > current.dailyStoryLimit!) {
        changes.add('Increasing daily story limit from ${current.dailyStoryLimit} to ${target.dailyStoryLimit}');
      }
    }

    if (!current.storiesPostingEnabled && target.storiesPostingEnabled) {
      changes.add('Enabling external story posting');
    }

    if (!current.sharedPostsFromDmsEnabled && target.sharedPostsFromDmsEnabled) {
      changes.add('Enabling shared feed posts in DMs');
    }

    if (current.messagesOnlyNotifications && !target.messagesOnlyNotifications) {
      changes.add('Enabling activity notifications (likes/comments/follows)');
    }

    return changes;
  }
}
