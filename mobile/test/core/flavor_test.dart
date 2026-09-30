import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';

void main() {
  group('FlavorConfig', () {
    test('play flavor has correct title and disables self-update', () {
      final config = FlavorConfig.play();
      expect(config.flavor, AppFlavor.play);
      expect(config.isPlay, isTrue);
      expect(config.isSideload, isFalse);
      expect(config.canSelfUpdate, isFalse);
      expect(config.appTitle, 'ZeroScroll');
    });

    test('sideload flavor has correct title and enables self-update', () {
      final config = FlavorConfig.sideload();
      expect(config.flavor, AppFlavor.sideload);
      expect(config.isPlay, isFalse);
      expect(config.isSideload, isTrue);
      expect(config.canSelfUpdate, isTrue);
      expect(config.appTitle, 'ZeroScroll (Sideload)');
    });
  });
}
