/// View mode setting for Instagram Stories.
enum StoriesViewMode {
  off('Off'),
  fromDmsOnly('From DMs Only'),
  fromFollowing('From Following');

  const StoriesViewMode(this.label);
  final String label;

  static StoriesViewMode fromString(String? value) {
    switch (value) {
      case 'fromDmsOnly':
        return StoriesViewMode.fromDmsOnly;
      case 'fromFollowing':
        return StoriesViewMode.fromFollowing;
      case 'off':
      default:
        return StoriesViewMode.off;
    }
  }
}

/// Mindful content preferences governing optional media viewing, budgets,
/// notification filtering, and friction delays.
///
/// Kept strictly on-device in Drift SQLite.
class FeaturePreferences {
  const FeaturePreferences({
    this.reelsFromDmsEnabled = true,
    this.dailyReelLimit = 3,
    this.storiesViewMode = StoriesViewMode.off,
    this.storiesPostingEnabled = false,
    this.sharedPostsFromDmsEnabled = true,
    this.dailyStoryLimit = 10,
    this.messagesOnlyNotifications = false,
    this.delayLoosening24h = false,
    this.hasChosenFeatures = false,
    this.pendingLooseningJson,
    this.pendingLooseningReleaseTime,
  });

  /// Preset: Maximum restriction.
  /// Reels off, Stories off, Posting off, Shared posts off, Messages-only notifications.
  static const FeaturePreferences strict = FeaturePreferences(
    reelsFromDmsEnabled: false,
    dailyReelLimit: null,
    storiesViewMode: StoriesViewMode.off,
    storiesPostingEnabled: false,
    sharedPostsFromDmsEnabled: false,
    dailyStoryLimit: null,
    messagesOnlyNotifications: true,
    hasChosenFeatures: true,
  );

  /// Preset: Mindful balance.
  /// Reels on with a budget of 3, Stories from DMs only, Posting off, Shared posts on, Messages-only notifications.
  static const FeaturePreferences balanced = FeaturePreferences(
    reelsFromDmsEnabled: true,
    dailyReelLimit: 3,
    storiesViewMode: StoriesViewMode.fromDmsOnly,
    storiesPostingEnabled: false,
    sharedPostsFromDmsEnabled: true,
    dailyStoryLimit: 10,
    messagesOnlyNotifications: false,
    hasChosenFeatures: true,
  );

  /// Default configuration for existing installs upgrading to the feature selector.
  /// Reels on, Stories off, Posting off, Shared posts on, Messages-only notifications.
  static const FeaturePreferences oldDefault = FeaturePreferences(
    reelsFromDmsEnabled: true,
    dailyReelLimit: 3,
    storiesViewMode: StoriesViewMode.off,
    storiesPostingEnabled: false,
    sharedPostsFromDmsEnabled: true,
    dailyStoryLimit: 10,
    messagesOnlyNotifications: false,
    hasChosenFeatures: true,
  );

  /// Whether single reels sent in Direct Messages can be opened.
  final bool reelsFromDmsEnabled;

  /// Daily quota for viewing reels from DMs. If `null`, unlimited.
  final int? dailyReelLimit;

  /// Mode for viewing Stories: [StoriesViewMode.off], [StoriesViewMode.fromDmsOnly], or [StoriesViewMode.fromFollowing].
  final StoriesViewMode storiesViewMode;

  /// Whether story posting/creation entry points are enabled.
  final bool storiesPostingEnabled;

  /// Whether single shared feed posts (`/p/<id>/`) sent in DMs can be opened.
  final bool sharedPostsFromDmsEnabled;

  /// Daily quota for viewing stories. If `null`, unlimited.
  final int? dailyStoryLimit;

  /// Whether notification capture filters out activity (likes/follows/comments) and keeps only messages.
  final bool messagesOnlyNotifications;

  /// When true, any action that loosens mindful restrictions is delayed by 24 hours.
  final bool delayLoosening24h;

  /// Flag indicating whether the user has seen and completed the feature selector.
  final bool hasChosenFeatures;

  /// Serialized target preferences when a 24-hour loosening delay is active.
  final String? pendingLooseningJson;

  /// Timestamp when scheduled loosening becomes active.
  final DateTime? pendingLooseningReleaseTime;

  /// Convenient getter for whether stories are enabled in any mode.
  bool get areStoriesEnabled => storiesViewMode != StoriesViewMode.off;

  /// Convenient getter for whether the Following Stories tab is active.
  bool get areStoriesFromFollowingEnabled =>
      storiesViewMode == StoriesViewMode.fromFollowing;

  /// Whether there is a pending delayed loosening currently waiting for release.
  bool get hasPendingLoosening =>
      pendingLooseningReleaseTime != null && pendingLooseningJson != null;

  FeaturePreferences copyWith({
    bool? reelsFromDmsEnabled,
    int? dailyReelLimit,
    bool clearDailyReelLimit = false,
    StoriesViewMode? storiesViewMode,
    bool? storiesPostingEnabled,
    bool? sharedPostsFromDmsEnabled,
    int? dailyStoryLimit,
    bool clearDailyStoryLimit = false,
    bool? messagesOnlyNotifications,
    bool? delayLoosening24h,
    bool? hasChosenFeatures,
    String? pendingLooseningJson,
    bool clearPendingLooseningJson = false,
    DateTime? pendingLooseningReleaseTime,
    bool clearPendingLooseningReleaseTime = false,
  }) {
    return FeaturePreferences(
      reelsFromDmsEnabled: reelsFromDmsEnabled ?? this.reelsFromDmsEnabled,
      dailyReelLimit: clearDailyReelLimit
          ? null
          : (dailyReelLimit ?? this.dailyReelLimit),
      storiesViewMode: storiesViewMode ?? this.storiesViewMode,
      storiesPostingEnabled:
          storiesPostingEnabled ?? this.storiesPostingEnabled,
      sharedPostsFromDmsEnabled:
          sharedPostsFromDmsEnabled ?? this.sharedPostsFromDmsEnabled,
      dailyStoryLimit: clearDailyStoryLimit
          ? null
          : (dailyStoryLimit ?? this.dailyStoryLimit),
      messagesOnlyNotifications:
          messagesOnlyNotifications ?? this.messagesOnlyNotifications,
      delayLoosening24h: delayLoosening24h ?? this.delayLoosening24h,
      hasChosenFeatures: hasChosenFeatures ?? this.hasChosenFeatures,
      pendingLooseningJson: clearPendingLooseningJson
          ? null
          : (pendingLooseningJson ?? this.pendingLooseningJson),
      pendingLooseningReleaseTime: clearPendingLooseningReleaseTime
          ? null
          : (pendingLooseningReleaseTime ?? this.pendingLooseningReleaseTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reelsFromDmsEnabled': reelsFromDmsEnabled,
      'dailyReelLimit': dailyReelLimit,
      'storiesViewMode': storiesViewMode.name,
      'storiesPostingEnabled': storiesPostingEnabled,
      'sharedPostsFromDmsEnabled': sharedPostsFromDmsEnabled,
      'dailyStoryLimit': dailyStoryLimit,
      'messagesOnlyNotifications': messagesOnlyNotifications,
      'delayLoosening24h': delayLoosening24h,
      'hasChosenFeatures': hasChosenFeatures,
      'pendingLooseningJson': pendingLooseningJson,
      'pendingLooseningReleaseTime':
          pendingLooseningReleaseTime?.toIso8601String(),
    };
  }

  factory FeaturePreferences.fromJson(Map<String, dynamic> json) {
    return FeaturePreferences(
      reelsFromDmsEnabled: json['reelsFromDmsEnabled'] as bool? ?? true,
      dailyReelLimit: json.containsKey('dailyReelLimit')
          ? json['dailyReelLimit'] as int?
          : 3,
      storiesViewMode: StoriesViewMode.fromString(
        json['storiesViewMode'] as String?,
      ),
      storiesPostingEnabled: json['storiesPostingEnabled'] as bool? ?? false,
      sharedPostsFromDmsEnabled:
          json['sharedPostsFromDmsEnabled'] as bool? ?? true,
      dailyStoryLimit: json.containsKey('dailyStoryLimit')
          ? json['dailyStoryLimit'] as int?
          : 10,
      messagesOnlyNotifications:
          json['messagesOnlyNotifications'] as bool? ?? false,
      delayLoosening24h: json['delayLoosening24h'] as bool? ?? false,
      hasChosenFeatures: json['hasChosenFeatures'] as bool? ?? false,
      pendingLooseningJson: json['pendingLooseningJson'] as String?,
      pendingLooseningReleaseTime: json['pendingLooseningReleaseTime'] != null
          ? DateTime.tryParse(json['pendingLooseningReleaseTime'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeaturePreferences &&
          runtimeType == other.runtimeType &&
          reelsFromDmsEnabled == other.reelsFromDmsEnabled &&
          dailyReelLimit == other.dailyReelLimit &&
          storiesViewMode == other.storiesViewMode &&
          storiesPostingEnabled == other.storiesPostingEnabled &&
          sharedPostsFromDmsEnabled == other.sharedPostsFromDmsEnabled &&
          dailyStoryLimit == other.dailyStoryLimit &&
          messagesOnlyNotifications == other.messagesOnlyNotifications &&
          delayLoosening24h == other.delayLoosening24h &&
          hasChosenFeatures == other.hasChosenFeatures &&
          pendingLooseningJson == other.pendingLooseningJson &&
          pendingLooseningReleaseTime == other.pendingLooseningReleaseTime;

  @override
  int get hashCode => Object.hash(
        reelsFromDmsEnabled,
        dailyReelLimit,
        storiesViewMode,
        storiesPostingEnabled,
        sharedPostsFromDmsEnabled,
        dailyStoryLimit,
        messagesOnlyNotifications,
        delayLoosening24h,
        hasChosenFeatures,
        pendingLooseningJson,
        pendingLooseningReleaseTime,
      );
}
