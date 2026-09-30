import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/limits_repository.dart';
import '../../domain/usage_limit.dart';

class LimitsNotifier extends StateNotifier<AsyncValue<UsageLimit>> {
  LimitsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final LimitsRepository _repository;

  Future<void> _load() async {
    try {
      final limit = await _repository.getUsageLimit();
      state = AsyncValue.data(limit);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLimit(UsageLimit limit) async {
    await _repository.saveUsageLimit(limit);
    state = AsyncValue.data(limit);
  }
}

final limitsProvider =
    StateNotifierProvider<LimitsNotifier, AsyncValue<UsageLimit>>((ref) {
      final repo = ref.watch(limitsRepositoryProvider);
      return LimitsNotifier(repo);
    });
