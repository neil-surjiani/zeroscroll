import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_flavor.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../limits/presentation/screens/limits_screen.dart';
import '../../../limits/presentation/screens/stats_screen.dart';
import '../../../limits/presentation/widgets/deactivate_app_dialog.dart';
import '../../../security/data/security_repository.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../security/presentation/screens/debug_screen.dart';
import '../../../shell/domain/shell_tab.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../../../updater/domain/update_check_result.dart';
import '../../../updater/presentation/providers/updater_provider.dart';
import '../../../updater/presentation/widgets/update_download_dialog.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
import '../../domain/app_settings.dart';
import '../../domain/feature_preferences.dart';
import '../providers/feature_preferences_provider.dart';
import '../providers/settings_provider.dart';
import 'features_settings_screen.dart';

/// Provider tracking whether the developer settings section is unlocked.
final developerModeUnlockedProvider = StateProvider<bool>((ref) => false);

/// Comprehensive Settings screen organized into 7 distinct sections:
/// Account, Limits, Notifications, Security, Appearance, About, and Developer (hidden).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  DateTime? _lastVersionTapTime;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final featurePrefs = ref.watch(featurePreferencesProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final updaterState = flavor.canSelfUpdate ? ref.watch(updaterProvider) : null;
    final isDeveloperUnlocked = ref.watch(developerModeUnlockedProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Instagram-style Profile/Account Header Card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Logo in Instagram-style story gradient ring
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      theme.colorScheme.primary,
                      const Color(0xFF6AAA9E),
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primary,
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/logo_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.verified_user_rounded,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ZeroScroll',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Mindful Instagram Client',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Active Session • 100% Private',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 1. ACCOUNT SECTION
        _SectionHeader(title: 'Account', icon: Icons.person_outline_rounded),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Account Status'),
                subtitle: Text('Connected inside guarded container'),
                trailing: Icon(Icons.circle, color: Color(0xFF10B981), size: 12),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Refresh Session'),
                subtitle: const Text('Reload current web container'),
                onTap: () {
                  ref.read(webViewControllerProvider)?.reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reloading web container...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_logout_tile'),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFDC2626),
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Clears on-device cookies, cache, and session',
                ),
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. LIMITS & FOCUS SECTION
        _SectionHeader(title: 'Limits & Focus', icon: Icons.hourglass_top_rounded),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('settings_limits_tile'),
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Limits & Focus Schedules'),
                subtitle: const Text('Daily screen time, reel budgets, and focus blocks'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LimitsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_stats_tile'),
                leading: const Icon(Icons.insights_rounded),
                title: const Text('Intentional Usage Stats'),
                subtitle: const Text('View 7-day charts, streaks, and reels avoided'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_deactivate_app_tile'),
                leading: const Icon(Icons.lock_clock_rounded),
                title: const Text('Deactivate App (Hard Lock)'),
                subtitle: const Text('Lock ZeroScroll for hours or days with zero bypass'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => DeactivateAppDialog.show(context),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. STORIES & CONTENT SECTION
        _SectionHeader(title: 'Stories & Content', icon: Icons.amp_stories_outlined),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('settings_features_tile'),
                leading: const Icon(Icons.shield_outlined),
                title: const Text('All Features & Restrictions'),
                subtitle: const Text(
                  'Manage reels, stories, notification filtering & loosening delays',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FeaturesSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_stories_mode_tile'),
                leading: const Icon(Icons.amp_stories_outlined),
                title: const Text('Stories View Mode'),
                subtitle: Text(switch (featurePrefs.storiesViewMode) {
                  StoriesViewMode.off => 'Off (Blocked and hidden everywhere)',
                  StoriesViewMode.fromDmsOnly => 'From DMs Only (Direct links only)',
                  StoriesViewMode.fromFollowing => 'From Following (Story tray tab)',
                }),
                trailing: DropdownButton<StoriesViewMode>(
                  value: featurePrefs.storiesViewMode,
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
                      ref
                          .read(featurePreferencesProvider.notifier)
                          .updatePreferences(
                            featurePrefs.copyWith(storiesViewMode: newMode),
                          );
                    }
                  },
                ),
              ),
              if (featurePrefs.storiesViewMode != StoriesViewMode.off) ...[
                const Divider(),
                ListTile(
                  key: const ValueKey('settings_story_budget_tile'),
                  leading: const Icon(Icons.timelapse_outlined),
                  title: const Text('Daily Story Budget'),
                  subtitle: Text(
                    featurePrefs.dailyStoryLimit != null
                        ? '${featurePrefs.dailyStoryLimit} stories per day'
                        : 'Unlimited',
                  ),
                  trailing: DropdownButton<int?>(
                    value: featurePrefs.dailyStoryLimit,
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
                      ref
                          .read(featurePreferencesProvider.notifier)
                          .updatePreferences(
                            featurePrefs.copyWith(
                              dailyStoryLimit: newLimit,
                              clearDailyStoryLimit: newLimit == null,
                            ),
                          );
                    },
                  ),
                ),
              ],
              const Divider(),
              SwitchListTile(
                key: const ValueKey('settings_reels_from_dms_tile'),
                secondary: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Reels from DMs'),
                subtitle: const Text('Allow opening reels shared in message threads in single viewer mode'),
                value: featurePrefs.reelsFromDmsEnabled,
                onChanged: (val) {
                  ref
                      .read(featurePreferencesProvider.notifier)
                      .updatePreferences(
                        featurePrefs.copyWith(reelsFromDmsEnabled: val),
                      );
                },
              ),
              const Divider(),
              SwitchListTile(
                key: const ValueKey('settings_posts_from_dms_tile'),
                secondary: const Icon(Icons.image_outlined),
                title: const Text('Shared Posts from DMs'),
                subtitle: const Text('Allow opening feed posts shared in message threads'),
                value: featurePrefs.sharedPostsFromDmsEnabled,
                onChanged: (val) {
                  ref
                      .read(featurePreferencesProvider.notifier)
                      .updatePreferences(
                        featurePrefs.copyWith(sharedPostsFromDmsEnabled: val),
                      );
                },
              ),
              const Divider(),
              SwitchListTile(
                key: const ValueKey('settings_story_posting_tile'),
                secondary: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Story Posting'),
                subtitle: const Text(
                  'Enable story creation option (Requires external official app)',
                ),
                value: featurePrefs.storiesPostingEnabled,
                onChanged: (val) {
                  ref
                      .read(featurePreferencesProvider.notifier)
                      .updatePreferences(
                        featurePrefs.copyWith(storiesPostingEnabled: val),
                      );
                },
              ),
              if (featurePrefs.storiesPostingEnabled) ...[
                const Divider(),
                ListTile(
                  key: const ValueKey('settings_post_story_tile'),
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

        // 3. NOTIFICATIONS SECTION
        _SectionHeader(title: 'Notifications', icon: Icons.notifications_none_rounded),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.chat_bubble_outline_rounded),
                title: const Text('Direct Message Alerts'),
                subtitle: const Text('Show badges for unread conversation threads'),
                value: true,
                onChanged: (val) {
                  _showComingSoonSnackBar('Push notification integration');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.do_not_disturb_on_outlined),
                title: const Text('Quiet Hours'),
                subtitle: const Text('Mute notifications during focused time'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  _showComingSoonSnackBar('Quiet hours schedule');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. SECURITY SECTION
        _SectionHeader(title: 'Security', icon: Icons.shield_outlined),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                key: const ValueKey('settings_biometric_lock_tile'),
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Require App Lock'),
                subtitle: const Text('Biometrics or device credential on launch and timeout'),
                value: settings.biometricLockEnabled,
                onChanged: (value) async {
                  if (value) {
                    final authenticated =
                        await ref.read(securityRepositoryProvider).authenticate();
                    if (authenticated) {
                      await ref
                          .read(settingsNotifierProvider.notifier)
                          .updateSettings(settings.copyWith(biometricLockEnabled: true));
                      if (settings.blockScreenshotsEnabled) {
                        await ref.read(securityProvider.notifier).setSecureFlag(true);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('App lock verified and enabled.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Authentication cancelled. App lock remained off.'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  } else {
                    await ref
                        .read(settingsNotifierProvider.notifier)
                        .updateSettings(settings.copyWith(biometricLockEnabled: false));
                    await ref.read(securityProvider.notifier).setSecureFlag(false);
                  }
                },
              ),
              if (settings.biometricLockEnabled) ...[
                const Divider(),
                ListTile(
                  key: const ValueKey('settings_lock_timeout_tile'),
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Lock Timeout'),
                  subtitle: Text('Lock after background: ${settings.lockTimeout.label}'),
                  trailing: DropdownButton<LockTimeout>(
                    value: settings.lockTimeout,
                    underline: const SizedBox(),
                    items: LockTimeout.values.map((timeout) {
                      return DropdownMenuItem(
                        value: timeout,
                        child: Text(timeout.label),
                      );
                    }).toList(),
                    onChanged: (newTimeout) {
                      if (newTimeout != null) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .updateSettings(settings.copyWith(lockTimeout: newTimeout));
                      }
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  key: const ValueKey('settings_block_screenshots_tile'),
                  secondary: const Icon(Icons.screenshot_outlined),
                  title: const Text('Block Screenshots & Recents Preview'),
                  subtitle: const Text('Masks app in app switcher and blocks screen capture (FLAG_SECURE)'),
                  value: settings.blockScreenshotsEnabled,
                  onChanged: (value) async {
                    await ref
                        .read(settingsNotifierProvider.notifier)
                        .updateSettings(settings.copyWith(blockScreenshotsEnabled: value));
                    await ref.read(securityProvider.notifier).setSecureFlag(value);
                  },
                ),
              ],
              const Divider(),
              ListTile(
                key: const ValueKey('settings_privacy_details_tile'),
                leading: const Icon(Icons.lock_outline_rounded),
                title: const Text('On-Device Privacy & Storage'),
                subtitle: const Text('Zero telemetry, no remote servers. View details.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context.push('/privacy');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. APPEARANCE SECTION
        _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6_rounded),
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
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 6. ABOUT SECTION
        _SectionHeader(title: 'About', icon: Icons.info_outline_rounded),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('settings_version_tile'),
                leading: const Icon(Icons.verified_outlined),
                title: const Text(AppConstants.appName),
                subtitle: Text(
                  'Version 1.0.0 (Build 1) • ${flavor.flavor.name.toUpperCase()}',
                ),
                onTap: _handleVersionTap,
              ),
              if (flavor.canSelfUpdate) ...[
                const Divider(),
                ListTile(
                  key: const ValueKey('settings_check_updates_tile'),
                  leading: const Icon(Icons.system_update_rounded),
                  title: const Text('Check for Updates'),
                  subtitle: Text(switch (updaterState?.status) {
                    UpdaterStatus.checking => 'Checking for updates...',
                    UpdaterStatus.updateAvailable =>
                      'Update available (v${updaterState?.manifest?.latestVersion})',
                    UpdaterStatus.updateRequired =>
                      'Critical update required (v${updaterState?.manifest?.latestVersion})',
                    UpdaterStatus.downloading => 'Downloading update...',
                    _ => 'Tap to check for new releases',
                  }),
                  trailing: updaterState?.status == UpdaterStatus.checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    if (updaterState?.status == UpdaterStatus.updateAvailable ||
                        updaterState?.status == UpdaterStatus.updateRequired) {
                      UpdateDownloadDialog.show(context);
                      ref.read(updaterProvider.notifier).startDownloadAndInstall();
                      return;
                    }
                    final result = await ref
                        .read(updaterProvider.notifier)
                        .checkForUpdate(force: true);
                    if (!context.mounted) return;
                    if (result.status == UpdateCheckStatus.noUpdate) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ZeroScroll is up to date!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (result.status == UpdateCheckStatus.error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.errorMessage ?? 'Update check failed.'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else if (result.hasUpdate) {
                      UpdateDownloadDialog.show(context);
                      ref.read(updaterProvider.notifier).startDownloadAndInstall();
                    }
                  },
                ),
              ],
              if (flavor.isPlay) ...[
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.storefront_outlined),
                  title: Text('Google Play Release'),
                  subtitle: Text('Updates are managed automatically by Google Play'),
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Open Source Licenses'),
                subtitle: const Text('Third-party software notices and licenses'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: 'v1.0.0',
                  );
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_privacy_policy_tile'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy & Data Security'),
                subtitle: const Text('Zero telemetry, zero external servers'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context.push('/privacy');
                },
              ),
              const Divider(),
              ListTile(
                key: const ValueKey('settings_welcome_guide_tile'),
                leading: const Icon(Icons.school_outlined),
                title: const Text('Welcome Guide'),
                subtitle: const Text('Review setup steps and permissions guide'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  context.push('/onboarding');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Required Legal Disclaimer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.gavel_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Not affiliated with or endorsed by Meta or Instagram. ZeroScroll is an independent utility designed for intentional communication without algorithmic discovery.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 7. DEVELOPER SECTION (Hidden until unlocked via 7 taps)
        if (isDeveloperUnlocked) ...[
          const SizedBox(height: 24),
          _SectionHeader(title: 'Developer Options', icon: Icons.bug_report_outlined),
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.terminal_rounded),
                  title: const Text('Developer Diagnostics'),
                  subtitle: const Text('View blocked routes, console logs, and reports'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebugScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  key: const ValueKey('settings_probe_posting_tile'),
                  leading: const Icon(Icons.radar_outlined),
                  title: const Text('Probe Posting Capability'),
                  subtitle: const Text('Test web media input and camera support'),
                  onTap: () => _probePostingCapability(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Hide Developer Options'),
                  onTap: () {
                    ref.read(developerModeUnlockedProvider.notifier).state = false;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Developer options hidden.'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be fully configurable in upcoming build.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
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
            key: const ValueKey('confirm_logout_button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
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

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastVersionTapTime == null ||
        now.difference(_lastVersionTapTime!) > const Duration(seconds: 2)) {
      _versionTapCount = 1;
    } else {
      _versionTapCount++;
    }
    _lastVersionTapTime = now;

    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      ref.read(developerModeUnlockedProvider.notifier).state = true;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Developer Options unlocked! Scroll down to view.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_versionTapCount >= 4) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are ${7 - _versionTapCount} steps away from Developer Options.',
          ),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePostStory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('External App Handoff'),
        content: const Text(
          'ZeroScroll cannot verify official app behavior outside this sandbox.\n\nWould you like to open the official app or camera to post a story?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm_post_story_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Official App'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final instagramCameraUri = Uri.parse('instagram://story-camera');
        if (await canLaunchUrl(instagramCameraUri)) {
          await launchUrl(instagramCameraUri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}

      try {
        final webFallbackUri = Uri.parse('https://www.instagram.com/stories/create/');
        if (await canLaunchUrl(webFallbackUri)) {
          await launchUrl(webFallbackUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
  }

  Future<void> _probePostingCapability(BuildContext context) async {
    final controller = ref.read(webViewControllerProvider);
    final buffer = StringBuffer('=== Story Posting Capability Probe ===\n');

    if (controller == null) {
      buffer.writeln('WebViewController is not currently attached.');
    } else {
      try {
        final probeResult = await controller.evaluateJs(
          '''
            (function() {
              var results = {};
              results.hasMediaDevices = !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
              results.hasFileInput = !!document.querySelector("input[type='file']");
              results.hasCaptureSupport = 'capture' in document.createElement('input');
              results.cookieEnabled = navigator.cookieEnabled;
              results.userAgent = navigator.userAgent;
              return JSON.stringify(results);
            })();
          ''',
        );
        buffer.writeln('Mobile Web Capabilities:\n$probeResult');
      } catch (e) {
        buffer.writeln('JS Probe Error: $e');
      }
    }

    final report = buffer.toString();
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Posting Capability Probe'),
          content: SingleChildScrollView(
            child: Text(
              report,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: report));
                Navigator.of(ctx).pop();
              },
              child: const Text('Copy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
