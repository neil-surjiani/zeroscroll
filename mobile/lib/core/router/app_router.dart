import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/security/presentation/screens/privacy_screen.dart';
import '../../features/settings/presentation/screens/choose_features_screen.dart';
import '../../features/settings/presentation/screens/features_settings_screen.dart';
import '../../features/shell/presentation/screens/home_screen.dart';

/// Provider for app-wide GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/features/choose',
        name: 'chooseFeatures',
        builder: (context, state) => const ChooseFeaturesScreen(),
      ),
      GoRoute(
        path: '/settings/features',
        name: 'settingsFeatures',
        builder: (context, state) => const FeaturesSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
