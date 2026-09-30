import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available distribution build flavors.
enum AppFlavor { play, sideload }

/// Runtime configuration specific to the active distribution flavor.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appTitle,
    required this.canSelfUpdate,
  });

  final AppFlavor flavor;
  final String appTitle;

  /// Whether the app has permission and capability to perform in-app APK self-updating.
  /// Strictly restricted to [AppFlavor.sideload].
  final bool canSelfUpdate;

  bool get isPlay => flavor == AppFlavor.play;
  bool get isSideload => flavor == AppFlavor.sideload;

  /// Detects the active flavor from the runtime environment or falls back to [defaultFlavor].
  factory FlavorConfig.fromEnvironment([
    AppFlavor defaultFlavor = AppFlavor.play,
  ]) {
    final flavorName = appFlavor?.toLowerCase() ?? '';
    if (flavorName == 'sideload') {
      return const FlavorConfig(
        flavor: AppFlavor.sideload,
        appTitle: 'ZeroScroll (Sideload)',
        canSelfUpdate: true,
      );
    }

    return const FlavorConfig(
      flavor: AppFlavor.play,
      appTitle: 'ZeroScroll',
      canSelfUpdate: false,
    );
  }

  /// Explicit factory for the Google Play Store flavor.
  factory FlavorConfig.play() => const FlavorConfig(
    flavor: AppFlavor.play,
    appTitle: 'ZeroScroll',
    canSelfUpdate: false,
  );

  /// Explicit factory for the independent sideload flavor.
  factory FlavorConfig.sideload() => const FlavorConfig(
    flavor: AppFlavor.sideload,
    appTitle: 'ZeroScroll (Sideload)',
    canSelfUpdate: true,
  );
}

/// Riverpod provider for accessing active [FlavorConfig].
final flavorConfigProvider = Provider<FlavorConfig>((ref) {
  return FlavorConfig.fromEnvironment();
});
