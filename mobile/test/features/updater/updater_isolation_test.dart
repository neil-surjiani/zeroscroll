import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeroscroll/core/config/app_flavor.dart';
import 'package:zeroscroll/features/updater/data/updater_repository.dart';
import 'package:zeroscroll/features/updater/domain/update_check_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Updater Flavor Isolation', () {
    test('Play flavor updater repository returns disabled update', () async {
      final repo = SideloadUpdaterRepository(flavorConfig: FlavorConfig.play());
      final result = await repo.checkForUpdate();
      expect(result.status, equals(UpdateCheckStatus.disabled));
      expect(result.hasUpdate, isFalse);
    });

    test('Sideload flavor allows update check', () async {
      final repo = SideloadUpdaterRepository(
        flavorConfig: FlavorConfig.sideload(),
      );
      final result = await repo.checkForUpdate();
      expect(result, isNotNull);
    });
  });
}
