import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../limits/data/limits_repository.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';

/// Privacy & Data Security screen detailing on-device storage,
/// non-collection guarantees, and destructive local data management actions.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _clearNotifications(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Captured Notifications?'),
        content: const Text(
          'This will permanently delete all locally stored notification alerts and activity records from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_clear_notifications_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notificationsRepositoryProvider).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All captured notifications have been deleted.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logoutAndWipeData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out and Wipe All Data?'),
        content: const Text(
          'This will completely clear your login session, cookies, cache, local notification database, and mindful usage history. ZeroScroll will be reset to its initial state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_wipe_all_data_btn'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 1. Clear WebView session & cookies
      final webview = ref.read(webViewControllerProvider);
      if (webview != null) {
        await webview.clearAllSessionData();
      }

      // 2. Wipe limits and stats SQLite database
      await ref.read(limitsRepositoryProvider).wipeAllData();

      // 3. Clear captured notifications SQLite database
      await ref.read(notificationsRepositoryProvider).clearAll();

      // 4. Reset AppSettings to default
      await ref
          .read(settingsNotifierProvider.notifier)
          .updateSettings(const AppSettings());

      // 5. Reset Onboarding
      await ref.read(onboardingRepositoryProvider).resetOnboarding();
      await ref.read(onboardingStateProvider.notifier).reset();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All session data wiped. ZeroScroll has been reset.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate back to root / onboarding
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data Security'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Core Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Strictly On-Device Architecture',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ZeroScroll has no servers and collects zero personal data. Everything stays on your phone.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Stored Locally
            Text(
              'STORED LOCALLY ON YOUR DEVICE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _PrivacyItemRow(
                      icon: Icons.shield_outlined,
                      title: 'Sandboxed WebView Session',
                      description:
                          'Your login cookies and local web storage remain strictly isolated inside the Android app sandbox. Credentials are never intercepted or readable by the app.',
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Captured Message Alerts',
                      description:
                          'Incoming direct message alerts are stored in a local SQLite database to display message previews without opening feeds. Automatically deleted after the configured retention period.',
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.hourglass_top_rounded,
                      title: 'Mindful Limits & Schedules',
                      description:
                          'Your daily reel budget, app time limit, and focus schedules are stored entirely on-device via Drift SQLite.',
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.tune_rounded,
                      title: 'App Preferences & Guard Cache',
                      description:
                          'Your theme choice, biometric preferences, and cached route guard rules are stored in local application storage.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Never Collected
            Text(
              'NEVER COLLECTED OR TRANSMITTED',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    _PrivacyItemRow(
                      icon: Icons.cloud_off_rounded,
                      title: 'No Remote Backend Servers',
                      description:
                          'ZeroScroll operates without any server infrastructure. No user content, message text, or activity is ever uploaded anywhere.',
                      iconColor: Color(0xFF10B981),
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.analytics_outlined,
                      title: 'No Analytics or Trackers',
                      description:
                          'Zero third-party analytics SDKs, advertising beacons, tracking pixels, or crash-reporting services.',
                      iconColor: Color(0xFF10B981),
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'No Message or Thread Logging',
                      description:
                          'No code path logs message text, conversation thread IDs, or notification bodies in production builds.',
                      iconColor: Color(0xFF10B981),
                    ),
                    Divider(height: 20),
                    _PrivacyItemRow(
                      icon: Icons.phonelink_erase_rounded,
                      title: 'Excluded From Device Backups',
                      description:
                          'System backup rules strictly exclude all session cookies and local databases from Android cloud backups and device migration.',
                      iconColor: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Section 3: Data Management Actions
            Text(
              'DATA MANAGEMENT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const ValueKey('clear_notifications_tile'),
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear Captured Notifications'),
                    subtitle: const Text(
                      'Delete all locally stored notification history',
                    ),
                    onTap: () => _clearNotifications(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    key: const ValueKey('logout_and_wipe_tile'),
                    leading: const Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFFDC2626),
                    ),
                    title: const Text(
                      'Log Out and Wipe Data',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Clear WebView cookies, local databases, and reset app',
                    ),
                    onTap: () => _logoutAndWipeData(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PrivacyItemRow extends StatelessWidget {
  const _PrivacyItemRow({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
