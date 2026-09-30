import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shell/domain/shell_tab.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';

/// Screen displaying notifications and account activity.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Activity & Notifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Only your direct message alerts and account notifications are accessible. Discover feeds and promoted stories remain strictly filtered.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final controller = ref.read(webViewControllerProvider);
                    if (controller != null) {
                      await controller.loadNotifications();
                      ref
                          .read(activeShellTabProvider.notifier)
                          .selectTab(ShellTab.messages);
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('View Activity in Container'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
