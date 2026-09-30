import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_flavor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

    return MaterialApp.router(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
