import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shell/domain/shell_tab.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../../../webview/data/webview_constants.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
import '../../../webview/presentation/widgets/webview_container.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification_item.dart';
import '../providers/notifications_provider.dart';

/// State provider for the Notifications tab view mode (Activity WebView vs Native List).
final notificationsViewIndexProvider = StateProvider<int>((ref) => 0);

/// Screen displaying account activity via guarded WebView and native alerts list.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const String activityUrl =
      'https://${WebViewConstants.allowedHost}/accounts/activity/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeView = ref.watch(notificationsViewIndexProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    icon: Icon(Icons.public_rounded, size: 16),
                    label: Text('Activity Feed'),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: Icon(Icons.notifications_active_outlined, size: 16),
                    label: Text('Native Alerts'),
                  ),
                ],
                selected: {activeView},
                onSelectionChanged: (newSelection) {
                  ref.read(notificationsViewIndexProvider.notifier).state =
                      newSelection.first;
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: activeView,
        children: const [
          // View 0: Guarded WebView pointing directly to /accounts/activity/
          WebviewContainer(
            initialUrl: activityUrl,
            isMainInbox: false,
          ),

          // View 1: Native alert list with pull-to-refresh & swipe-to-dismiss
          _NativeNotificationsListView(),
        ],
      ),
    );
  }
}

class _NativeNotificationsListView extends ConsumerWidget {
  const _NativeNotificationsListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listenerEnabledAsync = ref.watch(notificationsListenerEnabledProvider);
    final notificationsAsync = ref.watch(notificationsListNotifierProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Permission alert banner if notification listener is disabled
        listenerEnabledAsync.maybeWhen(
          data: (isEnabled) {
            if (!isEnabled) {
              return const _ListenerPermissionBanner();
            }
            return const SizedBox.shrink();
          },
          orElse: () => const SizedBox.shrink(),
        ),

        // Native Alert List header with Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Captured Notifications',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded, size: 20),
                    tooltip: 'Mark all as read',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      ref
                          .read(notificationsListNotifierProvider.notifier)
                          .markAllAsRead();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                    tooltip: 'Clear all notifications',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmClearAll(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),

        // List body
        Expanded(
          child: notificationsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load notifications',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        ref
                            .read(notificationsListNotifierProvider.notifier)
                            .refresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _buildEmptyState(context, ref);
              }

              return RefreshIndicator(
                onRefresh: () => ref
                    .read(notificationsListNotifierProvider.notifier)
                    .refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationTile(item: item);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationsListNotifierProvider.notifier).refresh(),
      child: ListView(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No Notifications Captured Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'ZeroScroll intercepts only your Instagram messages and activity notifications on-device. When you receive a notification, it will be saved here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will delete all stored notifications from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(notificationsListNotifierProvider.notifier).clearAll();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final relativeTime = _formatRelativeTime(item.timestamp);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        ref
            .read(notificationsListNotifierProvider.notifier)
            .deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification removed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        elevation: item.isRead ? 0 : 1,
        color: item.isRead
            ? theme.colorScheme.surfaceContainerLowest
            : theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: item.isRead
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.3)
                : theme.colorScheme.primary.withValues(alpha: 0.3),
            width: item.isRead ? 0.5 : 1.2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleItemTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getIconBackgroundColor(context, item.type),
                  foregroundColor: _getIconForegroundColor(context, item.type),
                  child: Icon(_getIconForType(item.type), size: 18),
                ),
                const SizedBox(width: 12),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.sender ?? item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            relativeTime,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unread indicator dot
                if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.unreadBadgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, WidgetRef ref) {
    // 1. Mark as read
    ref.read(notificationsListNotifierProvider.notifier).markAsRead(item.id);

    // 2. Navigate based on notification category
    if (item.type == NotificationType.dm) {
      // Switch tab to Messages
      ref.read(activeShellTabProvider.notifier).selectTab(ShellTab.messages);

      // Deep link to direct thread if available
      final controller = ref.read(webViewControllerProvider);
      if (item.threadId != null && item.threadId!.isNotEmpty) {
        controller?.loadThread(item.threadId!);
      } else {
        controller?.loadInbox();
      }
    } else if (item.type == NotificationType.activity) {
      // Switch SegmentedButton to Activity Feed WebView
      ref.read(notificationsViewIndexProvider.notifier).state = 0;
      ref.read(webViewControllerProvider)?.loadNotifications();
    }
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.dm:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.activity:
        return Icons.favorite_border_rounded;
      case NotificationType.other:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconBackgroundColor(BuildContext context, NotificationType type) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.dm:
        return theme.colorScheme.primary.withValues(alpha: 0.12);
      case NotificationType.activity:
        return Colors.pink.withValues(alpha: 0.12);
      case NotificationType.other:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  Color _getIconForegroundColor(BuildContext context, NotificationType type) {
    final theme = Theme.of(context);
    switch (type) {
      case NotificationType.dm:
        return theme.colorScheme.primary;
      case NotificationType.activity:
        return Colors.pink.shade600;
      case NotificationType.other:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

class _ListenerPermissionBanner extends ConsumerWidget {
  const _ListenerPermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade700.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_paused_outlined,
            color: Colors.amber.shade800,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Access Disabled',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grant access so ZeroScroll can capture your DMs and alerts locally without sending data off-device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        ref
                            .read(notificationsRepositoryProvider)
                            .openListenerSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        ref.invalidate(notificationsListenerEnabledProvider);
                      },
                      child: const Text('Check Status'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
