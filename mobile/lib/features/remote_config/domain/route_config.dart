import 'dart:convert';
import '../../settings/domain/feature_preferences.dart';
import 'css_sanitizer.dart';
import 'kill_switch_config.dart';

/// Configuration for a single feature group (e.g. dms, activity, reels, stories).
class FeatureGroupConfig {
  const FeatureGroupConfig({
    this.allowedPaths = const [],
    this.blockedPaths = const [],
    this.hideSelectors = const [],
  });

  final List<String> allowedPaths;
  final List<String> blockedPaths;
  final List<String> hideSelectors;

  factory FeatureGroupConfig.fromJson(Map<String, dynamic> json) {
    return FeatureGroupConfig(
      allowedPaths:
          List<String>.from(json['allowedPaths'] as List? ?? const []),
      blockedPaths:
          List<String>.from(json['blockedPaths'] as List? ?? const []),
      hideSelectors:
          List<String>.from(json['hideSelectors'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toJson() => {
        'allowedPaths': allowedPaths,
        'blockedPaths': blockedPaths,
        'hideSelectors': hideSelectors,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeatureGroupConfig &&
          runtimeType == other.runtimeType &&
          _listEquals(allowedPaths, other.allowedPaths) &&
          _listEquals(blockedPaths, other.blockedPaths) &&
          _listEquals(hideSelectors, other.hideSelectors);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(allowedPaths),
        Object.hashAll(blockedPaths),
        Object.hashAll(hideSelectors),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Configuration for single item viewer mode (isolated reel/post/story playback).
class ViewerConfig {
  const ViewerConfig({
    this.enabled = true,
    this.pathPatterns = const [
      r'^/reel/[^/]+/?$',
      r'^/reels/[^/]+/?$',
      r'^/p/[^/]+/?$',
      r'^/stories/[^/]+/[^/]+/?$',
      r'^/stories/[^/]+/?$',
    ],
    this.hideSelectors = const [
      "a[href*='/comments/']",
      "div[aria-label*='Comments']",
      "button[aria-label*='Next']",
      "div[aria-label*='Next']",
      "a[aria-label*='Next']",
      "div[aria-label*='Suggested']",
      "div:has(> *[aria-label*='More from'])",
      "div[aria-label*='More reels']",
      "div[aria-label*='More posts']",
      "header a[role='link']",
      "a[role='link']:has(img[alt*='profile'])",
      "div[aria-label*='More options']",
      "button[aria-label*='More options']",
    ],
    this.scrollContainerSelectors = const [
      "main",
      "[role='main']",
      "article",
      "div[data-pressable-container='true']",
    ],
    this.lockScroll = true,
    this.preventScrollKeys = true,
    this.blockNextReel = true,
    this.disableVideoLoop = true,
    this.lastReelMessage = "That's the last one.",
  });

  final bool enabled;
  final List<String> pathPatterns;
  final List<String> hideSelectors;
  final List<String> scrollContainerSelectors;
  final bool lockScroll;
  final bool preventScrollKeys;
  final bool blockNextReel;
  final bool disableVideoLoop;
  final String lastReelMessage;

  factory ViewerConfig.fromJson(Map<String, dynamic> json) {
    return ViewerConfig(
      enabled: json['enabled'] as bool? ?? true,
      pathPatterns: List<String>.from(
        json['pathPatterns'] as List? ??
            [
              r'^/reel/[^/]+/?$',
              r'^/reels/[^/]+/?$',
              r'^/p/[^/]+/?$',
              r'^/stories/[^/]+/[^/]+/?$',
              r'^/stories/[^/]+/?$',
            ],
      ),
      hideSelectors: List<String>.from(
        json['hideSelectors'] as List? ??
            [
              "a[href*='/comments/']",
              "div[aria-label*='Comments']",
              "button[aria-label*='Next']",
              "div[aria-label*='Next']",
              "a[aria-label*='Next']",
              "div[aria-label*='Suggested']",
              "div:has(> *[aria-label*='More from'])",
              "div[aria-label*='More reels']",
              "div[aria-label*='More posts']",
              "header a[role='link']",
              "a[role='link']:has(img[alt*='profile'])",
              "div[aria-label*='More options']",
              "button[aria-label*='More options']",
            ],
      ),
      scrollContainerSelectors: List<String>.from(
        json['scrollContainerSelectors'] as List? ??
            [
              "main",
              "[role='main']",
              "article",
              "div[data-pressable-container='true']",
            ],
      ),
      lockScroll: json['lockScroll'] as bool? ?? true,
      preventScrollKeys: json['preventScrollKeys'] as bool? ?? true,
      blockNextReel: json['blockNextReel'] as bool? ?? true,
      disableVideoLoop: json['disableVideoLoop'] as bool? ?? true,
      lastReelMessage:
          json['lastReelMessage'] as String? ?? "That's the last one.",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'pathPatterns': pathPatterns,
      'hideSelectors': hideSelectors,
      'scrollContainerSelectors': scrollContainerSelectors,
      'lockScroll': lockScroll,
      'preventScrollKeys': preventScrollKeys,
      'blockNextReel': blockNextReel,
      'disableVideoLoop': disableVideoLoop,
      'lastReelMessage': lastReelMessage,
    };
  }

  ViewerConfig copyWith({
    bool? enabled,
    List<String>? pathPatterns,
    List<String>? hideSelectors,
    List<String>? scrollContainerSelectors,
    bool? lockScroll,
    bool? preventScrollKeys,
    bool? blockNextReel,
    bool? disableVideoLoop,
    String? lastReelMessage,
  }) {
    return ViewerConfig(
      enabled: enabled ?? this.enabled,
      pathPatterns: pathPatterns ?? this.pathPatterns,
      hideSelectors: hideSelectors ?? this.hideSelectors,
      scrollContainerSelectors:
          scrollContainerSelectors ?? this.scrollContainerSelectors,
      lockScroll: lockScroll ?? this.lockScroll,
      preventScrollKeys: preventScrollKeys ?? this.preventScrollKeys,
      blockNextReel: blockNextReel ?? this.blockNextReel,
      disableVideoLoop: disableVideoLoop ?? this.disableVideoLoop,
      lastReelMessage: lastReelMessage ?? this.lastReelMessage,
    );
  }
}

/// Single authoritative configuration model driving the 3-layer ZeroScroll route guard.
class RouteConfig {
  const RouteConfig({
    required this.version,
    required this.userAgent,
    required this.fallbackPath,
    required this.allowedPaths,
    required this.alwaysBlockedPaths,
    required this.hideSelectors,
    String? extraCss,
    String? customCss,
    this.externalAllowedHosts = const [
      'instagram.com',
      'facebook.com',
      'meta.com',
      'fbcdn.net',
    ],
    ViewerConfig? viewerModeRules,
    ViewerConfig? viewerConfig,
    this.minAppVersion,
    this.killSwitch = const KillSwitchConfig(),
    this.featureGroups = const {},
  })  : extraCss = extraCss ?? customCss ?? '',
        viewerModeRules =
            viewerModeRules ?? viewerConfig ?? const ViewerConfig();

  final int version;
  final String? minAppVersion;
  final KillSwitchConfig killSwitch;
  final String userAgent;
  final String fallbackPath;
  final List<String> allowedPaths;
  final List<String> alwaysBlockedPaths;
  final List<String> hideSelectors;
  final String extraCss;
  final List<String> externalAllowedHosts;
  final ViewerConfig viewerModeRules;
  final Map<String, FeatureGroupConfig> featureGroups;

  /// Backward-compatible alias for [extraCss].
  String get customCss => extraCss;

  /// Backward-compatible alias for [viewerModeRules].
  ViewerConfig get viewerConfig => viewerModeRules;

  /// Validates whether a given URL path is permitted under the guard rules.
  ///
  /// Priority:
  /// 1. If [path] matches any pattern in [alwaysBlockedPaths], it is strictly rejected.
  /// 2. If [path] matches any pattern in [allowedPaths], it is approved.
  /// 3. Default deny: any other path (such as profiles or discovery) is rejected.
  /// Pages that must always be reachable, whatever an old cached/remote config says.
  static final List<RegExp> _coreAllowed = [
    RegExp(r'^/notifications(/|$)'),
    RegExp(r'^/accounts/activity(/|$)'),
  ];

  bool isPathAllowed(String path) {
    final clean = _normalizePath(path);

    // 0. Core Activity pages are always allowed
    for (final core in _coreAllowed) {
      if (core.hasMatch(clean)) return true;
    }

    // 1. Check always blocked paths first
    for (final pattern in alwaysBlockedPaths) {
      try {
        final regex = RegExp(pattern);
        if (regex.hasMatch(clean)) {
          return false;
        }
      } catch (_) {
        // Continue if an individual regex is malformed
      }
    }

    // 2. Check allowed paths
    for (final pattern in allowedPaths) {
      try {
        final regex = RegExp(pattern);
        if (regex.hasMatch(clean)) {
          return true;
        }
      } catch (_) {
        // Continue if an individual regex is malformed
      }
    }

    // 3. Default deny
    return false;
  }

  /// Checks whether a given host is permitted to load inside the WebView.
  bool isHostAllowed(String host) {
    final lowerHost = host.toLowerCase();
    for (final allowed in externalAllowedHosts) {
      if (lowerHost == allowed || lowerHost.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  /// Checks whether a given path is an isolated single item viewer path.
  bool isViewerPath(String path) {
    if (!viewerModeRules.enabled) return false;
    final clean = _normalizePath(path);
    for (final pattern in viewerModeRules.pathPatterns) {
      try {
        if (RegExp(pattern).hasMatch(clean)) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Checks whether a given path is a Story path (`/stories/<username>/...`).
  bool isStoryPath(String path) {
    final clean = _normalizePath(path);
    return clean.startsWith('/stories/');
  }

  /// Creates default feature groups for standard ZeroScroll features.
  static Map<String, FeatureGroupConfig> createDefaultFeatureGroups() {
    return const {
      'dms': FeatureGroupConfig(
        allowedPaths: [
          r'^/direct/',
          r'^/accounts/login',
          r'^/accounts/onetap',
          r'^/challenge/',
          r'^/two_factor/',
          r'^/accounts/suspended',
        ],
        blockedPaths: [],
        hideSelectors: [],
      ),
      'activity': FeatureGroupConfig(
        allowedPaths: [
          r'^/accounts/activity',
        ],
        blockedPaths: [],
        hideSelectors: [],
      ),
      'reels': FeatureGroupConfig(
        allowedPaths: [
          r'^/reel/[^/]+/?$',
          r'^/reels/[^/]+/?$',
        ],
        blockedPaths: [
          r'^/reels/?$',
        ],
        hideSelectors: [
          "a[href^='/reels']",
          "a[aria-label='Reels']",
          "div[role='tablist'] a[href^='/reels']",
        ],
      ),
      'storiesView': FeatureGroupConfig(
        allowedPaths: [
          r'^/stories/(?!create/)[^/]+/[^/]+/?$',
          r'^/stories/(?!create/?$)[^/]+/?$',
        ],
        blockedPaths: [
          r'^/stories/?$',
        ],
        hideSelectors: [],
      ),
      'storiesFromFollowing': FeatureGroupConfig(
        allowedPaths: [
          r'^/$',
        ],
        blockedPaths: [],
        hideSelectors: [
          "section[aria-label='Stories']",
          "div[aria-label*='Stories']",
          "div[data-testid='story-tray']",
        ],
      ),
      'storiesCreate': FeatureGroupConfig(
        allowedPaths: [
          r'^/stories/create/?$',
          r'^/create/story/?$',
        ],
        blockedPaths: [],
        hideSelectors: [
          "a[href*='/create/story']",
          "button[aria-label*='Create Story']",
          "div[aria-label*='Create Story']",
          "div[aria-label*='Your story']",
        ],
      ),
      'sharedPosts': FeatureGroupConfig(
        allowedPaths: [
          r'^/p/[^/]+/?$',
        ],
        blockedPaths: [],
        hideSelectors: [],
      ),
    };
  }

  /// Computes the effective [RouteConfig] based on the user's [FeaturePreferences].
  ///
  /// Always-on groups (dms, activity) plus enabled optional groups contribute to allowed paths.
  /// Disabled groups' paths go to blockedPaths, and their hideSelectors go to hideSelectors.
  RouteConfig computeEffectiveConfig(FeaturePreferences prefs) {
    final groups = featureGroups.isNotEmpty
        ? featureGroups
        : createDefaultFeatureGroups();

    final effectiveAllowed = <String>[...allowedPaths];
    final effectiveBlocked = <String>[...alwaysBlockedPaths];
    final effectiveHide = <String>[...hideSelectors];

    final isGroupEnabled = <String, bool>{
      'dms': true,
      'activity': true,
      'reels': prefs.reelsFromDmsEnabled,
      'storiesView': prefs.storiesViewMode != StoriesViewMode.off,
      'storiesFromFollowing':
          prefs.storiesViewMode == StoriesViewMode.fromFollowing,
      'storiesCreate': prefs.storiesPostingEnabled,
      'sharedPosts': prefs.sharedPostsFromDmsEnabled,
    };

    for (final entry in groups.entries) {
      final name = entry.key;
      final group = entry.value;
      final enabled = isGroupEnabled[name] ?? true;

      if (enabled) {
        effectiveAllowed.addAll(group.allowedPaths);
        effectiveBlocked.addAll(group.blockedPaths);
        // Reels tab navigation icons are always hidden even when single reel playback is enabled
        if (name == 'dms' || name == 'activity' || name == 'reels') {
          effectiveHide.addAll(group.hideSelectors);
        }
      } else {
        effectiveBlocked.addAll(group.allowedPaths);
        effectiveBlocked.addAll(group.blockedPaths);
        effectiveHide.addAll(group.hideSelectors);
      }
    }

    // Filter viewerModeRules path patterns based on enabled media features
    final currentViewer = viewerModeRules;
    final activeViewerPatterns = currentViewer.pathPatterns.where((pattern) {
      if (pattern.contains('/reel')) {
        return prefs.reelsFromDmsEnabled;
      }
      if (pattern.contains('/stories')) {
        return prefs.storiesViewMode != StoriesViewMode.off;
      }
      if (pattern.contains('/p/')) {
        return prefs.sharedPostsFromDmsEnabled;
      }
      return true;
    }).toList();

    // When reels are off, add selectors to hide reel previews & play icons in DM threads
    if (!prefs.reelsFromDmsEnabled) {
      effectiveHide.addAll([
        "a[href*='/reel/'] img",
        "a[href*='/reels/'] img",
        "a[href*='/reel/'] svg",
        "a[href*='/reels/'] svg",
        "a[href*='/reel/'] video",
        "a[href*='/reels/'] video",
      ]);
    }

    return copyWith(
      allowedPaths: effectiveAllowed.toSet().toList(),
      alwaysBlockedPaths: effectiveBlocked.toSet().toList(),
      hideSelectors: effectiveHide.toSet().toList(),
      viewerModeRules: currentViewer.copyWith(
        pathPatterns: activeViewerPatterns,
      ),
    );
  }

  RouteConfig copyWith({
    int? version,
    String? minAppVersion,
    KillSwitchConfig? killSwitch,
    String? userAgent,
    String? fallbackPath,
    List<String>? allowedPaths,
    List<String>? alwaysBlockedPaths,
    List<String>? hideSelectors,
    String? extraCss,
    List<String>? externalAllowedHosts,
    ViewerConfig? viewerModeRules,
    Map<String, FeatureGroupConfig>? featureGroups,
  }) {
    return RouteConfig(
      version: version ?? this.version,
      minAppVersion: minAppVersion ?? this.minAppVersion,
      killSwitch: killSwitch ?? this.killSwitch,
      userAgent: userAgent ?? this.userAgent,
      fallbackPath: fallbackPath ?? this.fallbackPath,
      allowedPaths: allowedPaths ?? this.allowedPaths,
      alwaysBlockedPaths: alwaysBlockedPaths ?? this.alwaysBlockedPaths,
      hideSelectors: hideSelectors ?? this.hideSelectors,
      extraCss: extraCss ?? this.extraCss,
      externalAllowedHosts:
          externalAllowedHosts ?? this.externalAllowedHosts,
      viewerModeRules: viewerModeRules ?? this.viewerModeRules,
      featureGroups: featureGroups ?? this.featureGroups,
    );
  }

  /// Normalizes incoming path by stripping query parameters and trailing anchors.
  static String _normalizePath(String rawPath) {
    var p = rawPath.trim();
    if (p.isEmpty) return '/';

    // Strip query parameters and fragment
    final queryIndex = p.indexOf('?');
    if (queryIndex != -1) {
      p = p.substring(0, queryIndex);
    }
    final hashIndex = p.indexOf('#');
    if (hashIndex != -1) {
      p = p.substring(0, hashIndex);
    }

    if (!p.startsWith('/')) {
      p = '/$p';
    }
    return p;
  }

  factory RouteConfig.fromJson(Map<String, dynamic> json) {
    // Read and sanitize CSS
    final rawCss = (json['extraCss'] as String?) ??
        (json['customCss'] as String?) ??
        '';
    final sanitizedCss = CssSanitizer.sanitizeCss(rawCss);

    // Read and sanitize hide selectors
    final rawSelectors =
        List<String>.from(json['hideSelectors'] as List? ?? []);
    final sanitizedSelectors = CssSanitizer.sanitizeSelectors(rawSelectors);

    // Read viewer mode rules
    final viewerRaw = (json['viewerModeRules'] as Map<String, dynamic>?) ??
        (json['viewerConfig'] as Map<String, dynamic>?);

    // Read feature groups if present
    final rawFeatureGroups = json['featureGroups'] as Map<String, dynamic>?;
    final parsedFeatureGroups = <String, FeatureGroupConfig>{};
    if (rawFeatureGroups != null) {
      for (final entry in rawFeatureGroups.entries) {
        if (entry.value is Map<String, dynamic>) {
          parsedFeatureGroups[entry.key] =
              FeatureGroupConfig.fromJson(entry.value as Map<String, dynamic>);
        }
      }
    }

    return RouteConfig(
      version: json['version'] as int? ?? 1,
      minAppVersion: json['minAppVersion'] as String?,
      killSwitch: KillSwitchConfig.fromJson(
        json['killSwitch'] as Map<String, dynamic>?,
      ),
      userAgent: json['userAgent'] as String? ?? '',
      fallbackPath: json['fallbackPath'] as String? ?? '/direct/inbox/',
      allowedPaths: List<String>.from(json['allowedPaths'] as List? ?? []),
      alwaysBlockedPaths: List<String>.from(
        json['alwaysBlockedPaths'] as List? ?? [],
      ),
      hideSelectors: sanitizedSelectors,
      extraCss: sanitizedCss,
      externalAllowedHosts: json['externalAllowedHosts'] != null
          ? List<String>.from(json['externalAllowedHosts'] as List)
          : const ['instagram.com', 'facebook.com', 'meta.com', 'fbcdn.net'],
      viewerModeRules: viewerRaw != null
          ? ViewerConfig.fromJson(viewerRaw)
          : const ViewerConfig(),
      featureGroups: parsedFeatureGroups.isNotEmpty
          ? parsedFeatureGroups
          : createDefaultFeatureGroups(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (minAppVersion != null) 'minAppVersion': minAppVersion,
      'killSwitch': killSwitch.toJson(),
      'userAgent': userAgent,
      'fallbackPath': fallbackPath,
      'allowedPaths': allowedPaths,
      'alwaysBlockedPaths': alwaysBlockedPaths,
      'hideSelectors': hideSelectors,
      'extraCss': extraCss,
      'customCss': extraCss, // Kept for backward compatibility
      'externalAllowedHosts': externalAllowedHosts,
      'viewerModeRules': viewerModeRules.toJson(),
      'viewerConfig': viewerModeRules.toJson(), // Kept for backward compatibility
      if (featureGroups.isNotEmpty)
        'featureGroups': {
          for (final entry in featureGroups.entries)
            entry.key: entry.value.toJson(),
        },
    };
  }

  /// Generates a JSON string suitable for injecting into JavaScript.
  String toJsonString() => jsonEncode(toJson());
}
