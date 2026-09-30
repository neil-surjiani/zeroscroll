import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_flavor.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../limits/domain/limits_status.dart';
import '../../../limits/presentation/providers/app_lifecycle_tracker.dart';
import '../../../limits/presentation/providers/limits_state_provider.dart';
import '../../../limits/presentation/widgets/deactivated_overlay.dart';
import '../../../limits/presentation/widgets/done_for_today_overlay.dart';
import '../../../limits/presentation/widgets/focus_locked_overlay.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../onboarding/data/onboarding_repository.dart';
import '../../../security/presentation/providers/security_provider.dart';
import '../../../security/presentation/screens/app_lock_screen.dart';
import '../../../settings/data/feature_preferences_repository.dart';
import '../../../settings/domain/feature_preferences.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../stories/presentation/screens/stories_tray_screen.dart';
import '../../../updater/presentation/providers/updater_provider.dart';
import '../../../updater/presentation/screens/blocking_update_screen.dart';
import '../../../updater/presentation/widgets/update_available_card.dart';
import '../../../webview/presentation/providers/webview_controller_provider.dart';
import '../../../webview/presentation/providers/webview_provider.dart';
import '../../../webview/presentation/widgets/webview_container.dart';
import '../../domain/shell_tab.dart';
import '../providers/shell_provider.dart';
import '../widgets/slim_stats_bar.dart';

/// Main Shell container with 3-tab navigation, collapsible top stats bar,
/// unread badge notification support, persistent IndexedStack, and limits lock enforcement.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(appLifecycleTrackerProvider).init();
      final completed =
          await ref.read(onboardingRepositoryProvider).isOnboardingCompleted();
      if (!completed && mounted) {
        context.push('/onboarding');
      } else if (mounted) {
        // One-time prompt for existing installs to choose features
        final prefs =
            await ref.read(featurePreferencesRepositoryProvider).getPreferences();
        if (!prefs.hasChosenFeatures && mounted) {
          context.push('/features/choose');
        }
        final flavor = ref.read(flavorConfigProvider);
        if (flavor.canSelfUpdate) {
          ref.read(updaterProvider.notifier).checkForUpdate();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsNotifierProvider);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(securityProvider.notifier).onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(securityProvider.notifier).checkTimeoutAndLock(
            biometricLockEnabled: settings.biometricLockEnabled,
            lockTimeout: settings.lockTimeout,
          );
      ref
          .read(featurePreferencesProvider.notifier)
          .checkAndApplyPendingLoosening();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 0. App Lock (local_auth): must be shown before any WebView content is visible
    final securityStatus = ref.watch(securityProvider);
    if (securityStatus.isAppLocked) {
      return const AppLockScreen();
    }

    final flavor = ref.watch(flavorConfigProvider);

    // 0.1 Blocking mandatory update screen (if current build < minSupportedBuild on sideload)
    if (flavor.canSelfUpdate) {
      final updaterState = ref.watch(updaterProvider);
      if (updaterState.isMandatory) {
        return const BlockingUpdateScreen();
      }
    }

    // 1. Check if an active focus schedule, daily limit, or hard deactivation locks the app
    final limitsStatus = ref.watch(activeLimitsStatusProvider);
    if (limitsStatus is DeactivatedStatus) {
      return DeactivatedOverlay(deactivatedUntil: limitsStatus.deactivatedUntil);
    }
    if (limitsStatus is FocusLockedStatus) {
      return FocusLockedOverlay(schedule: limitsStatus.schedule);
    }
    if (limitsStatus is DoneForTodayStatus) {
      return DoneForTodayOverlay(status: limitsStatus);
    }

    final activeTab = ref.watch(activeShellTabProvider);
    final unreadCount = ref.watch(unreadMessagesCountProvider);
    final webviewState = ref.watch(webviewNotifierProvider);
    final featurePrefs = ref.watch(featurePreferencesProvider);
    final theme = Theme.of(context);

    final showStoriesTab =
        featurePrefs.storiesViewMode == StoriesViewMode.fromFollowing;
    final availableTabs = [
      ShellTab.messages,
      ShellTab.notifications,
      if (showStoriesTab) ShellTab.stories,
      ShellTab.settings,
    ];

    final safeTab =
        availableTabs.contains(activeTab) ? activeTab : ShellTab.messages;
    final selectedIndex = availableTabs.indexOf(safeTab);

    // Full-screen media isolation: hide bars when viewing a single reel/media or story
    final isViewerActive =
        (safeTab == ShellTab.messages || safeTab == ShellTab.stories) &&
        webviewState.isViewerMode;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: isViewerActive
          ? null
          : AppBar(
              titleSpacing: 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ZeroScroll',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: flavor.isSideload
                          ? Colors.amber.shade800.withValues(alpha: 0.15)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: flavor.isSideload
                            ? Colors.amber.shade800.withValues(alpha: 0.4)
                            : theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      flavor.flavor.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child: Container(
                  color: theme.colorScheme.outlineVariant,
                  height: 0.5,
                ),
              ),
              actions: [
                if (safeTab == ShellTab.messages)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Reload Messages',
                    onPressed: () {
                      ref.read(webViewControllerProvider)?.reload();
                    },
                  ),
              ],
            ),
      body: SafeArea(
        top: !isViewerActive,
        bottom: !isViewerActive,
        child: Column(
          children: [
            // Top Area: Slim ZeroScroll stats bar (collapsible)
            if (!isViewerActive) const SlimStatsBar(),

            // Sideload update banner
            if (flavor.canSelfUpdate && !isViewerActive)
              const UpdateAvailableCard(),

            // Persistent IndexedStack for the tabs
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  const WebviewContainer(),
                  const NotificationsScreen(),
                  if (showStoriesTab) const StoriesTrayScreen(),
                  const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isViewerActive
          ? null
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  ref
                      .read(activeShellTabProvider.notifier)
                      .selectTab(availableTabs[index]);
                },
                destinations: [
                  // Tab 0: Messages with unread badge (no red badges except unread counts)
                  NavigationDestination(
                    icon: unreadCount > 0
                        ? Badge.count(
                            count: unreadCount,
                            backgroundColor: AppTheme.unreadBadgeColor,
                            child: const Icon(Icons.chat_bubble_outline_rounded),
                          )
                        : const Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: unreadCount > 0
                        ? Badge.count(
                            count: unreadCount,
                            backgroundColor: AppTheme.unreadBadgeColor,
                            child: const Icon(Icons.chat_bubble_rounded),
                          )
                        : const Icon(Icons.chat_bubble_rounded),
                    label: 'Messages',
                    tooltip: unreadCount > 0
                        ? 'Direct Messages ($unreadCount unread)'
                        : 'Direct Messages',
                  ),

                  // Tab 1: Notifications & Activity
                  const NavigationDestination(
                    icon: Icon(Icons.notifications_none_rounded),
                    selectedIcon: Icon(Icons.notifications_rounded),
                    label: 'Activity',
                    tooltip: 'Activity and Notifications',
                  ),

                  // Dynamic 4th tab: Stories (only when fromFollowing mode is enabled)
                  if (showStoriesTab)
                    const NavigationDestination(
                      icon: Icon(Icons.amp_stories_outlined),
                      selectedIcon: Icon(Icons.amp_stories_rounded),
                      label: 'Stories',
                      tooltip: 'Stories from Following',
                    ),

                  // Tab: Settings
                  const NavigationDestination(
                    icon: Icon(Icons.tune_rounded),
                    selectedIcon: Icon(Icons.tune_rounded),
                    label: 'Settings',
                    tooltip: 'Settings and Limits',
                  ),
                ],
              ),
            ),
    );
  }
}
