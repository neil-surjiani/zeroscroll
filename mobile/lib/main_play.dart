import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_flavor.dart';
import 'main.dart';

/// Entrypoint for the Google Play Store build flavor.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [flavorConfigProvider.overrideWithValue(FlavorConfig.play())],
      child: const ZeroScrollApp(),
    ),
  );
}
