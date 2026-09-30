import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_flavor.dart';
import '../domain/update_info.dart';

/// Repository interface for checking and downloading APK updates.
/// Strictly functional only on [AppFlavor.sideload].
abstract class UpdaterRepository {
  Future<UpdateInfo?> checkForUpdate();
}

/// Sideload-specific updater repository implementation.
class SideloadUpdaterRepository implements UpdaterRepository {
  const SideloadUpdaterRepository({required this.flavorConfig});

  final FlavorConfig flavorConfig;

  @override
  Future<UpdateInfo?> checkForUpdate() async {
    // Safety guard: Must never run on Play flavor
    if (!flavorConfig.canSelfUpdate) {
      return null;
    }

    // Placeholder until version.json network fetching is wired in
    return null;
  }
}

final updaterRepositoryProvider = Provider<UpdaterRepository>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  return SideloadUpdaterRepository(flavorConfig: flavor);
});
