import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/updater_provider.dart';
import 'update_download_dialog.dart';

/// Non-blocking banner/card displayed when a newer application build is available.
class UpdateAvailableCard extends ConsumerWidget {
  const UpdateAvailableCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updaterProvider);
    final notifier = ref.read(updaterProvider.notifier);

    // Only render if an optional update is available and user hasn't dismissed it
    if (state.status != UpdaterStatus.updateAvailable ||
        state.isCardDismissed ||
        state.manifest == null) {
      return const SizedBox.shrink();
    }

    final manifest = state.manifest!;
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('update_available_card'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Update Available',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${manifest.latestVersion}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'A new build of ZeroScroll is ready to install.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('update_card_dismiss_btn'),
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Dismiss',
                onPressed: () => notifier.dismissCard(),
              ),
            ],
          ),
          if (manifest.changelog.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                manifest.changelog,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const ValueKey('update_card_later_btn'),
                onPressed: () => notifier.dismissCard(),
                child: const Text('Later'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const ValueKey('update_card_update_btn'),
                onPressed: () {
                  UpdateDownloadDialog.show(context);
                  notifier.startDownloadAndInstall();
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
