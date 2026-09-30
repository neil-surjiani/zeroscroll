import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../security/data/security_repository.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Step 4: Optional Biometric Lock screen.
/// Checks device capability, offers fingerprint/face unlock on launch,
/// and tests it immediately when enabled.
class BiometricsStepView extends ConsumerStatefulWidget {
  const BiometricsStepView({super.key});

  @override
  ConsumerState<BiometricsStepView> createState() => _BiometricsStepViewState();
}

class _BiometricsStepViewState extends ConsumerState<BiometricsStepView> {
  bool _isLoading = true;
  bool _isDeviceSupported = false;
  bool _isTestingAuth = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final repo = ref.read(securityRepositoryProvider);
    final supported = await repo.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _isDeviceSupported = supported;
        _isLoading = false;
      });
    }
  }

  Future<void> _onToggleBiometrics(bool enable) async {
    final settings = ref.read(settingsNotifierProvider);
    final repo = ref.read(securityRepositoryProvider);

    if (enable) {
      setState(() => _isTestingAuth = true);
      final authenticated = await repo.authenticate();
      if (!mounted) return;
      setState(() => _isTestingAuth = false);

      if (authenticated) {
        await ref
            .read(settingsNotifierProvider.notifier)
            .updateSettings(settings.copyWith(biometricLockEnabled: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric lock verified and enabled.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Authentication was not completed. Biometrics remained off.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      await ref
          .read(settingsNotifierProvider.notifier)
          .updateSettings(settings.copyWith(biometricLockEnabled: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsNotifierProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Keep It Private',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Protect your personal chats by requiring biometric unlock (fingerprint or face) whenever ZeroScroll opens.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          if (_isDeviceSupported) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.biometricLockEnabled
                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.biometricLockEnabled
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: settings.biometricLockEnabled
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Require Biometric Unlock',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fingerprint, face, or screen lock',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isTestingAuth)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      else
                        Switch.adaptive(
                          key: const ValueKey('biometrics_toggle_switch'),
                          value: settings.biometricLockEnabled,
                          onChanged: _onToggleBiometrics,
                        ),
                    ],
                  ),
                  if (settings.biometricLockEnabled) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active: Your messages are protected.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ZeroScroll never stores any biometric data. All authentication occurs safely through the Android OS hardware security module.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biometrics Not Available',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This device does not have fingerprint or face recognition configured. You can set it up in your phone\'s Settings later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
