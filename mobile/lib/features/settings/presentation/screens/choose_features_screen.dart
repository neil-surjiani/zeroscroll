import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../onboarding/presentation/widgets/preferences_step_view.dart';
import '../../data/feature_preferences_repository.dart';
import '../../domain/feature_preferences.dart';
import '../providers/feature_preferences_provider.dart';

/// One-time migration screen for existing installs who finished onboarding
/// prior to the granular features update. Defaults to the legacy behavior
/// (reels on, stories off).
class ChooseFeaturesScreen extends ConsumerWidget {
  const ChooseFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroScroll Features'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: PreferencesStepView(
          isStandaloneMigration: true,
          initialPreferences: FeaturePreferences.oldDefault,
          onConfirmed: (prefs) async {
            final confirmed = prefs.copyWith(hasChosenFeatures: true);
            await ref
                .read(featurePreferencesRepositoryProvider)
                .savePreferences(confirmed);
            await ref
                .read(featurePreferencesProvider.notifier)
                .updatePreferences(confirmed);
            if (context.mounted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            }
          },
        ),
      ),
    );
  }
}
