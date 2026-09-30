import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/usage_limit.dart';

/// Repository contract for managing usage limits.
abstract class LimitsRepository {
  Future<UsageLimit> getUsageLimit();
  Future<void> saveUsageLimit(UsageLimit limit);
  Future<void> incrementUsage(int minutes);
}

/// In-memory implementation of [LimitsRepository].
class LocalLimitsRepository implements LimitsRepository {
  UsageLimit _limit = const UsageLimit(
    dailyLimitMinutes: 30,
    currentUsageMinutes: 0,
    isLimitEnabled: false,
  );

  @override
  Future<UsageLimit> getUsageLimit() async => _limit;

  @override
  Future<void> saveUsageLimit(UsageLimit limit) async {
    _limit = limit;
  }

  @override
  Future<void> incrementUsage(int minutes) async {
    _limit = _limit.copyWith(
      currentUsageMinutes: _limit.currentUsageMinutes + minutes,
    );
  }
}

final limitsRepositoryProvider = Provider<LimitsRepository>((ref) {
  return LocalLimitsRepository();
});
