import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/data/remote_config_repository.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/webview/domain/webview_mode.dart';
import 'package:zeroscroll/features/webview/presentation/providers/webview_provider.dart';
import 'package:zeroscroll/features/webview/presentation/widgets/webview_container.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('Single Item Viewer Mode State & Notifier', () {
    test('initial state defaults to direct messages and not viewer mode', () {
      final notifier = WebviewNotifier();
      expect(notifier.state.mode, WebviewMode.directMessages);
      expect(notifier.state.isViewerMode, isFalse);
      expect(notifier.state.currentMediaId, isNull);
      expect(notifier.state.showBudgetReached, isFalse);
    });

    test('transitions to singleMediaViewer mode with mediaId', () {
      final notifier = WebviewNotifier();
      notifier.setViewerMode(
        isViewer: true,
        mediaId: 'C4xX9yZ',
        lastDirectPath: '/direct/t/12345/',
      );

      expect(notifier.state.mode, WebviewMode.singleMediaViewer);
      expect(notifier.state.isViewerMode, isTrue);
      expect(notifier.state.currentMediaId, 'C4xX9yZ');
      expect(notifier.state.lastDirectPath, '/direct/t/12345/');
    });

    test('exiting viewer mode resets mode, mediaId, and budget overlay', () {
      final notifier = WebviewNotifier();
      notifier.setViewerMode(isViewer: true, mediaId: 'C4xX9yZ');
      notifier.setBudgetReached(true);
      expect(notifier.state.showBudgetReached, isTrue);

      notifier.setViewerMode(isViewer: false);
      expect(notifier.state.mode, WebviewMode.directMessages);
      expect(notifier.state.isViewerMode, isFalse);
      expect(notifier.state.currentMediaId, isNull);
      expect(notifier.state.showBudgetReached, isFalse);
    });
  });

  group('WebviewContainer Viewer Mode Overlay Widgets', () {
    testWidgets('renders persistent top bar overlay in viewer mode', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/direct/', r'^/reel/[^/]+/?$'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );

      // Put container into singleMediaViewer mode
      container
          .read(webviewNotifierProvider.notifier)
          .setViewerMode(isViewer: true, mediaId: 'mock_reel_1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: WebviewContainer()),
          ),
        ),
      );

      // Bounded pumps for initial rendering
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('viewer_close_button')), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.textContaining('Reels today:'), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byKey(const ValueKey('viewer_close_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // After closing, mode transitions out of singleMediaViewer
      expect(
        container.read(webviewNotifierProvider).mode,
        WebviewMode.directMessages,
      );
      expect(
        find.byKey(const ValueKey('viewer_close_button')),
        findsNothing,
      );
    });

    testWidgets('renders budget reached screen when budget exceeded', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/direct/', r'^/reel/[^/]+/?$'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );

      // Set viewer mode and budget reached
      container
          .read(webviewNotifierProvider.notifier)
          .setViewerMode(isViewer: true, mediaId: 'mock_reel_over_budget');
      container.read(webviewNotifierProvider.notifier).setBudgetReached(true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: WebviewContainer()),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Budget reached overlay should be visible
      expect(find.text('Daily Reel Budget Reached'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget_return_button')),
        findsOneWidget,
      );
      expect(find.text('Return to Messages'), findsOneWidget);

      // Top bar Close button should not overlap the budget screen
      expect(find.byKey(const ValueKey('viewer_close_button')), findsNothing);

      // Tapping Return to Messages exits viewer mode
      await tester.tap(find.byKey(const ValueKey('budget_return_button')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        container.read(webviewNotifierProvider).mode,
        WebviewMode.directMessages,
      );
      expect(find.text('Daily Reel Budget Reached'), findsNothing);
    });
  });
}
