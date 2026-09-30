import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';

void main() {
  group('RouteConfig Path Guard Matching Table', () {
    late RouteConfig config;

    setUp(() {
      const defaultJson = '''
      {
        "version": 1,
        "userAgent": "Mozilla/5.0 Test",
        "fallbackPath": "/direct/inbox/",
        "allowedPaths": [
          "^/direct/",
          "^/accounts/login",
          "^/accounts/activity",
          "^/accounts/onetap",
          "^/challenge/",
          "^/two_factor/",
          "^/accounts/suspended",
          "^/reel/[^/]+/?\$",
          "^/reels/[^/]+/?\$",
          "^/p/[^/]+/?\$"
        ],
        "alwaysBlockedPaths": [
          "^/\$",
          "^/explore",
          "^/reels/?\$",
          "^/stories/",
          "^/accounts/edit",
          "^/(?!direct|accounts|challenge|two_factor|reel|reels|p|legal|static)[a-zA-Z0-9._]+/?\$"
        ],
        "hideSelectors": [
          "a[href='/']",
          "a[href^='/explore']"
        ]
      }
      ''';

      config = RouteConfig.fromJson(
        jsonDecode(defaultJson) as Map<String, dynamic>,
      );
    });

    final allowedTestCases = <String, String>{
      'Direct inbox with trailing slash': '/direct/inbox/',
      'Direct inbox without trailing slash': '/direct/inbox',
      'Direct conversation thread': '/direct/t/17841400000000000/',
      'Direct conversation without trailing slash':
          '/direct/t/17841400000000000',
      'Accounts login route': '/accounts/login/',
      'Accounts login with query parameters':
          '/accounts/login?next=/direct/inbox/',
      'Accounts activity / notifications': '/accounts/activity/',
      'Accounts one-tap login': '/accounts/onetap/',
      'Security challenge checkpoint': '/challenge/',
      'Specific checkpoint challenge ID': '/challenge/123456789/',
      'Two factor authentication': '/two_factor/',
      'Suspended account notice': '/accounts/suspended/',
      'Single reel viewer with ID': '/reel/C4xX9yZ/',
      'Single reel viewer without trailing slash': '/reel/C4xX9yZ',
      'Single reel with query parameters':
          '/reel/C4xX9yZ/?utm_source=ig_web_copy_link',
      'Single reels plural path with ID': '/reels/C4xX9yZ/',
      'Single post viewer with ID': '/p/C987654321/',
      'Single post with media index query': '/p/C987654321/?img_index=1',
    };

    for (final entry in allowedTestCases.entries) {
      test('ALLOWED: ${entry.key} ("${entry.value}")', () {
        expect(
          config.isPathAllowed(entry.value),
          isTrue,
          reason: 'Expected "${entry.value}" to be permitted by RouteConfig.',
        );
      });
    }

    final blockedTestCases = <String, String>{
      'Home algorithmic feed': '/',
      'Explore root': '/explore',
      'Explore with trailing slash': '/explore/',
      'Explore tag search': '/explore/tags/flutter/',
      'Explore search query': '/explore/search/?q=news',
      'Reels discovery tab without trailing slash': '/reels',
      'Reels discovery tab with trailing slash': '/reels/',
      'Stories tray root': '/stories/',
      'Stories user viewer': '/stories/cristiano/1234567890/',
      'Accounts profile edit': '/accounts/edit/',
      'Accounts edit without trailing slash': '/accounts/edit',
      'Celebrity user profile': '/cristiano/',
      'Tech leader user profile': '/zuck/',
      'Random user profile': '/elonmusk',
      'Platform account profile': '/instagram/',
    };

    for (final entry in blockedTestCases.entries) {
      test('BLOCKED: ${entry.key} ("${entry.value}")', () {
        expect(
          config.isPathAllowed(entry.value),
          isFalse,
          reason: 'Expected "${entry.value}" to be blocked by RouteConfig.',
        );
      });
    }

    group('Host Allowed Check', () {
      test('allows instagram.com and subdomains', () {
        expect(config.isHostAllowed('instagram.com'), isTrue);
        expect(config.isHostAllowed('www.instagram.com'), isTrue);
        expect(config.isHostAllowed('auth.instagram.com'), isTrue);
      });

      test('allows auth and CDN infrastructure hosts', () {
        expect(config.isHostAllowed('facebook.com'), isTrue);
        expect(config.isHostAllowed('www.facebook.com'), isTrue);
        expect(config.isHostAllowed('meta.com'), isTrue);
        expect(config.isHostAllowed('static.cdninstagram.com'), isFalse);
      });

      test('rejects external third-party hosts', () {
        expect(config.isHostAllowed('google.com'), isFalse);
        expect(config.isHostAllowed('tiktok.com'), isFalse);
        expect(config.isHostAllowed('malicious-site.com'), isFalse);
      });
    });

    test('toJsonString outputs valid non-empty JSON', () {
      final jsonStr = config.toJsonString();
      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], 1);
      expect(decoded['fallbackPath'], '/direct/inbox/');
    });
  });
}
