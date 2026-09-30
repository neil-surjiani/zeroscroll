import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../limits/presentation/providers/reel_budget_provider.dart';
import '../../../limits/presentation/screens/stats_screen.dart';
import '../providers/shell_provider.dart';

/// Slim collapsible top statistics bar displaying today's intentional usage metrics.
class SlimStatsBar extends ConsumerWidget {
  const SlimStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(statsBarCollapsedProvider);
    final usageMinutes = ref.watch(todayUsageMinutesProvider);
    final reelCount = ref.watch(todayReelCountProvider);
    final theme = Theme.of(context);

    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF283548)
        : const Color(0xFFE2E8F0);

    final backgroundColor = theme.brightness == Brightness.dark
        ? const Color(0xFF131B26)
        : const Color(0xFFFFFFFF);

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: isCollapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      // EXPANDED STATE
      firstChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    // Time in App Stat
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${usageMinutes}m in app',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reels Opened Stat
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$reelCount ${reelCount == 1 ? "reel" : "reels"} opened',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Collapse Button
            IconButton(
              key: const ValueKey('collapse_stats_bar'),
              icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
              tooltip: 'Collapse stats bar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                ref.read(statsBarCollapsedProvider.notifier).state = true;
              },
            ),
          ],
        ),
      ),
      // COLLAPSED STATE (Compact slim strip)
      secondChild: InkWell(
        key: const ValueKey('expand_stats_bar'),
        onTap: () {
          ref.read(statsBarCollapsedProvider.notifier).state = false;
        },
        child: Container(
          width: double.infinity,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(bottom: BorderSide(color: borderColor, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '⏱ ${usageMinutes}m  •  ▶ $reelCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
