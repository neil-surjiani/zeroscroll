import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/updater_provider.dart';

/// Full-screen blocking update screen displayed when the installed app build
/// is below the server's minSupportedBuild requirement.
class BlockingUpdateScreen extends ConsumerWidget {
  const BlockingUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(updaterProvider);
    final notifier = ref.read(updaterProvider.notifier);
    final manifest = state.manifest;

    final isDownloading = state.status == UpdaterStatus.downloading;
    final isVerifying = state.status == UpdaterStatus.verifying;
    final isInstalling = state.status == UpdaterStatus.installing;
    final isPermissionRequired = state.status == UpdaterStatus.permissionRequired;
    final isError = state.status == UpdaterStatus.error;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_security_update_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Update Required',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your current version of ZeroScroll is no longer supported. Please update to continue accessing your messages safely.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (manifest != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Version ${manifest.latestVersion}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Build ${manifest.latestBuild}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (manifest.changelog.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            manifest.changelog,
                            style: theme.textTheme.bodySmall,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // In-progress download indicator
                if (isDownloading) ...[
                  LinearProgressIndicator(
                    value: state.downloadProgress != null &&
                            state.downloadProgress!.totalBytes > 0
                        ? state.downloadProgress!.percentage
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  if (state.downloadProgress != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(state.downloadProgress!.percentage * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${state.downloadProgress!.formattedReceived} / ${state.downloadProgress!.formattedTotal}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => notifier.cancelDownload(),
                    child: const Text('Cancel Download'),
                  ),
                ] else if (isVerifying) ...[
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: 12),
                  const Text('Verifying integrity and signatures...'),
                ] else if (isInstalling) ...[
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: 12),
                  const Text('Launching Android Package Installer...'),
                ] else if (isPermissionRequired) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Permission to install unknown apps is required.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey('blocking_update_settings_btn'),
                      onPressed: () => notifier.openPermissionSettings(),
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Allow in Settings'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('blocking_update_retry_install_btn'),
                    onPressed: () => notifier.retryInstall(),
                    child: const Text('Retry Install'),
                  ),
                ] else if (isError) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      state.errorMessage ?? 'Update failed. Please retry.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey('blocking_update_retry_btn'),
                      onPressed: () => notifier.startDownloadAndInstall(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Update'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey('blocking_update_download_btn'),
                      onPressed: () => notifier.startDownloadAndInstall(),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download & Install Update'),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
