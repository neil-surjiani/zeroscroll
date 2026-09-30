import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/notifications/data/notifications_repository.dart';
import 'package:zeroscroll/features/notifications/domain/notification_item.dart';
import 'package:zeroscroll/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:zeroscroll/features/remote_config/data/remote_config_repository.dart';
import 'package:zeroscroll/features/remote_config/domain/route_config.dart';
import 'package:zeroscroll/features/shell/domain/shell_tab.dart';
import 'package:zeroscroll/features/shell/presentation/providers/shell_provider.dart';
import '../../helpers/test_webview_platform.dart';

void main() {
  setUpAll(() {
    TestInAppWebViewPlatform.register();
  });

  final item1 = NotificationItem(
    id: 'dm_101',
    title: 'grace_hopper',
    body: 'Need your review on compiler specs',
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    type: NotificationType.dm,
    sender: 'grace_hopper',
    isRead: false,
  );

  final item2 = NotificationItem(
    id: 'act_102',
    title: 'ada_lovelace',
    body: 'Liked your post',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    type: NotificationType.activity,
    sender: 'ada_lovelace',
    isRead: true,
  );

  Widget createWidget({required ProviderContainer container}) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: NotificationsScreen()),
      ),
    );
  }

  group('NotificationsScreen tests', () {
    testWidgets('renders segmented button and switches to Native Alerts', (
      tester,
    ) async {
      final repository =
          LocalNotificationsRepository(initialItems: [item1, item2]);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/accounts/activity'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Activity Feed'), findsOneWidget);
      expect(find.text('Native Alerts'), findsOneWidget);

      // Switch to Native Alerts
      await tester.tap(find.text('Native Alerts'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(notificationsViewIndexProvider), 1);
      expect(find.text('grace_hopper'), findsOneWidget);
      expect(find.text('Need your review on compiler specs'), findsOneWidget);
      expect(find.text('ada_lovelace'), findsOneWidget);
    });

    testWidgets('displays permission banner when notification access is disabled', (
      tester,
    ) async {
      final repository =
          LocalNotificationsRepository(initialItems: [])..setListenerEnabled(false);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          notificationsViewIndexProvider.overrideWith((ref) => 1),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/accounts/activity'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Notification Access Disabled'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('tapping DM notification navigates to Messages tab', (
      tester,
    ) async {
      final repository =
          LocalNotificationsRepository(initialItems: [item1]);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          notificationsViewIndexProvider.overrideWith((ref) => 1),
          activeShellTabProvider.overrideWith(
            (ref) => ShellTabNotifier()..selectTab(ShellTab.notifications),
          ),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/accounts/activity'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the DM item
      await tester.tap(find.text('grace_hopper'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify active shell tab switched to messages
      expect(container.read(activeShellTabProvider), ShellTab.messages);
    });

    testWidgets('tapping Activity notification switches segmented button to feed', (
      tester,
    ) async {
      final repository =
          LocalNotificationsRepository(initialItems: [item2]);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          notificationsViewIndexProvider.overrideWith((ref) => 1),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/accounts/activity'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the Activity item
      await tester.tap(find.text('ada_lovelace'));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify segmented view switched back to Activity Feed (0)
      expect(container.read(notificationsViewIndexProvider), 0);
    });

    testWidgets('dismissing item via swipe removes it from the list', (
      tester,
    ) async {
      final repository =
          LocalNotificationsRepository(initialItems: [item1]);
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          notificationsViewIndexProvider.overrideWith((ref) => 1),
          routeConfigProvider.overrideWith(
            (ref) => Future.value(
              const RouteConfig(
                version: 1,
                userAgent: 'test',
                fallbackPath: '/direct/inbox/',
                allowedPaths: [r'^/accounts/activity'],
                alwaysBlockedPaths: [],
                hideSelectors: [],
              ),
            ),
          ),
          guardJsProvider.overrideWith((ref) => Future.value('')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('grace_hopper'), findsOneWidget);

      // Dismiss swipe right-to-left
      await tester.drag(find.text('grace_hopper'), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('grace_hopper'), findsNothing);
      expect(find.text('No Notifications Captured Yet'), findsOneWidget);
    });
  });
}
