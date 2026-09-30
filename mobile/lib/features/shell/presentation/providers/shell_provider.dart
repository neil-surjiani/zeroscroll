import 'package:flutter_riverpod/flutter_riverpod.dart';
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
