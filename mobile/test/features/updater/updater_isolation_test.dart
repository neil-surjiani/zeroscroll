import 'package:flutter_test/flutter_test.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/updater/data/updater_repository.dart';

void main() {
  group('Updater Flavor Isolation', () {
    test('Play flavor updater repository returns null update', () async {
      final repo = SideloadUpdaterRepository(flavorConfig: FlavorConfig.play());
      final result = await repo.checkForUpdate();
      expect(result, isNull);
    });

    test('Sideload flavor allows update check', () async {
      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
      );
      final result = await repo.checkForUpdate();
      // Initially returns null (placeholder until version.json is configured)
      expect(result, isNull);
    });
  });
}
