import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/features/limits/data/stub_reel_budget_service.dart';

void main() {
  group('ReelBudgetService (Stub)', () {
    test('allows opening reels unconditionally by default', () async {
      final service = StubReelBudgetService();
      expect(await service.canOpenReel(), isTrue);
      expect(await service.getTodayReelCount(), 0);
    });

    test('increments daily count on recordReelOpened', () async {
      final service = StubReelBudgetService();
      await service.recordReelOpened();
      await service.recordReelOpened();
      expect(await service.getTodayReelCount(), 2);
      expect(await service.canOpenReel(), isTrue);
    });

    test('enforces budget limit when set', () async {
      final service = StubReelBudgetService(budgetLimit: 2);
      expect(await service.canOpenReel(), isTrue);
      await service.recordReelOpened();
      expect(await service.canOpenReel(), isTrue);
      await service.recordReelOpened();
      expect(await service.canOpenReel(), isFalse);
    });

    test('resets daily count properly', () async {
      final service = StubReelBudgetService(budgetLimit: 1);
      await service.recordReelOpened();
      expect(await service.canOpenReel(), isFalse);
      service.reset();
      expect(await service.getTodayReelCount(), 0);
      expect(await service.canOpenReel(), isTrue);
    });
  });
}
