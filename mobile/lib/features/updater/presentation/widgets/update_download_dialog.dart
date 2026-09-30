import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/updater_provider.dart';

/// Modal dialog showing real-time APK download progress and installation status.
class UpdateDownloadDialog extends ConsumerWidget {
  const UpdateDownloadDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpdateDownloadDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(updaterProvider);
    final notifier = ref.read(updaterProvider.notifier);

    final isDownloading = state.status == UpdaterStatus.downloading;
    final isVerifying = state.status == UpdaterStatus.verifying;
    final isInstalling = state.status == UpdaterStatus.installing;
    final isPermissionRequired = state.status == UpdaterStatus.permissionRequired;
    final isError = state.status == UpdaterStatus.error;

    return PopScope(
      canPop: !isDownloading && !isVerifying,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : (isPermissionRequired
                      ? Icons.security_rounded
                      : Icons.system_update_rounded),
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isError
                    ? 'Update Failed'
                    : (isPermissionRequired
                        ? 'Permission Required'
                        : 'Updating ZeroScroll'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDownloading) ...[
              Text(
                'Downloading v${state.manifest?.latestVersion}...',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
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
                        fontWeight: FontWeight.w600,
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
            ],
            if (isVerifying) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 12),
                      Text('Verifying package integrity & signatures...'),
                    ],
                  ),
                ),
              ),
            ],
            if (isInstalling) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      CircularProgressIndicator.adaptive(),
                      SizedBox(height: 12),
                      Text('Launching Android Package Installer...'),
                    ],
                  ),
                ),
              ),
            ],
            if (isPermissionRequired) ...[
              Text(
                'To install this update, Android requires permission to install apps from ZeroScroll.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('updater_open_settings_btn'),
                onPressed: () => notifier.openPermissionSettings(),
                icon: const Icon(Icons.settings_rounded, size: 18),
                label: const Text('Open Settings'),
              ),
            ],
            if (isError) ...[
              Text(
                state.errorMessage ?? 'An error occurred during update.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isDownloading)
            TextButton(
              key: const ValueKey('updater_cancel_download_btn'),
              onPressed: () {
                notifier.cancelDownload();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          if (isPermissionRequired) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('updater_retry_install_btn'),
              onPressed: () => notifier.retryInstall(),
              child: const Text('Retry Install'),
            ),
          ],
          if (isError) ...[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              key: const ValueKey('updater_retry_download_btn'),
              onPressed: () => notifier.startDownloadAndInstall(),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
