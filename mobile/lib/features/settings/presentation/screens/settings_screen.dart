import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_flavor.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../security/presentation/screens/debug_screen.dart';
import '../../../shell/domain/shell_tab.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
import '../providers/settings_provider.dart';

/// Screen displaying application settings, preferences, and account log-out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // App Identity Header
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _handleVersionTap(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Distribution: ${flavor.appTitle} (v1.0.0)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'PREFERENCES',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme Mode'),
                subtitle: Text(switch (settings.themeMode) {
                  ThemeMode.system => 'System Default',
                  ThemeMode.light => 'Light Mode',
                  ThemeMode.dark => 'Dark Mode',
                }),
                trailing: DropdownButton<ThemeMode>(
                  value: settings.themeMode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .updateSettings(settings.copyWith(themeMode: mode));
                    }
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Biometric Lock'),
                subtitle: const Text('Require biometric auth to view messages'),
                value: settings.biometricLockEnabled,
                onChanged: (value) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateSettings(
                        settings.copyWith(biometricLockEnabled: value),
                      );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'PRIVACY & SECURITY',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Zero Data Collection'),
                subtitle: Text(
                  'All credentials, messages, and cookies stay strictly on this device.',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Reload Messages'),
                subtitle: const Text('Refresh current WebView container'),
                onTap: () {
                  ref.read(webViewControllerProvider)?.reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reloading web container...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text(
          'ACCOUNT ACTIONS',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text(
              'Log Out',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Clears all cookies, web cache, localStorage, and IndexedDB on this device.',
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out of ZeroScroll?'),
        content: const Text(
          'This will completely clear your local session, cookies, cache, and on-device storage. You will need to log in again to access direct messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final controller = ref.read(webViewControllerProvider);
        if (controller != null) {
          await controller.clearAllSessionData();
        }
        // Switch back to messages tab to show the fresh login screen
        ref.read(activeShellTabProvider.notifier).selectTab(ShellTab.messages);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Logged out. All local session data and cache cleared.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  static int _tapCount = 0;
  static DateTime? _lastTapTime;

  void _handleVersionTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount == 7) {
      _tapCount = 0;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DebugScreen()));
    } else if (_tapCount >= 4) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are ${7 - _tapCount} steps away from Developer Options.',
          ),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
