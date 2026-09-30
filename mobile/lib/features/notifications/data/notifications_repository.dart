import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_item.dart';

/// Abstract repository contract for managing captured on-device notifications.
abstract class NotificationsRepository {
  /// Checks whether ZeroScroll has notification listener permission enabled in Android settings.
  Future<bool> isListenerEnabled();

  /// Launches the system Android Notification Listener Access settings screen.
  Future<void> openListenerSettings();

  /// Opens the App Info settings screen (required for "Allow restricted settings" on Android 13+).
  Future<void> openAppInfoSettings();

  /// Checks if POST_NOTIFICATIONS runtime permission is granted (Android 13+).
  Future<bool> isPostNotificationsGranted();

  /// Requests the POST_NOTIFICATIONS runtime permission on Android 13+.
  Future<void> requestPostNotificationsPermission();

  /// Checks if battery optimization is ignored for ZeroScroll.
  Future<bool> isBatteryOptimizationIgnored();

  /// Opens the battery optimization settings screen.
  Future<void> openBatteryOptimizationSettings();

  /// Returns the device Android SDK version (e.g. 33 for Android 13).
  Future<int> getAndroidSdkVersion();

  /// Retrieves stored notifications from local SQLite, ordered by newest first.
  Future<List<NotificationItem>> getNotifications({
    int limit = 100,
    NotificationType? type,
  });

  /// Marks a specific notification as read.
  Future<void> markAsRead(String id);

  /// Marks all stored notifications as read.
  Future<void> markAllAsRead();

  /// Deletes a single notification from local storage.
  Future<void> deleteNotification(String id);

  /// Clears all notifications from local storage.
  Future<void> clearAll();

  /// Returns the current count of unread Direct Messages.
  Future<int> getUnreadDmCount();

  /// Retrieves current notification capture settings.
  Future<Map<String, dynamic>> getSettings();

  /// Updates notification capture settings in native SharedPreferences.
  Future<void> updateSettings({
    bool? storageEnabled,
    int? retentionDays,
    bool? repostEnabled,
    bool? dismissOriginalEnabled,
    bool? messagesOnly,
  });

  /// Configures notification filter mode (messages only vs messages and activity).
  Future<void> setNotificationFilter({required bool messagesOnly});

  /// Retrieves initial notification payload if the app was launched by tapping an alert.
  Future<Map<String, dynamic>?> getInitialNotification();

  /// Real-time stream of incoming notifications captured by the native listener service.
  Stream<NotificationItem> get notificationStream;
}

/// Native Android implementation using MethodChannel and EventChannel.
class NativeNotificationsRepository implements NotificationsRepository {
  NativeNotificationsRepository({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ??
            const MethodChannel('com.apexventures.zeroscroll/notifications'),
        _eventChannel = eventChannel ??
            const EventChannel('com.apexventures.zeroscroll/notifications_stream');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<NotificationItem>? _stream;

  @override
  Future<bool> isListenerEnabled() async {
    try {
      final bool? result =
          await _methodChannel.invokeMethod<bool>('isListenerEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openListenerSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openListenerSettings');
    } catch (_) {}
  }

  @override
  Future<void> openAppInfoSettings() async {
    try {
      await _methodChannel.invokeMethod<void>('openAppInfoSettings');
    } catch (_) {}
  }

  @override
  Future<bool> isPostNotificationsGranted() async {
    try {
      final bool? result =
          await _methodChannel.invokeMethod<bool>('isPostNotificationsGranted');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> requestPostNotificationsPermission() async {
    try {
      await _methodChannel
          .invokeMethod<void>('requestPostNotificationsPermission');
    } catch (_) {}
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async {
    try {
      final bool? result = await _methodChannel
          .invokeMethod<bool>('isBatteryOptimizationIgnored');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> openBatteryOptimizationSettings() async {
    try {
      await _methodChannel
          .invokeMethod<void>('openBatteryOptimizationSettings');
    } catch (_) {}
  }

  @override
  Future<int> getAndroidSdkVersion() async {
    try {
      final int? result =
          await _methodChannel.invokeMethod<int>('getAndroidSdkVersion');
      return result ?? 33;
    } catch (_) {
      return 33;
    }
  }

  @override
  Future<List<NotificationItem>> getNotifications({
    int limit = 100,
    NotificationType? type,
  }) async {
    try {
      final List<dynamic>? raw =
          await _methodChannel.invokeListMethod<dynamic>(
        'getNotifications',
        {
          'limit': limit,
          if (type != null) 'type': type.name.toUpperCase(),
        },
      );
      if (raw == null) return [];
      return raw
          .map((e) => NotificationItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await _methodChannel.invokeMethod<bool>('markRead', {'id': id});
    } catch (_) {}
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _methodChannel.invokeMethod<int>('markAllRead');
    } catch (_) {}
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _methodChannel.invokeMethod<bool>('deleteNotification', {'id': id});
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    try {
      await _methodChannel.invokeMethod<int>('clearAll');
    } catch (_) {}
  }

  @override
  Future<int> getUnreadDmCount() async {
    try {
      final int? count =
          await _methodChannel.invokeMethod<int>('getUnreadDmCount');
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _methodChannel.invokeMapMethod<dynamic, dynamic>('getSettings');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return {
      'storageEnabled': true,
      'retentionDays': 7,
      'repostEnabled': false,
      'dismissOriginalEnabled': false,
    };
  }

  @override
  Future<void> updateSettings({
    bool? storageEnabled,
    int? retentionDays,
    bool? repostEnabled,
    bool? dismissOriginalEnabled,
    bool? messagesOnly,
  }) async {
    try {
      final Map<String, dynamic> args = {};
      if (storageEnabled != null) args['storageEnabled'] = storageEnabled;
      if (retentionDays != null) args['retentionDays'] = retentionDays;
      if (repostEnabled != null) args['repostEnabled'] = repostEnabled;
      if (dismissOriginalEnabled != null) {
        args['dismissOriginalEnabled'] = dismissOriginalEnabled;
      }
      if (messagesOnly != null) args['messagesOnly'] = messagesOnly;
      await _methodChannel.invokeMethod<bool>('updateSettings', args);
    } catch (_) {}
  }

  @override
  Future<void> setNotificationFilter({required bool messagesOnly}) async {
    try {
      await _methodChannel.invokeMethod<bool>('setNotificationFilter', {
        'messagesOnly': messagesOnly,
      });
    } catch (_) {}
  }

  @override
  Future<Map<String, dynamic>?> getInitialNotification() async {
    try {
      final Map<dynamic, dynamic>? result = await _methodChannel
          .invokeMapMethod<dynamic, dynamic>('getInitialNotification');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {}
    return null;
  }

  @override
  Stream<NotificationItem> get notificationStream {
    _stream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) {
          if (event is Map) {
            return NotificationItem.fromMap(Map<dynamic, dynamic>.from(event));
          }
          return null;
        })
        .where((item) => item != null)
        .cast<NotificationItem>();
    return _stream!;
  }
}

/// In-memory repository implementation useful for tests and local fallbacks.
class LocalNotificationsRepository implements NotificationsRepository {
  LocalNotificationsRepository({List<NotificationItem>? initialItems})
      : _items = List.of(initialItems ?? []);

  final List<NotificationItem> _items;
  final StreamController<NotificationItem> _streamController =
      StreamController<NotificationItem>.broadcast();
  bool _listenerEnabled = true;

  void emitMockNotification(NotificationItem item) {
    _items.insert(0, item);
    _streamController.add(item);
  }

  void setListenerEnabled(bool enabled) {
    _listenerEnabled = enabled;
  }

  @override
  Future<bool> isListenerEnabled() async => _listenerEnabled;

  @override
  Future<void> openListenerSettings() async {}

  @override
  Future<void> openAppInfoSettings() async {}

  @override
  Future<bool> isPostNotificationsGranted() async => true;

  @override
  Future<void> requestPostNotificationsPermission() async {}

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;

  @override
  Future<void> openBatteryOptimizationSettings() async {}

  @override
  Future<int> getAndroidSdkVersion() async => 33;

  @override
  Future<List<NotificationItem>> getNotifications({
    int limit = 100,
    NotificationType? type,
  }) async {
    var filtered = _items;
    if (type != null) {
      filtered = filtered.where((item) => item.type == type).toList();
    }
    return filtered.take(limit).toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
  }

  @override
  Future<int> getUnreadDmCount() async {
    return _items.where((i) => i.type == NotificationType.dm && !i.isRead).length;
  }

  bool _messagesOnly = true;

  bool get isMessagesOnlyFiltered => _messagesOnly;

  @override
  Future<Map<String, dynamic>> getSettings() async {
    return {
      'storageEnabled': true,
      'retentionDays': 7,
      'repostEnabled': false,
      'dismissOriginalEnabled': false,
      'messagesOnly': _messagesOnly,
    };
  }

  @override
  Future<void> updateSettings({
    bool? storageEnabled,
    int? retentionDays,
    bool? repostEnabled,
    bool? dismissOriginalEnabled,
    bool? messagesOnly,
  }) async {
    if (messagesOnly != null) {
      _messagesOnly = messagesOnly;
    }
  }

  @override
  Future<void> setNotificationFilter({required bool messagesOnly}) async {
    _messagesOnly = messagesOnly;
  }

  @override
  Future<Map<String, dynamic>?> getInitialNotification() async => null;

  @override
  Stream<NotificationItem> get notificationStream => _streamController.stream;
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NativeNotificationsRepository();
});
