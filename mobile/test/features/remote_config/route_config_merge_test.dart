import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/domain/remote_config_validator.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/settings/domain/feature_preferences.dart';

void main() {
  late RouteConfig baseConfig;

  setUpAll(() {
    final configFile = File('assets/default_config.json');
    final jsonString = configFile.readAsStringSync();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    baseConfig = RouteConfig.fromJson(jsonMap);
  });

  group('RouteConfig Feature Groups Schema & Validator', () {
    test('RemoteConfigValidator accepts valid default_config.json with featureGroups', () {
      final configFile = File('assets/default_config.json');
      final jsonString = configFile.readAsStringSync();

      final result = RemoteConfigValidator.validate(
        rawJson: jsonString,
        sourceUrl: 'https://config.zeroscroll.app/config.json',
      );

      expect(result.isValid, isTrue, reason: result.errorMessage);
    });

    test('RemoteConfigValidator rejects malformed regex inside a feature group', () {
      final invalidJson = jsonEncode({
        'version': 2,
        'userAgent': 'test',
        'fallbackPath': '/direct/inbox/',
        'featureGroups': {
          'reels': {
            'allowedPaths': ['[invalid regex('],
          },
        },
      });

      final result = RemoteConfigValidator.validate(
        rawJson: invalidJson,
        sourceUrl: 'https://config.zeroscroll.app/config.json',
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Invalid regex in feature group'));
    });
  });

  group('Table-Driven RouteConfig Merge (All 24 Combinations)', () {
    final boolValues = [true, false];
    final storiesModes = [
      StoriesViewMode.off,
      StoriesViewMode.fromDmsOnly,
      StoriesViewMode.fromFollowing,
    ];

    int combinationIndex = 0;

    for (final reelsEnabled in boolValues) {
      for (final storiesMode in storiesModes) {
        for (final postingEnabled in boolValues) {
          for (final sharedPostsEnabled in boolValues) {
            final testIndex = ++combinationIndex;
            final prefs = FeaturePreferences(
              reelsFromDmsEnabled: reelsEnabled,
              storiesViewMode: storiesMode,
              storiesPostingEnabled: postingEnabled,
              sharedPostsFromDmsEnabled: sharedPostsEnabled,
            );

            test(
              '#$testIndex: reels=$reelsEnabled, stories=$storiesMode, posting=$postingEnabled, sharedPosts=$sharedPostsEnabled',
              () {
                final effective = baseConfig.computeEffectiveConfig(prefs);

                // 1. ALWAYS ON / BASE PATHS
                expect(
                  effective.isPathAllowed('/direct/inbox/'),
                  isTrue,
                  reason: 'DMs inbox must always be allowed',
                );
                expect(
                  effective.isPathAllowed('/direct/t/12345/'),
                  isTrue,
                  reason: 'DM threads must always be allowed',
                );
                expect(
                  effective.isPathAllowed('/accounts/activity'),
                  isTrue,
                  reason: 'Activity must always be allowed',
                );
                expect(
                  effective.isPathAllowed('/accounts/login'),
                  isTrue,
                  reason: 'Login must always be allowed',
                );
                expect(
                  effective.isPathAllowed('/explore'),
                  isFalse,
                  reason: 'Explore must always be blocked',
                );
                expect(
                  effective.isPathAllowed('/accounts/edit'),
                  isFalse,
                  reason: 'Account editing must always be blocked',
                );
                expect(
                  effective.isPathAllowed('/reels'),
                  isFalse,
                  reason: 'Reels tab must always be blocked',
                );
                expect(
                  effective.isPathAllowed('/reels/'),
                  isFalse,
                  reason: 'Reels tab must always be blocked',
                );

                // 2. REELS FROM DMS
                if (reelsEnabled) {
                  expect(
                    effective.isPathAllowed('/reel/CxY123/'),
                    isTrue,
                    reason: 'Single reel should be allowed when reels enabled',
                  );
                  expect(
                    effective.isPathAllowed('/reels/CxY123/'),
                    isTrue,
                    reason: 'Single reel should be allowed when reels enabled',
                  );
                } else {
                  expect(
                    effective.isPathAllowed('/reel/CxY123/'),
                    isFalse,
                    reason: 'Single reel should be blocked when reels disabled',
                  );
                  expect(
                    effective.isPathAllowed('/reels/CxY123/'),
                    isFalse,
                    reason: 'Single reel should be blocked when reels disabled',
                  );
                  expect(
                    effective.viewerConfig.pathPatterns.any((p) => p.contains('reel')),
                    isFalse,
                    reason: 'Reels viewer rules must be removed when reels are disabled',
                  );
                  expect(
                    effective.hideSelectors,
                    contains("a[href*='/reel/'] img"),
                    reason: 'Reel link selectors must be hidden when reels are disabled',
                  );
                }

                // 3. SHARED POSTS FROM DMS
                if (sharedPostsEnabled) {
                  expect(
                    effective.isPathAllowed('/p/ABC123xyz/'),
                    isTrue,
                    reason: 'Single post should be allowed when sharedPosts enabled',
                  );
                } else {
                  expect(
                    effective.isPathAllowed('/p/ABC123xyz/'),
                    isFalse,
                    reason: 'Single post should be blocked when sharedPosts disabled',
                  );
                }

                // 4. STORIES VIEW MODE
                switch (storiesMode) {
                  case StoriesViewMode.off:
                    expect(
                      effective.isPathAllowed('/stories/johndoe/12345/'),
                      isFalse,
                      reason: 'Story URL should be blocked when stories are OFF',
                    );
                    expect(
                      effective.isPathAllowed('/'),
                      isFalse,
                      reason: 'Home path / should be blocked when stories are OFF',
                    );
                    expect(
                      effective.hideSelectors,
                      contains('section[aria-label=\'Stories\']'),
                      reason: 'Story tray must be hidden when stories are OFF',
                    );
                    break;

                  case StoriesViewMode.fromDmsOnly:
                    expect(
                      effective.isPathAllowed('/stories/johndoe/12345/'),
                      isTrue,
                      reason:
                          'Story URL path pattern should be permitted in config for fromDmsOnly',
                    );
                    expect(
                      effective.isPathAllowed('/'),
                      isFalse,
                      reason:
                          'Home path / must be blocked for fromDmsOnly (tray not allowed)',
                    );
                    expect(
                      effective.hideSelectors,
                      contains('section[aria-label=\'Stories\']'),
                      reason: 'Story tray must remain hidden in fromDmsOnly mode',
                    );
                    break;

                  case StoriesViewMode.fromFollowing:
                    expect(
                      effective.isPathAllowed('/stories/johndoe/12345/'),
                      isTrue,
                      reason:
                          'Story URL path pattern should be permitted for fromFollowing',
                    );
                    expect(
                      effective.isPathAllowed('/'),
                      isTrue,
                      reason:
                          'Home path / is allowed in fromFollowing (for isolated tray WebView)',
                    );
                    expect(
                      effective.hideSelectors.contains('section[aria-label=\'Stories\']'),
                      isFalse,
                      reason:
                          'Story tray must NOT be in global hideSelectors for fromFollowing',
                    );
                    break;
                }

                // 5. STORIES POSTING / CREATION
                if (postingEnabled) {
                  expect(
                    effective.isPathAllowed('/stories/create/'),
                    isTrue,
                    reason:
                        'Story creation path should be allowed when posting enabled',
                  );
                  expect(
                    effective.hideSelectors.contains('a[href*=\'/create/story\']'),
                    isFalse,
                    reason:
                        'Create story selectors should NOT be hidden when posting enabled',
                  );
                } else {
                  expect(
                    effective.isPathAllowed('/stories/create/'),
                    isFalse,
                    reason:
                        'Story creation path should be blocked when posting disabled',
                  );
                  expect(
                    effective.hideSelectors,
                    contains('a[href*=\'/create/story\']'),
                    reason:
                        'Create story button should be hidden when posting disabled',
                  );
                }
              },
            );
          }
        }
      }
    }
  });
}
