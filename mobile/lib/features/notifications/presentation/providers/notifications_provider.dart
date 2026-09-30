import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_item.dart';

/// Provider for checking whether Notification Listener Service permission is granted.
final notificationsListenerEnabledProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.isListenerEnabled();
});

/// State notifier managing the list of captured notifications.
class NotificationsListNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  NotificationsListNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _init();
  }

  final NotificationsRepository _repository;
  StreamSubscription<NotificationItem>? _streamSubscription;

  Future<void> _init() async {
    await load();
    _streamSubscription = _repository.notificationStream.listen(
      (newItem) {
        state.whenData((currentList) {
          // Avoid duplicate entries
          final updated = [
            newItem,
            ...currentList.where((item) => item.id != newItem.id),
          ];
          state = AsyncValue.data(updated);
        });
      },
      onError: (err, stack) {
        // Stream errors should not crash the state
      },
    );
  }

  Future<void> load() async {
    try {
      final items = await _repository.getNotifications();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state.whenData((items) {
      final updated = items.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    state.whenData((items) {
      final updated = items.map((item) => item.copyWith(isRead: true)).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    state.whenData((items) {
      final updated = items.where((item) => item.id != id).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

/// Provider exposing the notification list state notifier.
final notificationsListNotifierProvider = StateNotifierProvider<
    NotificationsListNotifier, AsyncValue<List<NotificationItem>>>((ref) {
  final repository = ref.watch(notificationsRepositoryProvider);
  return NotificationsListNotifier(repository);
});

/// Direct accessor for the notification list.
final notificationsListProvider =
    Provider<AsyncValue<List<NotificationItem>>>((ref) {
  return ref.watch(notificationsListNotifierProvider);
});

/// Computes the unread DM count in real time for badges and notifications.
final unreadDmCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsListNotifierProvider);
  return notificationsAsync.maybeWhen(
    data: (items) =>
        items.where((i) => i.type == NotificationType.dm && !i.isRead).length,
    orElse: () => 0,
  );
});

/// Settings provider for notification preferences.
final notificationSettingsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.getSettings();
});
