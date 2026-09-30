import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../domain/shell_tab.dart';

/// Riverpod state notifier for active shell tab.
class ShellTabNotifier extends StateNotifier<ShellTab> {
  ShellTabNotifier() : super(ShellTab.messages);

  void selectTab(ShellTab tab) {
    state = tab;
  }
}

final activeShellTabProvider =
    StateNotifierProvider<ShellTabNotifier, ShellTab>((ref) {
      return ShellTabNotifier();
    });

/// Provider for unread message badge count on Messages tab, reflecting live captured DMs.
final unreadMessagesCountProvider = Provider<int>((ref) {
  return ref.watch(unreadDmCountProvider);
});

/// Provider controlling whether the top slim stats bar is collapsed.
final statsBarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Provider tracking active time in app today in minutes (placeholder, fed by Prompt 7).
final todayUsageMinutesProvider = StateProvider<int>((ref) => 14);
