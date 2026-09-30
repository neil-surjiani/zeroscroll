import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/debug_models.dart';

class DebugLogState {
  const DebugLogState({
    this.blockedNavigations = const [],
    this.consoleLogs = const [],
    this.currentUrl,
    this.configVersion = 1,
  });

  final List<BlockedNavigationEntry> blockedNavigations;
  final List<ConsoleLogEntry> consoleLogs;
  final String? currentUrl;
  final int configVersion;

  DebugLogState copyWith({
    List<BlockedNavigationEntry>? blockedNavigations,
    List<ConsoleLogEntry>? consoleLogs,
    String? currentUrl,
    int? configVersion,
  }) {
    return DebugLogState(
      blockedNavigations: blockedNavigations ?? this.blockedNavigations,
      consoleLogs: consoleLogs ?? this.consoleLogs,
      currentUrl: currentUrl ?? this.currentUrl,
      configVersion: configVersion ?? this.configVersion,
    );
  }
}

class DebugLogNotifier extends StateNotifier<DebugLogState> {
  DebugLogNotifier() : super(const DebugLogState());

  void addBlockedNavigation(String path, String url) {
    final entry = BlockedNavigationEntry(
      timestamp: DateTime.now(),
      path: path,
      url: url,
    );
    final updated = [entry, ...state.blockedNavigations];
    if (updated.length > 50) {
      updated.removeRange(50, updated.length);
    }
    state = state.copyWith(blockedNavigations: updated);
  }

  void addConsoleLog(String message, String level) {
    final entry = ConsoleLogEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
    );
    final updated = [entry, ...state.consoleLogs];
    if (updated.length > 100) {
      updated.removeRange(100, updated.length);
    }
    state = state.copyWith(consoleLogs: updated);
  }

  void setCurrentUrl(String? url) {
    state = state.copyWith(currentUrl: url);
  }

  void setConfigVersion(int version) {
    state = state.copyWith(configVersion: version);
  }

  void clearLogs() {
    state = state.copyWith(blockedNavigations: const [], consoleLogs: const []);
  }

  String generateDebugReport() {
    final buffer = StringBuffer();
    buffer.writeln('# ZeroScroll Debug Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Active Config Version: ${state.configVersion}');
    buffer.writeln('Current Active URL: ${state.currentUrl ?? "None"}');
    buffer.writeln();

    buffer.writeln(
      '## Blocked Navigations (${state.blockedNavigations.length} items)',
    );
    if (state.blockedNavigations.isEmpty) {
      buffer.writeln('No blocked navigations recorded.');
    } else {
      for (final b in state.blockedNavigations) {
        buffer.writeln(
          '- [${b.timestamp.toIso8601String()}] Path: "${b.path}" | URL: "${b.url}"',
        );
      }
    }
    buffer.writeln();

    buffer.writeln(
      '## Live WebView Console Logs (${state.consoleLogs.length} items)',
    );
    if (state.consoleLogs.isEmpty) {
      buffer.writeln('No console logs recorded.');
    } else {
      for (final log in state.consoleLogs) {
        buffer.writeln(
          '- [${log.timestamp.toIso8601String()}] [${log.level.toUpperCase()}]: ${log.message}',
        );
      }
    }

    return buffer.toString();
  }
}

final debugLogProvider = StateNotifierProvider<DebugLogNotifier, DebugLogState>(
  (ref) {
    return DebugLogNotifier();
  },
);
