import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/presentation/providers/remote_config_provider.dart';
import 'package:zeroscroll/features/webview/presentation/providers/webview_provider.dart';
import 'package:zeroscroll/features/webview/presentation/widgets/webview_container.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('WebviewContainer Graceful Degradation / Fail-Closed Guard Tests', () {
    final mockRouteConfig = RouteConfig(
      version: 1,
      userAgent: 'test',
      fallbackPath: '/direct/inbox/',
      allowedPaths: const [r'^/direct/'],
      alwaysBlockedPaths: const [],
      hideSelectors: const [],
      featureGroups: RouteConfig.createDefaultFeatureGroups(),
    );

    testWidgets('Renders Security Guard Offline screen when guard JS asset fails to load', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routeConfigProvider.overrideWith((ref) => Future.value(mockRouteConfig)),
            guardJsProvider.overrideWith((ref) async {
              throw Exception('Asset load failure');
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WebviewContainer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guard_failed_overlay')), findsOneWidget);
      expect(find.text('Security Guard Offline'), findsOneWidget);
      expect(
        find.textContaining('Guard script asset could not be loaded from app bundle'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('guard_retry_btn')), findsOneWidget);
    });

    testWidgets('Renders Security Guard Offline screen when guard JS asset load throws', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routeConfigProvider.overrideWith((ref) => Future.value(mockRouteConfig)),
            guardJsProvider.overrideWith((ref) => Future.error('File not found')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WebviewContainer(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('guard_failed_overlay')), findsOneWidget);
      expect(find.text('Security Guard Offline'), findsOneWidget);
      expect(find.byKey(const ValueKey('guard_retry_btn')), findsOneWidget);
    });

    testWidgets('Shows fail-closed overlay when guard verification triggers onGuardFailure', (tester) async {
      final container = ProviderContainer(
        overrides: [
          routeConfigProvider.overrideWith((ref) => Future.value(mockRouteConfig)),
          guardJsProvider.overrideWith((ref) => Future.value('mock_js')),
        ],
      );
      addTearDown(container.dispose);

      container.read(webviewNotifierProvider.notifier).onGuardFailure(
            'Guard script injection could not be verified on this page.',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: WebviewContainer(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Fail-closed overlay must appear and block the screen
      expect(find.byKey(const ValueKey('guard_failed_overlay')), findsOneWidget);
      expect(find.text('Security Guard Offline'), findsOneWidget);
      expect(
        find.textContaining('Guard script injection could not be verified on this page.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('guard_retry_btn')), findsOneWidget);
    });
  });
}
