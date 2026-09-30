/// Type of notification captured on-device.
enum NotificationType {
  dm,
  activity,
  other;

  static NotificationType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'DM':
        return NotificationType.dm;
      case 'ACTIVITY':
        return NotificationType.activity;
      default:
        return NotificationType.other;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.dm:
        return 'Direct Message';
      case NotificationType.activity:
        return 'Activity';
      case NotificationType.other:
        return 'System & Other';
    }
  }
}

/// Entity representing an on-device captured notification item.
/// Stored strictly in local SQLite and never sent over the network.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = NotificationType.dm,
    this.sender,
    this.threadId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? sender;
  final String? threadId;
  final bool isRead;

  /// Compatibility alias for [body]
  String get text => body;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    String? sender,
    String? threadId,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      threadId: threadId ?? this.threadId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': body,
      'postedAt': timestamp.millisecondsSinceEpoch,
      'type': type.name.toUpperCase(),
      'sender': sender,
      'threadId': threadId,
      'isRead': isRead,
    };
  }

  factory NotificationItem.fromMap(Map<dynamic, dynamic> map) {
    final rawTimestamp = map['postedAt'];
    final DateTime dt;
    if (rawTimestamp is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      dt = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    final rawType = map['type'] as String?;
    final text = (map['text'] ?? map['body'] ?? '') as String;
    final title = (map['title'] ?? '') as String;

    return NotificationItem(
      id: (map['id'] ?? '') as String,
      title: title,
      body: text,
      timestamp: dt,
      type: NotificationType.fromString(rawType),
      sender: map['sender'] as String?,
      threadId: map['threadId'] as String?,
      isRead: map['isRead'] == true || map['isRead'] == 1,
    );
  }
}
