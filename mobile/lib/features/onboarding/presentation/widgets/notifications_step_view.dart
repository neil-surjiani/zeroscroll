import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/data/notifications_repository.dart';

/// Step 3: Notification access setup, handling Android 13+ restricted settings,
/// POST_NOTIFICATIONS runtime permission, and battery optimization guidance.
class NotificationsStepView extends ConsumerStatefulWidget {
  const NotificationsStepView({super.key});

  @override
  ConsumerState<NotificationsStepView> createState() =>
      NotificationsStepViewState();
}

class NotificationsStepViewState extends ConsumerState<NotificationsStepView> {
  bool _isLoading = true;
  bool _isListenerEnabled = false;
  bool _isPostNotificationsGranted = true;
  bool _isBatteryIgnored = true;
  int _sdkVersion = 33;
  bool _showRestrictedSettingsGuide = false;

  @override
  void initState() {
    super.initState();
    refreshStatus();
  }

  /// Refreshes all notification and system permissions.
  Future<void> refreshStatus() async {
    final repo = ref.read(notificationsRepositoryProvider);
    final listener = await repo.isListenerEnabled();
    final postNotif = await repo.isPostNotificationsGranted();
    final battery = await repo.isBatteryOptimizationIgnored();
    final sdk = await repo.getAndroidSdkVersion();

    if (mounted) {
      setState(() {
        _isListenerEnabled = listener;
        _isPostNotificationsGranted = postNotif;
        _isBatteryIgnored = battery;
        _sdkVersion = sdk;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.read(notificationsRepositoryProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Stay Updated, Calmly',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'ZeroScroll captures incoming direct messages directly on your device so you receive timely alerts without opening the feed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Required Instagram App Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Requirement: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              'This feature requires the official Instagram app installed with its notifications enabled so ZeroScroll can safely relay message alerts to you.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary: Notification Listener Access Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isListenerEnabled
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isListenerEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isListenerEnabled
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isListenerEnabled
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notification Listener Access',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _isListenerEnabled
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isListenerEnabled ? 'Enabled' : 'Needed',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _isListenerEnabled
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Allows ZeroScroll to detect incoming chats entirely on-device and update your unread inbox counter.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('open_listener_settings_btn'),
                    onPressed: () async {
                      await repo.openListenerSettings();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: Text(
                      _isListenerEnabled
                          ? 'Modify Listener Settings'
                          : 'Enable Notification Access',
                    ),
                  ),
                ),

                // Android 13+ Sideload Restricted Settings Guide
                if (!_isListenerEnabled && _sdkVersion >= 33) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    key: const ValueKey('toggle_restricted_guide_btn'),
                    onTap: () {
                      setState(() {
                        _showRestrictedSettingsGuide =
                            !_showRestrictedSettingsGuide;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Can\'t turn it on? Android 13+ Help',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            _showRestrictedSettingsGuide
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showRestrictedSettingsGuide) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Android 13+ Restricts Sideloaded Apps:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _GuideStepRow(
                            stepNumber: '1',
                            text: 'Tap "Open App Info" below',
                          ),
                          _GuideStepRow(
                            stepNumber: '2',
                            text:
                                'Tap the top-right three dots menu (⋮)',
                          ),
                          _GuideStepRow(
                            stepNumber: '3',
                            text:
                                'Select "Allow restricted settings" and unlock device',
                          ),
                          _GuideStepRow(
                            stepNumber: '4',
                            text:
                                'Return here and tap "Enable Notification Access"',
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('open_app_info_btn'),
                              onPressed: () async {
                                await repo.openAppInfoSettings();
                              },
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Open App Info'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // POST_NOTIFICATIONS Permission (Android 13+)
          if (_sdkVersion >= 33) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPostNotificationsGranted
                        ? Icons.check_circle_rounded
                        : Icons.notifications_off_outlined,
                    color: _isPostNotificationsGranted
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Notification Alert',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Permit ZeroScroll to show native banners',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isPostNotificationsGranted)
                    TextButton(
                      key: const ValueKey('request_post_notif_btn'),
                      onPressed: () async {
                        await repo.requestPostNotificationsPermission();
                        await refreshStatus();
                      },
                      child: const Text('Allow'),
                    )
                  else
                    const Icon(
                      Icons.check,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Battery Optimization Guidance (Optional)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.battery_saver_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Background Reliability (Optional)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isBatteryIgnored)
                      const Text(
                        'Optimized',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Some Android phones aggressively sleep background listeners. Disabling battery optimization ensures you never miss a message alert.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const ValueKey('battery_optimization_btn'),
                    onPressed: () async {
                      await repo.openBatteryOptimizationSettings();
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Battery Settings'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStepRow extends StatelessWidget {
  const _GuideStepRow({required this.stepNumber, required this.text});

  final String stepNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
