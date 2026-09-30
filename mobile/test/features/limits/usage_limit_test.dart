import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/domain/usage_limit.dart';

void main() {
  group('UsageLimit', () {
    test('calculates limit exceeded properly', () {
      const limit = UsageLimit(
        dailyLimitMinutes: 30,
        currentUsageMinutes: 35,
        isLimitEnabled: true,
      );
      expect(limit.isLimitExceeded, isTrue);
      expect(limit.remainingMinutes, 0);
    });

    test('calculates remaining minutes properly when under limit', () {
      const limit = UsageLimit(
        dailyLimitMinutes: 30,
        currentUsageMinutes: 10,
        isLimitEnabled: true,
      );
      expect(limit.isLimitExceeded, isFalse);
      expect(limit.remainingMinutes, 20);
    });

    test('returns -1 remaining minutes when disabled', () {
      const limit = UsageLimit(
        dailyLimitMinutes: 30,
        currentUsageMinutes: 50,
        isLimitEnabled: false,
      );
      expect(limit.isLimitExceeded, isFalse);
      expect(limit.remainingMinutes, -1);
    });
  });
}
