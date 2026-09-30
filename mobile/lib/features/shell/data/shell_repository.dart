import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/shell_tab.dart';

/// Repository contract for persisting shell preferences (e.g., last active tab).
abstract class ShellRepository {
  Future<ShellTab> getLastActiveTab();
  Future<void> setLastActiveTab(ShellTab tab);
}

/// In-memory repository implementation for the shell feature.
class InMemoryShellRepository implements ShellRepository {
  ShellTab _currentTab = ShellTab.messages;

  @override
  Future<ShellTab> getLastActiveTab() async => _currentTab;

  @override
  Future<void> setLastActiveTab(ShellTab tab) async {
    _currentTab = tab;
  }
}

final shellRepositoryProvider = Provider<ShellRepository>((ref) {
  return InMemoryShellRepository();
});
