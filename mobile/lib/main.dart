import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_flavor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/remote_config/data/remote_config_repository.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Preload guard script for instantaneous zero-latency WebView bootstrap
  try {
    HttpRouteConfigRepository.preloadedGuardJs =
        await rootBundle.loadString('assets/js/guard.js');
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        flavorConfigProvider.overrideWithValue(FlavorConfig.fromEnvironment()),
      ],
      child: const ZeroScrollApp(),
    ),
  );
}

/// Root widget for the ZeroScroll application.
class ZeroScrollApp extends ConsumerWidget {
  const ZeroScrollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final settings = ref.watch(settingsNotifierProvider);

    return MaterialApp.router(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Accessibility: Support system font scaling with a graceful clamp (0.85x to 2.0x)
        // ensuring high-legibility TalkBack/system font support without layout clipping
        final mediaQuery = MediaQuery.of(context);
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 2.0,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
