import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/limits/presentation/providers/reel_budget_provider.dart';
import 'package:zeroscroll/features/remote_config/data/remote_config_repository.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/settings/presentation/screens/settings_screen.dart';
import 'package:zeroscroll/features/shell/domain/shell_tab.dart';
import 'package:zeroscroll/features/shell/presentation/providers/shell_provider.dart';
import 'package:zeroscroll/features/shell/presentation/screens/home_screen.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  Widget createShellTestWidget({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('Shell Navigation & 3-Tab Structure', () {
    testWidgets('renders all 3 navigation tabs properly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(container.read(activeShellTabProvider), ShellTab.messages);
    });

    testWidgets('switching tabs updates activeShellTabProvider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Activity
      await tester.tap(find.text('Activity'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(activeShellTabProvider), ShellTab.notifications);

      // Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(activeShellTabProvider), ShellTab.settings);

      // Switch back to Messages
      await tester.tap(find.text('Messages'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(activeShellTabProvider), ShellTab.messages);
    });
  });

  group('Unread Badge on Messages Tab', () {
    testWidgets('displays badge count when unread count > 0', (tester) async {
      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          unreadMessagesCountProvider.overrideWith((ref) => 3),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      // Badge count "3" should be found
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides badge when unread count is 0', (tester) async {
      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          unreadMessagesCountProvider.overrideWith((ref) => 0),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Badge), findsNothing);
    });
  });

  group('Top SlimStatsBar Collapsible Behavior', () {
    testWidgets('displays stats and collapses on tap', (tester) async {
      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          todayUsageMinutesProvider.overrideWith((ref) => 25),
          todayReelCountProvider.overrideWith(
            (ref) => TodayReelCountNotifier(ref.watch(reelBudgetServiceProvider)),
          ),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      // Initially expanded: contains '25m in app'
      expect(find.text('25m in app'), findsOneWidget);
      expect(find.byKey(const ValueKey('collapse_stats_bar')), findsOneWidget);

      // Tap collapse
      await tester.tap(find.byKey(const ValueKey('collapse_stats_bar')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(statsBarCollapsedProvider), isTrue);
      // Collapsed strip displays compact stats
      expect(find.byKey(const ValueKey('expand_stats_bar')), findsOneWidget);
      expect(find.textContaining('⏱ 25m'), findsOneWidget);

      // Tap expand
      await tester.tap(find.byKey(const ValueKey('expand_stats_bar')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(container.read(statsBarCollapsedProvider), isFalse);
      expect(find.text('25m in app'), findsOneWidget);
    });
  });

  group('Settings Screen Sections & Developer Unlock', () {
    testWidgets('displays all 6 standard sections and legal disclaimer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          flavorConfigProvider.overrideWithValue(FlavorConfig.play()),
          activeShellTabProvider.overrideWith(
            (ref) => ShellTabNotifier()..selectTab(ShellTab.settings),
          ),
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

      await tester.pumpWidget(createShellTestWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('LIMITS & FOCUS'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('SECURITY'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(
        find.textContaining('Not affiliated with or endorsed by Meta or Instagram'),
        findsOneWidget,
      );

      // Developer section is hidden initially
      expect(find.text('DEVELOPER OPTIONS'), findsNothing);

      // Tap version tile 7 times to unlock developer section
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.byKey(const ValueKey('settings_version_tile')));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(developerModeUnlockedProvider), isTrue);
      expect(find.text('DEVELOPER OPTIONS'), findsOneWidget);
      expect(find.text('Developer Diagnostics'), findsOneWidget);
    });
  });
}
