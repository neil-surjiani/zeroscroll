import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_flavor.dart';
import '../../../limits/presentation/screens/limits_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
import '../../../webview/presentation/widgets/webview_container.dart';
import '../../domain/shell_tab.dart';
import '../providers/shell_provider.dart';

/// Main Shell container displaying navigation and persistent tab views.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeShellTabProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'ZeroScroll',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: flavor.isSideload
                    ? Colors.amber.shade800.withValues(alpha: 0.15)
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: flavor.isSideload
                      ? Colors.amber.shade800.withValues(alpha: 0.4)
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                flavor.flavor.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: flavor.isSideload
                      ? (theme.brightness == Brightness.dark
                            ? Colors.amber.shade300
                            : Colors.amber.shade900)
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (activeTab == ShellTab.messages)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload Messages',
              onPressed: () {
                ref.read(webViewControllerProvider)?.reload();
              },
            ),
        ],
      ),
      // IndexedStack keeps all views alive in the widget tree across tab switches.
      body: SafeArea(
        child: IndexedStack(
          index: activeTab.index,
          children: const [
            WebviewContainer(),
            NotificationsScreen(),
            LimitsScreen(),
            SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected: (index) {
          ref
              .read(activeShellTabProvider.notifier)
              .selectTab(ShellTab.values[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty),
            selectedIcon: Icon(Icons.hourglass_full),
            label: 'Limits',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
