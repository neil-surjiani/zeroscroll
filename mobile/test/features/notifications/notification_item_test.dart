import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/notifications/domain/notification_item.dart';

void main() {
  group('NotificationItem domain model', () {
    test('serializes to and from Map correctly', () {
      final item = NotificationItem(
        id: 'test_123',
        title: 'sarah_c',
        body: 'Hey! Did you see the latest update?',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        type: NotificationType.dm,
        sender: 'sarah_c',
        threadId: 'thread_999',
        isRead: false,
      );

      final map = item.toMap();
      expect(map['id'], 'test_123');
      expect(map['title'], 'sarah_c');
      expect(map['text'], 'Hey! Did you see the latest update?');
      expect(map['type'], 'DM');
      expect(map['sender'], 'sarah_c');
      expect(map['threadId'], 'thread_999');
      expect(map['isRead'], isFalse);

      final fromMapItem = NotificationItem.fromMap(map);
      expect(fromMapItem.id, item.id);
      expect(fromMapItem.title, item.title);
      expect(fromMapItem.body, item.body);
      expect(fromMapItem.text, item.text);
      expect(fromMapItem.type, NotificationType.dm);
      expect(fromMapItem.sender, item.sender);
      expect(fromMapItem.threadId, item.threadId);
      expect(fromMapItem.isRead, isFalse);
    });

    test('copyWith updates properties properly', () {
      final item = NotificationItem(
        id: '1',
        title: 'Title',
        body: 'Body',
        timestamp: DateTime.now(),
        type: NotificationType.activity,
        isRead: false,
      );

      final updated = item.copyWith(isRead: true, sender: 'new_sender');
      expect(updated.isRead, isTrue);
      expect(updated.sender, 'new_sender');
      expect(updated.id, '1');
      expect(updated.type, NotificationType.activity);
    });

    test('NotificationType parsing from string handles variations', () {
      expect(NotificationType.fromString('DM'), NotificationType.dm);
      expect(NotificationType.fromString('dm'), NotificationType.dm);
      expect(NotificationType.fromString('ACTIVITY'), NotificationType.activity);
      expect(NotificationType.fromString('activity'), NotificationType.activity);
      expect(NotificationType.fromString('other'), NotificationType.other);
      expect(NotificationType.fromString(null), NotificationType.other);
      expect(NotificationType.fromString('unknown_string'), NotificationType.other);
    });
  });
}
