import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/limits_status.dart';
import '../providers/limits_state_provider.dart';

/// Full-screen intentional overlay displayed when the daily time limit is reached.
class DoneForTodayOverlay extends ConsumerWidget {
  const DoneForTodayOverlay({
    super.key,
    required this.status,
  });

  final DoneForTodayStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.colorScheme.surface;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Calming Icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bedtime_outlined,
                        size: 44,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Done for Today',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle / Limit Explanation
                    Text(
                      'You’ve reached your daily threshold of ${status.limitMinutes} minutes (active time: ${status.usedMinutes}m).',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Calming Reminder Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Rest your eyes, step away from the screen, and recharge your mind.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Emergency 5-Minute Unlock Button
                    if (status.emergencyUnlocksRemaining > 0) ...[
                      FilledButton.icon(
                        key: const ValueKey('emergency_unlock_button'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.lock_open_rounded, size: 20),
                        label: const Text(
                          'Emergency 5-Minute Unlock',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: () async {
                          final granted = await ref
                              .read(emergencyUnlockProvider.notifier)
                              .requestUnlock();
                          if (granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Emergency 5-minute unlock active.'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${status.emergencyUnlocksRemaining} of ${status.maxEmergencyUnlocks} unlock${status.maxEmergencyUnlocks == 1 ? "" : "s"} left today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        key: const ValueKey('emergency_unlock_exhausted_button'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: const Text('Emergency unlocks exhausted today'),
                        onPressed: null,
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Close App Button
                    TextButton.icon(
                      key: const ValueKey('close_app_button'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                      label: const Text('Close ZeroScroll'),
                      onPressed: () => SystemNavigator.pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
