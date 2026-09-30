import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usage_stats.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../providers/limits_state_provider.dart';
import '../providers/story_budget_provider.dart';

/// Screen displaying today, 7-day, and 30-day screen time, reels opened,
/// reels avoided, intentional usage streak, and 7-day visual chart.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(usageStatsProvider);
    final featurePrefs = ref.watch(featurePreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intentional Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Stats',
            onPressed: () {
              ref.invalidate(usageStatsProvider);
              ref.invalidate(storyStatsProvider);
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error loading stats: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(usageStatsProvider);
                    ref.invalidate(storyStatsProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(usageStatsProvider);
            ref.invalidate(storyStatsProvider);
            await ref.read(usageStatsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Streak Banner
              _StreakCard(streakDays: stats.currentStreakDays),
              const SizedBox(height: 16),

              // 2. Summary Metric Cards: Today, 7-Day, 30-Day
              _TimeMetricsGrid(
                stats: stats,
                reelsEnabled: featurePrefs.reelsFromDmsEnabled,
              ),
              const SizedBox(height: 20),

              // 3. Reels Avoided Card (Only shown when reels are enabled)
              if (featurePrefs.reelsFromDmsEnabled) ...[
                _ReelsAvoidedCard(count: stats.reelsAvoided),
                const SizedBox(height: 20),
              ],

              // 3.1 Stories Stats Card (Prompt 10)
              const _StoriesStatsCard(),
              const SizedBox(height: 20),

              // 4. 7-Day Visual Bar Chart
              _WeeklyBarChart(history: stats.dailyHistory),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays-Day Intentional Streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streakDays > 0
                      ? 'You’ve maintained healthy, bounded screen time!'
                      : 'Stay within your daily threshold today to build your streak.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeMetricsGrid extends StatelessWidget {
  const _TimeMetricsGrid({
    required this.stats,
    this.reelsEnabled = true,
  });

  final UsageStats stats;
  final bool reelsEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Today',
                timeMinutes: stats.todayMinutes,
                reels: stats.todayReels,
                reelsEnabled: reelsEnabled,
                icon: Icons.today_rounded,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Last 7 Days',
                timeMinutes: stats.sevenDayMinutes,
                reels: stats.sevenDayReels,
                reelsEnabled: reelsEnabled,
                subtitle: 'Avg ${stats.averageDailyMinutes7d.toStringAsFixed(1)}m / day',
                icon: Icons.date_range_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Last 30 Days',
          timeMinutes: stats.thirtyDayMinutes,
          reels: stats.thirtyDayReels,
          reelsEnabled: reelsEnabled,
          subtitle: 'Avg ${stats.averageDailyMinutes30d.toStringAsFixed(1)}m / day',
          icon: Icons.calendar_month_rounded,
          isFullWidth: true,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.timeMinutes,
    required this.reels,
    this.reelsEnabled = true,
    required this.icon,
    this.subtitle,
    this.isPrimary = false,
    this.isFullWidth = false,
  });

  final String title;
  final int timeMinutes;
  final int reels;
  final bool reelsEnabled;
  final IconData icon;
  final String? subtitle;
  final bool isPrimary;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPrimary
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${timeMinutes}m',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary ? colorScheme.primary : null,
              ),
            ),
            if (reelsEnabled) ...[
              const SizedBox(height: 4),
              Text(
                '$reels ${reels == 1 ? "reel" : "reels"} opened',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReelsAvoidedCard extends StatelessWidget {
  const _ReelsAvoidedCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.green,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count Reels Avoided',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Moments where reply-friction helped you mindfully skip video traps.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.history});

  final List<DailyStatItem> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int maxMinutes = 1;
    for (final item in history) {
      if (item.minutes > maxMinutes) {
        maxMinutes = item.minutes;
      }
    }

    const shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '7-Day App Usage',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: history.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isToday = index == history.length - 1;
                  final dayLabel = isToday ? 'Today' : shortDays[item.date.weekday - 1];

                  final barRatio = (item.minutes / maxMinutes).clamp(0.05, 1.0);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Minutes text
                        Text(
                          '${item.minutes}m',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bar
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: barRatio,
                              child: Container(
                                width: 22,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? colorScheme.primary
                                      : colorScheme.primary.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Day of week label
                        Text(
                          dayLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoriesStatsCard extends ConsumerWidget {
  const _StoriesStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final storyStatsAsync = ref.watch(storyStatsProvider);

    return storyStatsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (storyStats) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.amp_stories_outlined,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stories Watched',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Bounded single-user viewing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StoryMetric(label: 'Today', value: '${storyStats.todayStories}'),
                  _StoryMetric(label: '7 Days', value: '${storyStats.sevenDayStories}'),
                  _StoryMetric(label: '30 Days', value: '${storyStats.thirtyDayStories}'),
                  _StoryMetric(label: 'Avoided', value: '${storyStats.storiesAvoided}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryMetric extends StatelessWidget {
  const _StoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

