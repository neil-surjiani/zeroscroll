import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/remote_config/data/remote_config_repository.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/settings/data/feature_preferences_repository.dart';
import 'package:zeroscroll/features/settings/domain/feature_preferences.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';
import 'package:zeroscroll/features/shell/domain/shell_tab.dart';
import 'package:zeroscroll/features/shell/presentation/providers/shell_provider.dart';
import 'package:zeroscroll/features/shell/presentation/screens/home_screen.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('Stories Dynamic Tab and Settings Tests', () {
    testWidgets('renders 3 tabs by default when storiesViewMode is off', (tester) async {
      final mockRepo = LocalFeaturePreferencesRepository(
        const FeaturePreferences(storiesViewMode: StoriesViewMode.off),
      );

      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          featurePreferencesRepositoryProvider.overrideWithValue(mockRepo),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/direct/'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Stories'), findsNothing);
    });

    testWidgets('dynamically renders 4th Stories tab when storiesViewMode is fromFollowing', (tester) async {
      final mockRepo = LocalFeaturePreferencesRepository(
        const FeaturePreferences(storiesViewMode: StoriesViewMode.fromFollowing),
      );

      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          featurePreferencesRepositoryProvider.overrideWithValue(mockRepo),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/direct/'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Stories'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Tap on Stories tab
      await tester.tap(find.text('Stories'));
      await tester.pump();

      expect(container.read(activeShellTabProvider), ShellTab.stories);
    });

    testWidgets('Settings screen displays Stories & Content section and post story dialog', (tester) async {
      final mockRepo = LocalFeaturePreferencesRepository(
        const FeaturePreferences(
          storiesViewMode: StoriesViewMode.fromFollowing,
          storiesPostingEnabled: true,
          dailyStoryLimit: 10,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          featurePreferencesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STORIES & CONTENT'), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_stories_mode_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_story_budget_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_reels_from_dms_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_posts_from_dms_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_story_posting_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_post_story_tile')), findsOneWidget);

      // Scroll to Post Story tile and tap
      await tester.ensureVisible(find.byKey(const ValueKey('settings_post_story_tile')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings_post_story_tile')));
      await tester.pumpAndSettle();

      // Verify the warning modal appears
      expect(find.text('External App Handoff'), findsOneWidget);
      expect(
        find.textContaining('ZeroScroll cannot verify official app behavior outside this sandbox.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('confirm_post_story_button')), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('External App Handoff'), findsNothing);
    });
  });
}
