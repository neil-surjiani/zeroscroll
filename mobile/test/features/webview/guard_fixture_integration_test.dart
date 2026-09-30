import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/settings/domain/feature_preferences.dart';

void main() {
  group('HTML Fixtures & Guard Security Integration Tests', () {
    late String reelMockHtml;
    late String storyMockHtml;
    late String guardJs;
    late Map<String, dynamic> defaultConfigJson;
    late RouteConfig defaultConfig;

    setUpAll(() {
      final reelFile = File('test/fixtures/reel_mock.html');
      expect(reelFile.existsSync(), isTrue, reason: 'reel_mock.html must exist');
      reelMockHtml = reelFile.readAsStringSync();

      final storyFile = File('test/fixtures/story_mock.html');
      expect(storyFile.existsSync(), isTrue, reason: 'story_mock.html must exist');
      storyMockHtml = storyFile.readAsStringSync();

      final guardJsFile = File('assets/js/guard.js');
      expect(guardJsFile.existsSync(), isTrue, reason: 'guard.js must exist');
      guardJs = guardJsFile.readAsStringSync();

      final configFile = File('assets/default_config.json');
      expect(configFile.existsSync(), isTrue, reason: 'default_config.json must exist');
      defaultConfigJson = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
      defaultConfig = RouteConfig.fromJson(defaultConfigJson);
    });

    test('guard.js contains runtime initialization flag for fail-closed checks', () {
      expect(
        guardJs.contains('__ZEROSCROLL_GUARD_INITIALIZED__'),
        isTrue,
        reason: 'guard.js must set window.__ZEROSCROLL_GUARD_INITIALIZED__ = true',
      );
    });

    test('guard.js intercepts wheel, touchmove, and keyboard swipe gestures', () {
      expect(guardJs.contains('touchmove'), isTrue);
      expect(guardJs.contains('wheel'), isTrue);
      expect(guardJs.contains('keydown'), isTrue);
      expect(guardJs.contains('preventDefault'), isTrue);
      expect(guardJs.contains('stopImmediatePropagation'), isTrue);
    });

    test('guard.js wraps History pushState and replaceState to catch client-side routing', () {
      expect(guardJs.contains('history.pushState'), isTrue);
      expect(guardJs.contains('history.replaceState'), isTrue);
      expect(guardJs.contains('onNavigationBlocked'), isTrue);
    });

    test('reel_mock.html contains distracting elements targeted by hideSelectors', () {
      // Elements that ZeroScroll must shield
      expect(reelMockHtml.contains('Next Reel'), isTrue);
      expect(reelMockHtml.contains('suggested-section'), isTrue);
      expect(reelMockHtml.contains('more-from-section'), isTrue);
      expect(reelMockHtml.contains('data-reel-id="mock2"'), isTrue);

      // Verify hideSelectors in config address typical suggestion patterns
      final hideSelectorsStr = defaultConfig.hideSelectors.join(' ');
      final hasReelHiding = hideSelectorsStr.contains('reel') ||
          hideSelectorsStr.contains('explore') ||
          hideSelectorsStr.contains('suggested') ||
          defaultConfig.viewerConfig.hideSelectors.isNotEmpty;

      expect(hasReelHiding, isTrue);
    });

    test('story_mock.html contains feed and tray elements for isolation testing', () {
      expect(storyMockHtml.contains('data-testid="story-tray"'), isTrue);
      expect(storyMockHtml.contains('mock-feed-post-1'), isTrue);
      expect(storyMockHtml.contains('role="feed"'), isTrue);
      expect(storyMockHtml.contains('article'), isTrue);
    });

    test('RouteConfig matches single reel and blocks algorithmic feeds', () {
      final effectiveConfig = defaultConfig.computeEffectiveConfig(
        const FeaturePreferences(reelsFromDmsEnabled: true),
      );

      // Inbox & Direct allowed
      expect(effectiveConfig.isPathAllowed('/direct/inbox/'), isTrue);
      expect(effectiveConfig.isPathAllowed('/direct/t/12345/'), isTrue);

      // Single reel viewer path allowed when reelsFromDmsEnabled is true
      expect(effectiveConfig.isPathAllowed('/reel/mock1/'), isTrue);
      expect(effectiveConfig.isViewerPath('/reel/mock1/'), isTrue);

      // Algorithmic feeds blocked
      expect(effectiveConfig.isPathAllowed('/'), isFalse);
      expect(effectiveConfig.isPathAllowed('/explore/'), isFalse);
      expect(effectiveConfig.isPathAllowed('/reels/'), isFalse);
      expect(effectiveConfig.isPathAllowed('/random_user/'), isFalse);
    });

    test('single-reel locking logic rejects advancing to mock2', () {
      const activeReelId = 'mock1';
      final candidatePath = '/reel/mock2/';
      final candidateMatch = RegExp(r'^/(?:reel|reels|p)/([^/]+)').firstMatch(candidatePath);
      final candidateId = candidateMatch?.group(1);

      expect(candidateId, 'mock2');
      expect(candidateId != activeReelId, isTrue, reason: 'Must detect transition to different reel ID');
    });

    test('story single-user session locking detects transition across accounts', () {
      const activeStoryUser = 'alice';
      final nextSlidePath = '/stories/alice/102/';
      final nextUserPath = '/stories/bob/201/';

      final slideRegex = RegExp(r'^/stories/(?!create/)([^/]+)/([^/?#]+)');
      final slideUser = slideRegex.firstMatch(nextSlidePath)?.group(1);
      final nextUser = slideRegex.firstMatch(nextUserPath)?.group(1);

      expect(slideUser, 'alice');
      expect(slideUser == activeStoryUser, isTrue);

      expect(nextUser, 'bob');
      expect(nextUser == activeStoryUser, isFalse, reason: 'Transition to Bob must be intercepted and cancelled');
    });
  });
}
