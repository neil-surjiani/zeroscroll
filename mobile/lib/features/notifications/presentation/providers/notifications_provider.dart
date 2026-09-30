import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_item.dart';

final notificationsListProvider = FutureProvider<List<NotificationItem>>((
  ref,
) async {
  final repository = ref.watch(notificationsRepositoryProvider);
  return repository.getNotifications();
});
