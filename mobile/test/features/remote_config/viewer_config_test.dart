import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';

void main() {
  group('ViewerConfig & RouteConfig Viewer Mode', () {
    const config = RouteConfig(
      version: 1,
      userAgent: 'Mozilla/5.0 Test',
      fallbackPath: '/direct/inbox/',
      allowedPaths: [
        r'^/direct/',
        r'^/reel/[^/]+/?$',
        r'^/reels/[^/]+/?$',
        r'^/p/[^/]+/?$',
      ],
      alwaysBlockedPaths: [r'^/$', r'^/explore'],
      hideSelectors: ["a[href='/']"],
      viewerConfig: ViewerConfig(
        enabled: true,
        pathPatterns: [
          r'^/reel/[^/]+/?$',
          r'^/reels/[^/]+/?$',
          r'^/p/[^/]+/?$',
        ],
        hideSelectors: ["a[href*='/comments/']", "button[aria-label*='Next']"],
        scrollContainerSelectors: ["main", "[role='main']"],
        lockScroll: true,
        preventScrollKeys: true,
        blockNextReel: true,
        disableVideoLoop: true,
        lastReelMessage: "That's the last one.",
      ),
    );

    test('identifies single reel viewer paths correctly', () {
      expect(config.isViewerPath('/reel/C4xX9yZ/'), isTrue);
      expect(config.isViewerPath('/reel/C4xX9yZ'), isTrue);
      expect(config.isViewerPath('/reel/123456789/'), isTrue);
      expect(config.isViewerPath('/reels/C4xX9yZ/'), isTrue);
      expect(config.isViewerPath('/p/C4xX9yZ/'), isTrue);
      expect(
        config.isViewerPath('/reel/C4xX9yZ/?utm_source=ig_web_copy_link'),
        isTrue,
      );
    });

    test('rejects non-viewer paths', () {
      expect(config.isViewerPath('/direct/inbox/'), isFalse);
      expect(config.isViewerPath('/direct/t/12345/'), isFalse);
      expect(config.isViewerPath('/explore'), isFalse);
      expect(config.isViewerPath('/'), isFalse);
      expect(config.isViewerPath('/accounts/activity/'), isFalse);
      expect(config.isViewerPath('/reel/'), isFalse); // Root reels is not single item
      expect(config.isViewerPath('/reels/'), isFalse);
    });

    test('serializes and deserializes ViewerConfig correctly', () {
      final jsonMap = config.toJson();
      expect(jsonMap['viewerConfig'], isNotNull);

      final reconstructed = RouteConfig.fromJson(jsonMap);
      expect(reconstructed.viewerConfig.enabled, isTrue);
      expect(reconstructed.viewerConfig.lockScroll, isTrue);
      expect(reconstructed.viewerConfig.blockNextReel, isTrue);
      expect(reconstructed.viewerConfig.disableVideoLoop, isTrue);
      expect(
        reconstructed.viewerConfig.lastReelMessage,
        "That's the last one.",
      );
      expect(
        reconstructed.viewerConfig.hideSelectors,
        contains("a[href*='/comments/']"),
      );
      expect(
        reconstructed.viewerConfig.scrollContainerSelectors,
        contains("main"),
      );
    });

    test('disabled viewer config returns false for viewer paths', () {
      final disabledConfig = RouteConfig(
        version: 1,
        userAgent: 'test',
        fallbackPath: '/direct/inbox/',
        allowedPaths: [r'^/reel/[^/]+/?$'],
        alwaysBlockedPaths: [],
        hideSelectors: [],
        viewerConfig: const ViewerConfig(enabled: false),
      );
      expect(disabledConfig.isViewerPath('/reel/C4xX9yZ/'), isFalse);
    });
  });
}
