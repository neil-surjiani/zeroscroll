import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shell/presentation/providers/shell_provider.dart';
import '../../data/limits_repository.dart';
import 'limits_state_provider.dart';

/// Observer that tracks active foreground screen time across lifecycle events
/// and handles sudden app kills or crashes gracefully.
class AppLifecycleTracker with WidgetsBindingObserver {
  AppLifecycleTracker(this._ref) : _repository = _ref.read(limitsRepositoryProvider);

  final Ref _ref;
  final LimitsRepository _repository;
  int? _currentSessionId;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  /// Initializes lifecycle observation and performs crash recovery.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);

    // Crash recovery: close any sessions left open from an abrupt app termination
    final now = DateTime.now();
    await _repository.closeOpenSessions(now);

    // If app is currently foreground, start a fresh session
    final initialLifecycle = WidgetsBinding.instance.lifecycleState;
    if (initialLifecycle == null || initialLifecycle == AppLifecycleState.resumed) {
      await _onAppForeground();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppForeground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _onAppBackground();
        break;
    }
  }

  Future<void> _onAppForeground() async {
    if (_currentSessionId != null) return;

    final now = DateTime.now();
    _currentSessionId = await _repository.startSession(now);

    // Update stats immediately
    await _refreshStats();

    // Periodic heartbeat every 20 seconds to guarantee crash safety
    // and keep the top stats bar live.
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_currentSessionId != null) {
        final tickTime = DateTime.now();
        await _repository.endSession(_currentSessionId!, tickTime);
        await _refreshStats();
      }
    });
  }

  Future<void> _onAppBackground() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    if (_currentSessionId != null) {
      final now = DateTime.now();
      await _repository.endSession(_currentSessionId!, now);
      _currentSessionId = null;
    }

    await _refreshStats();
  }

  Future<void> _refreshStats() async {
    try {
      final todayMinutes = await _repository.getTodayUsageMinutes();
      _ref.read(todayUsageMinutesProvider.notifier).state = todayMinutes;
      // Invalidate stats provider for reactive listeners
      _ref.invalidate(usageStatsProvider);
    } catch (_) {}
  }

  /// Cleans up listeners and finishes open sessions.
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    try {
      await _onAppBackground();
    } catch (_) {}
    _isInitialized = false;
  }
}

/// Provider for [AppLifecycleTracker].
final appLifecycleTrackerProvider = Provider<AppLifecycleTracker>((ref) {
  final tracker = AppLifecycleTracker(ref);
  ref.onDispose(() => tracker.dispose());
  return tracker;
});
