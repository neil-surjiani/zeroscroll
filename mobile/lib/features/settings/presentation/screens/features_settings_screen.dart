import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/feature_loosening_checker.dart';
import '../../domain/feature_preferences.dart';
import '../providers/feature_preferences_provider.dart';
import '../widgets/loosening_confirmation_dialog.dart';

/// Screen managing mindful feature toggles, content restrictions, daily budgets,
/// and intentional friction delays.
class FeaturesSettingsScreen extends ConsumerWidget {
  const FeaturesSettingsScreen({super.key});

  void _applyChange({
    required BuildContext context,
    required WidgetRef ref,
    required FeaturePreferences current,
    required FeaturePreferences target,
  }) {
    final isLoosening = FeatureLooseningChecker.isLoosening(
      current: current,
      target: target,
    );

    if (!isLoosening) {
      // Tightening applies immediately
      ref.read(featurePreferencesProvider.notifier).updatePreferences(target);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restriction tightened immediately.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Loosening requires confirmation modal & 10-second wait
    final descriptions = FeatureLooseningChecker.describeLooseningChanges(
      current: current,
      target: target,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LooseningConfirmationDialog(
        title: 'Loosen Restriction?',
        descriptions: descriptions,
        is24hDelayActive: current.delayLoosening24h,
        onConfirmed: () async {
          if (current.delayLoosening24h) {
            await ref
                .read(featurePreferencesProvider.notifier)
                .scheduleLoosening(target);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Change scheduled. It will take effect in 24 hours.',
                  ),
                  duration: Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            await ref
                .read(featurePreferencesProvider.notifier)
                .updatePreferences(target);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restrictions updated.'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _handlePostStory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('External App Handoff'),
          ],
        ),
        content: const Text(
          'Posting stories is not supported inside the ZeroScroll sandbox. '
          'ZeroScroll will open the device camera or official app to create your story.\n\n'
          'ZeroScroll cannot verify official app behavior outside this sandbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const ValueKey('confirm_post_story_button'),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Proceed to External App'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse('instagram://camera');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                final fallbackUri =
                    Uri.parse('https://www.instagram.com/create/story/');
                await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(featurePreferencesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Features & Restrictions'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Pending Loosening Banner (if active)
          if (prefs.hasPendingLoosening) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduled Loosening in Progress',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your requested changes will unlock on ${prefs.pendingLooseningReleaseTime?.toLocal().toString().split(".")[0]}.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    key: const ValueKey('cancel_pending_loosening_btn'),
                    onPressed: () {
                      ref
                          .read(featurePreferencesProvider.notifier)
                          .cancelPendingLoosening();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pending loosening cancelled.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Cancel Pending Changes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Intentional Friction: 24h Delay Toggle
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: SwitchListTile(
              key: const ValueKey('features_delay_loosening_switch'),
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Delay loosening for 24 hours'),
              subtitle: const Text(
                'When enabled, any action that loosens restrictions will wait 24 hours before taking effect.',
              ),
              value: prefs.delayLoosening24h,
              onChanged: (val) {
                // Toggling 24h delay on is tightening, toggling off is loosening!
                final target = prefs.copyWith(delayLoosening24h: val);
                if (!val) {
                  // Turning delay OFF is loosening
                  _applyChange(
                    context: context,
                    ref: ref,
                    current: prefs,
                    target: target,
                  );
                } else {
                  // Turning delay ON is tightening (applies immediately)
                  ref
                      .read(featurePreferencesProvider.notifier)
                      .setDelayLoosening24h(true);
                }
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Reels Section
          _SectionHeader(title: 'Reels', icon: Icons.play_circle_outline_rounded),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  key: const ValueKey('features_reels_switch'),
                  secondary: const Icon(Icons.play_circle_outline_rounded),
                  title: const Text('Reels from DMs'),
                  subtitle: const Text(
                    'Allow opening single reels shared in DM threads. Feed and Explore tabs remain blocked.',
                  ),
                  value: prefs.reelsFromDmsEnabled,
                  onChanged: (val) {
                    final target = prefs.copyWith(reelsFromDmsEnabled: val);
                    _applyChange(
                      context: context,
                      ref: ref,
                      current: prefs,
                      target: target,
                    );
                  },
                ),
                if (prefs.reelsFromDmsEnabled) ...[
                  const Divider(),
                  ListTile(
                    key: const ValueKey('features_reels_budget_tile'),
                    leading: const Icon(Icons.timelapse_outlined),
                    title: const Text('Daily Reel Budget'),
                    subtitle: Text(
                      prefs.dailyReelLimit != null
                          ? '${prefs.dailyReelLimit} reels allowed per day'
                          : 'Unlimited',
                    ),
                    trailing: DropdownButton<int?>(
                      key: const ValueKey('features_reels_budget_dropdown'),
                      value: prefs.dailyReelLimit,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 3, child: Text('3 (Default)')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: null, child: Text('Unlimited')),
                      ],
                      onChanged: (newLimit) {
                        final target = prefs.copyWith(
                          dailyReelLimit: newLimit,
                          clearDailyReelLimit: newLimit == null,
                        );
                        _applyChange(
                          context: context,
                          ref: ref,
                          current: prefs,
                          target: target,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Stories Section
          _SectionHeader(title: 'Stories', icon: Icons.amp_stories_outlined),
          Card(
            child: Column(
              children: [
                ListTile(
                  key: const ValueKey('features_stories_mode_tile'),
                  leading: const Icon(Icons.amp_stories_outlined),
                  title: const Text('Stories View Mode'),
                  subtitle: Text(switch (prefs.storiesViewMode) {
                    StoriesViewMode.off => 'Off (Blocked and hidden everywhere)',
                    StoriesViewMode.fromDmsOnly => 'From DMs Only (Direct links only)',
                    StoriesViewMode.fromFollowing => 'From Following (Stories tab)',
                  }),
                  trailing: DropdownButton<StoriesViewMode>(
                    key: const ValueKey('features_stories_mode_dropdown'),
                    value: prefs.storiesViewMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: StoriesViewMode.off,
                        child: Text('Off'),
                      ),
                      DropdownMenuItem(
                        value: StoriesViewMode.fromDmsOnly,
                        child: Text('From DMs Only'),
                      ),
                      DropdownMenuItem(
                        value: StoriesViewMode.fromFollowing,
                        child: Text('From Following'),
                      ),
                    ],
                    onChanged: (newMode) {
                      if (newMode != null) {
                        final target = prefs.copyWith(storiesViewMode: newMode);
                        _applyChange(
                          context: context,
                          ref: ref,
                          current: prefs,
                          target: target,
                        );
                      }
                    },
                  ),
                ),
                if (prefs.storiesViewMode != StoriesViewMode.off) ...[
                  const Divider(),
                  ListTile(
                    key: const ValueKey('features_stories_budget_tile'),
                    leading: const Icon(Icons.timelapse_outlined),
                    title: const Text('Daily Story Budget'),
                    subtitle: Text(
                      prefs.dailyStoryLimit != null
                          ? '${prefs.dailyStoryLimit} stories allowed per day'
                          : 'Unlimited',
                    ),
                    trailing: DropdownButton<int?>(
                      key: const ValueKey('features_stories_budget_dropdown'),
                      value: prefs.dailyStoryLimit,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 10, child: Text('10 (Default)')),
                        DropdownMenuItem(value: 20, child: Text('20')),
                        DropdownMenuItem(value: 30, child: Text('30')),
                        DropdownMenuItem(value: null, child: Text('Unlimited')),
                      ],
                      onChanged: (newLimit) {
                        final target = prefs.copyWith(
                          dailyStoryLimit: newLimit,
                          clearDailyStoryLimit: newLimit == null,
                        );
                        _applyChange(
                          context: context,
                          ref: ref,
                          current: prefs,
                          target: target,
                        );
                      },
                    ),
                  ),
                ],
                const Divider(),
                SwitchListTile(
                  key: const ValueKey('features_stories_posting_switch'),
                  secondary: const Icon(Icons.add_photo_alternate_outlined),
                  title: const Text('Story Posting'),
                  subtitle: const Text(
                    'Enable story creation entry point (Requires external official app handoff)',
                  ),
                  value: prefs.storiesPostingEnabled,
                  onChanged: (val) {
                    final target = prefs.copyWith(storiesPostingEnabled: val);
                    _applyChange(
                      context: context,
                      ref: ref,
                      current: prefs,
                      target: target,
                    );
                  },
                ),
                if (prefs.storiesPostingEnabled) ...[
                  const Divider(),
                  ListTile(
                    key: const ValueKey('features_post_story_tile'),
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Post Story'),
                    subtitle: const Text('Launch external app or camera fallback'),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () => _handlePostStory(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Shared Posts Section
          _SectionHeader(title: 'Shared Feed Posts', icon: Icons.image_outlined),
          Card(
            child: SwitchListTile(
              key: const ValueKey('features_shared_posts_switch'),
              secondary: const Icon(Icons.image_outlined),
              title: const Text('Shared Posts from DMs'),
              subtitle: const Text(
                'Allow opening single feed posts shared in message threads.',
              ),
              value: prefs.sharedPostsFromDmsEnabled,
              onChanged: (val) {
                final target = prefs.copyWith(sharedPostsFromDmsEnabled: val);
                _applyChange(
                  context: context,
                  ref: ref,
                  current: prefs,
                  target: target,
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 6. Notifications Section
          _SectionHeader(title: 'Notifications Filter', icon: Icons.notifications_none_rounded),
          Card(
            child: ListTile(
              key: const ValueKey('features_notifications_tile'),
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Captured Notifications'),
              subtitle: Text(
                prefs.messagesOnlyNotifications
                    ? 'Messages only (Likes, comments, and follows filtered out)'
                    : 'Messages and activity',
              ),
              trailing: DropdownButton<bool>(
                key: const ValueKey('features_notifications_dropdown'),
                value: prefs.messagesOnlyNotifications,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('Messages only'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('Messages & activity'),
                  ),
                ],
                onChanged: (messagesOnly) {
                  if (messagesOnly != null) {
                    final target = prefs.copyWith(
                      messagesOnlyNotifications: messagesOnly,
                    );
                    _applyChange(
                      context: context,
                      ref: ref,
                      current: prefs,
                      target: target,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
