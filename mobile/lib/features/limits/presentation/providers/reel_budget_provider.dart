import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/limits_repository.dart';
import '../../domain/reel_budget_service.dart';

/// Provider for [ReelBudgetService] dependency, backed by [limitsRepositoryProvider].
final reelBudgetServiceProvider = Provider<ReelBudgetService>((ref) {
  return ref.watch(limitsRepositoryProvider);
});

/// StateNotifier providing reactive updates for today's watched reels.
final todayReelCountProvider =
    StateNotifierProvider<TodayReelCountNotifier, int>((ref) {
      final service = ref.watch(reelBudgetServiceProvider);
      return TodayReelCountNotifier(service);
    });

class TodayReelCountNotifier extends StateNotifier<int> {
  TodayReelCountNotifier(this._service) : super(0) {
    loadCount();
  }

  final ReelBudgetService _service;

  Future<void> loadCount() async {
    state = await _service.getTodayReelCount();
  }

  Future<void> recordReelOpened() async {
    await _service.recordReelOpened();
    state = await _service.getTodayReelCount();
  }
}
