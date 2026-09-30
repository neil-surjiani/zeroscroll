import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/limits_repository.dart';
import '../../domain/focus_schedule.dart';
import '../../../settings/presentation/providers/feature_preferences_provider.dart';
import '../providers/limits_state_provider.dart';
import 'stats_screen.dart';

/// Screen allowing configuration of intentional daily screen time limits,
/// reel budgets, focus schedules, reply friction, 4 AM resets, and data management.
class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(limitsConfigProvider);
    final featurePrefs = ref.watch(featurePreferencesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limits & Focus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded),
            tooltip: 'View Intentional Stats',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading limits: $e')),
        data: (config) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // 1. DAILY SCREEN TIME SECTION
            _SectionHeader(title: 'Screen Time Threshold', icon: Icons.hourglass_top_rounded),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Daily App Limit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        config.isDailyTimeLimitEnabled
                            ? '${config.dailyTimeLimitMinutes} minutes allowed per day'
                            : 'Off (No daily screen time limit)',
                      ),
                      value: config.isDailyTimeLimitEnabled,
                      onChanged: (val) {
                        ref.read(limitsConfigProvider.notifier).toggleTimeLimit(val);
                      },
                    ),
                    if (config.isDailyTimeLimitEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Allowed daily time:', style: theme.textTheme.bodyMedium),
                          ),
                          Text(
                            '${config.dailyTimeLimitMinutes} min',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: config.dailyTimeLimitMinutes.toDouble(),
                        min: 10,
                        max: 180,
                        divisions: 34,
                        label: '${config.dailyTimeLimitMinutes}m',
                        onChanged: (val) {
                          ref
                              .read(limitsConfigProvider.notifier)
                              .setTimeLimitMinutes(val.round());
                        },
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Emergency Unlocks', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '5-minute extensions per day',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          DropdownButton<int>(
                            value: config.maxEmergencyUnlocksPerDay,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 unlock')),
                              DropdownMenuItem(value: 2, child: Text('2 unlocks')),
                              DropdownMenuItem(value: 3, child: Text('3 unlocks')),
                              DropdownMenuItem(value: 5, child: Text('5 unlocks')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref.read(limitsConfigProvider.notifier).setMaxEmergencyUnlocks(v);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (featurePrefs.reelsFromDmsEnabled) ...[
              const SizedBox(height: 20),

              // 2. DAILY REEL BUDGET SECTION
              _SectionHeader(title: 'Reel Consumption Budget', icon: Icons.play_circle_outline_rounded),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Reel Budget',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          config.isReelBudgetEnabled
                              ? '${config.dailyReelBudget} ${config.dailyReelBudget == 1 ? "reel" : "reels"} allowed per day'
                              : 'Unlimited reel viewing',
                        ),
                        value: config.isReelBudgetEnabled,
                        onChanged: (val) {
                          ref.read(limitsConfigProvider.notifier).toggleReelBudget(val);
                        },
                      ),
                      if (config.isReelBudgetEnabled) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Max reels per day:', style: theme.textTheme.bodyMedium),
                            ),
                            Text(
                              '${config.dailyReelBudget}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: config.dailyReelBudget.toDouble(),
                          min: 0,
                          max: 20,
                          divisions: 20,
                          label: '${config.dailyReelBudget}',
                          onChanged: (val) {
                            ref.read(limitsConfigProvider.notifier).setReelBudget(val.round());
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 3. MINDFUL FRICTION & NIGHT BOUNDARIES
            _SectionHeader(title: 'Mindful Friction & Schedules', icon: Icons.psychology_outlined),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Reply-Friction Pause'),
                    subtitle: const Text(
                      'Adds a 5-second mindful pause before opening reels from direct messages.',
                    ),
                    value: config.isReplyFrictionEnabled,
                    onChanged: (val) {
                      ref.read(limitsConfigProvider.notifier).toggleReplyFriction(val);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Reset Day at 4:00 AM'),
                    subtitle: const Text(
                      'Ideal for night owls. Daily usage and reel budgets reset at 4 AM instead of midnight.',
                    ),
                    value: config.resetDayAt4AM,
                    onChanged: (val) {
                      ref.read(limitsConfigProvider.notifier).setResetDayAt4AM(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. FOCUS SCHEDULES SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: _SectionHeader(title: 'Focus Schedules', icon: Icons.do_not_disturb_on_outlined),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Schedule'),
                  onPressed: () => _showScheduleDialog(context, ref),
                ),
              ],
            ),
            if (config.focusSchedules.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 36, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(
                        'No focus schedules configured',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set scheduled hours (e.g. work time or overnight) where app access is locked and notifications are silenced.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...config.focusSchedules.map((schedule) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: schedule.isEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(schedule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${schedule.timeFormatted} • ${schedule.weekdaysFormatted}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: schedule.isEnabled,
                          onChanged: (enabled) {
                            ref.read(limitsConfigProvider.notifier).updateFocusSchedule(
                                  schedule.copyWith(isEnabled: enabled),
                                );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          tooltip: 'Delete schedule',
                          onPressed: () {
                            ref.read(limitsConfigProvider.notifier).removeFocusSchedule(schedule.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // 5. DATA MANAGEMENT & WIPE
            _SectionHeader(title: 'Data Management', icon: Icons.shield_outlined),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download_rounded),
                    title: const Text('Export My Data (JSON)'),
                    subtitle: const Text('Share or save your on-device usage sessions and limits'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _exportData(context, ref),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    title: const Text(
                      'Delete All My Data',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Wipes all local usage history, reel logs, and reset settings'),
                    onTap: () => _confirmDeleteData(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(limitsRepositoryProvider);
      final data = await repo.exportData();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/zeroscroll_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'ZeroScroll local usage and session export',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Usage Data?'),
        content: const Text(
          'This will permanently erase all local usage sessions, reel logs, and custom limit settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(limitsRepositoryProvider);
      await repo.wipeAllData();
      ref.invalidate(limitsConfigProvider);
      ref.invalidate(usageStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local usage data has been erased.')),
        );
      }
    }
  }

  void _showScheduleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _AddScheduleDialog(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddScheduleDialog extends StatefulWidget {
  const _AddScheduleDialog();

  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _nameController = TextEditingController(text: 'Work Hours');
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final Set<int> _selectedDays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOvernight = (_startTime.hour * 60 + _startTime.minute) >
        (_endTime.hour * 60 + _endTime.minute);

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Consumer(
      builder: (context, ref, _) => AlertDialog(
        title: const Text('Add Focus Schedule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Schedule Name',
                  hintText: 'e.g. Work, Deep Sleep',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) setState(() => _startTime = t);
                      },
                      child: Text('Start: ${_startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) setState(() => _endTime = t);
                      },
                      child: Text('End: ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              if (isOvernight) ...[
                const SizedBox(height: 8),
                Text(
                  '🌙 Overnight schedule crossing midnight',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Active Weekdays:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final dayNumber = i + 1;
                  final isSelected = _selectedDays.contains(dayNumber);
                  return FilterChip(
                    label: Text(dayLabels[i]),
                    selected: isSelected,
                    showCheckmark: false,
                    padding: EdgeInsets.zero,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(dayNumber);
                        } else if (_selectedDays.length > 1) {
                          _selectedDays.remove(dayNumber);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;

              final schedule = FocusSchedule(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                startHour: _startTime.hour,
                startMinute: _startTime.minute,
                endHour: _endTime.hour,
                endMinute: _endTime.minute,
                weekdays: _selectedDays.toList()..sort(),
              );

              ref.read(limitsConfigProvider.notifier).addFocusSchedule(schedule);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
