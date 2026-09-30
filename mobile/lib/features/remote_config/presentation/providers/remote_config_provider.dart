import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../../data/remote_config_repository.dart';
import '../../domain/route_config.dart';

export '../../data/remote_config_repository.dart'
    show
        routeConfigRepositoryProvider,
        routeConfigProvider,
        guardJsProvider,
        RouteConfigRepository,
        HttpRouteConfigRepository,
        ConfigSource;
export '../../domain/css_sanitizer.dart';
export '../../domain/kill_switch_config.dart';
export '../../domain/remote_config_validator.dart';
export '../../domain/route_config.dart';
export '../widgets/kill_switch_overlay.dart';

/// Provider for dynamic [RouteConfig] merged with the user's [FeaturePreferences].
final effectiveRouteConfigProvider = Provider<RouteConfig>((ref) {
  final rawAsync = ref.watch(routeConfigProvider);
  final prefs = ref.watch(featurePreferencesProvider);
  final baseConfig = rawAsync.valueOrNull ??
      RouteConfig(
        version: 1,
        userAgent: '',
        fallbackPath: '/direct/inbox/',
        allowedPaths: const [],
        alwaysBlockedPaths: const [],
        hideSelectors: const [],
        featureGroups: RouteConfig.createDefaultFeatureGroups(),
      );
  return baseConfig.computeEffectiveConfig(prefs);
});
