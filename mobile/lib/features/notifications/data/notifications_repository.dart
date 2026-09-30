import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_item.dart';

/// Repository contract for accessing locally stored notifications.
abstract class NotificationsRepository {
  Future<List<NotificationItem>> getNotifications();
  Future<void> markAsRead(String id);
  Future<void> clearAll();
}

/// In-memory repository implementation for notifications.
class LocalNotificationsRepository implements NotificationsRepository {
  final List<NotificationItem> _items = [];

  @override
  Future<List<NotificationItem>> getNotifications() async =>
      List.unmodifiable(_items);

  @override
  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return LocalNotificationsRepository();
});
