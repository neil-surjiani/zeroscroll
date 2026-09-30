import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/notifications/data/notifications_repository.dart';
import 'package:zeroscroll/features/notifications/domain/notification_item.dart';
import 'package:zeroscroll/features/notifications/presentation/providers/notifications_provider.dart';

void main() {
  group('NotificationsProvider and Notifier tests', () {
    late LocalNotificationsRepository repository;

    final item1 = NotificationItem(
      id: 'dm_1',
      title: 'david',
      body: 'Meeting at 3pm',
      timestamp: DateTime.now(),
      type: NotificationType.dm,
      sender: 'david',
      isRead: false,
    );

    final item2 = NotificationItem(
      id: 'act_1',
      title: 'eva',
      body: 'Liked your reel',
      timestamp: DateTime.now(),
      type: NotificationType.activity,
      sender: 'eva',
      isRead: true,
    );

    setUp(() {
      repository = LocalNotificationsRepository(initialItems: [item1, item2]);
    });

    test('initializes and computes unread DM count properly', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      // Wait for notifier to load
      await container.read(notificationsListNotifierProvider.notifier).load();

      final listState = container.read(notificationsListProvider);
      expect(listState.value?.length, 2);
      expect(container.read(unreadDmCountProvider), 1);
    });

    test('updates list and unread DM count on real-time stream event', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsListNotifierProvider.notifier).load();
      expect(container.read(unreadDmCountProvider), 1);

      // Emit new unread DM
      final newDm = NotificationItem(
        id: 'dm_2',
        title: 'frank',
        body: 'Can you call me?',
        timestamp: DateTime.now(),
        type: NotificationType.dm,
        sender: 'frank',
        isRead: false,
      );

      repository.emitMockNotification(newDm);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final items = container.read(notificationsListProvider).value!;
      expect(items.length, 3);
      expect(items.first.id, 'dm_2');
      expect(container.read(unreadDmCountProvider), 2);
    });

    test('markAsRead updates item and decrements unread count', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsListNotifierProvider.notifier).load();
      expect(container.read(unreadDmCountProvider), 1);

      await container.read(notificationsListNotifierProvider.notifier).markAsRead('dm_1');

      final items = container.read(notificationsListProvider).value!;
      expect(items.firstWhere((i) => i.id == 'dm_1').isRead, isTrue);
      expect(container.read(unreadDmCountProvider), 0);
    });

    test('deleteNotification removes item from state', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsListNotifierProvider.notifier).load();
      await container
          .read(notificationsListNotifierProvider.notifier)
          .deleteNotification('act_1');

      final items = container.read(notificationsListProvider).value!;
      expect(items.length, 1);
      expect(items.any((i) => i.id == 'act_1'), isFalse);
    });

    test('clearAll removes all items', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationsListNotifierProvider.notifier).load();
      await container.read(notificationsListNotifierProvider.notifier).clearAll();

      final items = container.read(notificationsListProvider).value!;
      expect(items.isEmpty, isTrue);
      expect(container.read(unreadDmCountProvider), 0);
    });
  });
}
