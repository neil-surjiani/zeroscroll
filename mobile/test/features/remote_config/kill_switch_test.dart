import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/remote_config/presentation/providers/remote_config_provider.dart';
import 'package:zeroscroll/features/webview/presentation/widgets/webview_container.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  group('KillSwitchConfig Domain Model', () {
    test('default configuration has enabled false and friendly default message', () {
      const config = KillSwitchConfig();
      expect(config.enabled, isFalse);
      expect(
        config.message,
        'ZeroScroll is paused while we fix an Instagram change',
      );
    });

    test('fromJson parses custom message and enabled state', () {
      final json = {
        'enabled': true,
        'message': 'Custom maintenance in progress',
      };
      final config = KillSwitchConfig.fromJson(json);
      expect(config.enabled, isTrue);
      expect(config.message, 'Custom maintenance in progress');
    });

    test('fromJson falls back to default message if message is null or empty', () {
      final jsonEmpty = {'enabled': true, 'message': '   '};
      final config = KillSwitchConfig.fromJson(jsonEmpty);
      expect(config.enabled, isTrue);
      expect(
        config.message,
        'ZeroScroll is paused while we fix an Instagram change',
      );
    });
  });

  group('KillSwitchOverlay Widget', () {
    testWidgets('renders pause title, message, and executes retry callback', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: KillSwitchOverlay(
            message: 'Testing pause message',
            onRetry: () async {
              retried = true;
            },
          ),
        ),
      );

      expect(find.text('ZeroScroll is Paused'), findsOneWidget);
      expect(find.text('Testing pause message'), findsOneWidget);
      expect(find.byKey(const ValueKey('kill_switch_retry_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('kill_switch_retry_button')));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  group('WebviewContainer Kill Switch Guard', () {
    testWidgets('when kill switch is enabled, WebView is NOT rendered and KillSwitchOverlay is shown', (tester) async {
      const pausedConfig = RouteConfig(
        version: 1,
        userAgent: 'TestAgent',
        fallbackPath: '/direct/inbox/',
        allowedPaths: ['^/direct/'],
        alwaysBlockedPaths: ['^/\$'],
        hideSelectors: [],
        killSwitch: KillSwitchConfig(
          enabled: true,
          message: 'ZeroScroll paused for emergency fixes',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routeConfigProvider.overrideWith((ref) => Future.value(pausedConfig)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WebviewContainer(),
            ),
          ),
        ),
      );

      await tester.pump();

      // KillSwitchOverlay must be present
      expect(find.byType(KillSwitchOverlay), findsOneWidget);
      expect(find.text('ZeroScroll paused for emergency fixes'), findsOneWidget);

      // InAppWebView MUST NOT be loaded or mounted in the widget tree
      expect(find.byType(InAppWebView), findsNothing);
    });

    testWidgets('when kill switch is disabled, InAppWebView IS rendered normally', (tester) async {
      const activeConfig = RouteConfig(
        version: 1,
        userAgent: 'TestAgent',
        fallbackPath: '/direct/inbox/',
        allowedPaths: ['^/direct/'],
        alwaysBlockedPaths: ['^/\$'],
        hideSelectors: [],
        killSwitch: KillSwitchConfig(
          enabled: false,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routeConfigProvider.overrideWith((ref) => Future.value(activeConfig)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WebviewContainer(),
            ),
          ),
        ),
      );

      await tester.pump();

      // KillSwitchOverlay must NOT be present
      expect(find.byType(KillSwitchOverlay), findsNothing);

      // InAppWebView must be present
      expect(find.byType(InAppWebView), findsOneWidget);
    });
  });
}
