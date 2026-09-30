import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/limits_provider.dart';

/// Screen allowing configuration of intentional daily screen time limits.
class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(limitsProvider);
    final theme = Theme.of(context);

    return limitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading limits: $e')),
      data: (limit) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_outlined,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Intentional Usage Limits',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set a healthy daily time threshold to prevent mindless scrolling and protect your attention.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Daily Limit Active'),
                    subtitle: Text(
                      limit.isLimitEnabled
                          ? '${limit.dailyLimitMinutes} minutes allowed daily'
                          : 'Unlimited access (No restrictions)',
                    ),
                    value: limit.isLimitEnabled,
                    onChanged: (enabled) {
                      ref
                          .read(limitsProvider.notifier)
                          .updateLimit(limit.copyWith(isLimitEnabled: enabled));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
