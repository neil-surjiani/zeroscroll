import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/notifications/data/notifications_repository.dart';
import 'package:zeroscroll/features/notifications/domain/notification_item.dart';

void main() {
  group('LocalNotificationsRepository tests', () {
    late LocalNotificationsRepository repository;

    final item1 = NotificationItem(
      id: 'notif_1',
      title: 'alice',
      body: 'Hello there!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: NotificationType.dm,
      sender: 'alice',
      isRead: false,
    );

    final item2 = NotificationItem(
      id: 'notif_2',
      title: 'bob',
      body: 'Liked your post',
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      type: NotificationType.activity,
      sender: 'bob',
      isRead: false,
    );

    setUp(() {
      repository = LocalNotificationsRepository(initialItems: [item1, item2]);
    });

    test('getNotifications returns initial items', () async {
      final items = await repository.getNotifications();
      expect(items.length, 2);
      expect(items.first.id, 'notif_1');
    });

    test('getNotifications filters by type', () async {
      final dms = await repository.getNotifications(type: NotificationType.dm);
      expect(dms.length, 1);
      expect(dms.first.type, NotificationType.dm);

      final activities =
          await repository.getNotifications(type: NotificationType.activity);
      expect(activities.length, 1);
      expect(activities.first.type, NotificationType.activity);
    });

    test('markAsRead marks specified item as read', () async {
      await repository.markAsRead('notif_1');
      final items = await repository.getNotifications();
      final updated = items.firstWhere((i) => i.id == 'notif_1');
      expect(updated.isRead, isTrue);
    });

    test('markAllAsRead marks all as read', () async {
      await repository.markAllAsRead();
      final items = await repository.getNotifications();
      expect(items.every((i) => i.isRead), isTrue);
    });

    test('deleteNotification removes item', () async {
      await repository.deleteNotification('notif_1');
      final items = await repository.getNotifications();
      expect(items.length, 1);
      expect(items.first.id, 'notif_2');
    });

    test('clearAll removes all items', () async {
      await repository.clearAll();
      final items = await repository.getNotifications();
      expect(items.isEmpty, isTrue);
    });

    test('getUnreadDmCount returns correct count', () async {
      expect(await repository.getUnreadDmCount(), 1);
      await repository.markAsRead('notif_1');
      expect(await repository.getUnreadDmCount(), 0);
    });

    test('notificationStream emits newly received notifications', () async {
      final streamFuture = repository.notificationStream.first;
      final newItem = NotificationItem(
        id: 'notif_3',
        title: 'clara',
        body: 'New DM arrived',
        timestamp: DateTime.now(),
        type: NotificationType.dm,
        sender: 'clara',
        isRead: false,
      );

      repository.emitMockNotification(newItem);
      final emitted = await streamFuture;
      expect(emitted.id, 'notif_3');
      expect(emitted.sender, 'clara');
    });
  });
}
