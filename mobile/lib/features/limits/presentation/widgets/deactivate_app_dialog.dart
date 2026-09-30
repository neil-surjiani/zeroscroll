import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/limits_state_provider.dart';

enum DeactivationUnit { hours, days }

/// Interactive modal sheet allowing the user to deactivate and hard-lock ZeroScroll
/// for a specified duration in hours or days with zero bypass options.
class DeactivateAppDialog extends ConsumerStatefulWidget {
  const DeactivateAppDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const DeactivateAppDialog(),
    );
  }

  @override
  ConsumerState<DeactivateAppDialog> createState() =>
      _DeactivateAppDialogState();
}

class _DeactivateAppDialogState extends ConsumerState<DeactivateAppDialog> {
  DeactivationUnit _selectedUnit = DeactivationUnit.hours;
  int _selectedValue = 4;
  bool _hasConfirmedNoBypass = false;

  final List<int> _hourPresets = [1, 2, 4, 8, 12, 24];
  final List<int> _dayPresets = [1, 2, 3, 5, 7, 14, 30];

  Duration get _selectedDuration {
    if (_selectedUnit == DeactivationUnit.hours) {
      return Duration(hours: _selectedValue);
    } else {
      return Duration(days: _selectedValue);
    }
  }

  DateTime get _targetUnlockTime {
    return DateTime.now().add(_selectedDuration);
  }

  String _formatDateTime(DateTime dt) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    final day = dt.day;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$weekday, $month $day at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_clock_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deactivate ZeroScroll',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lock out access for hours or days with zero bypass',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Unit Selector (Hours vs Days)
            SegmentedButton<DeactivationUnit>(
              segments: const [
                ButtonSegment(
                  value: DeactivationUnit.hours,
                  label: Text('Hours'),
                  icon: Icon(Icons.hourglass_bottom_rounded, size: 18),
                ),
                ButtonSegment(
                  value: DeactivationUnit.days,
                  label: Text('Days'),
                  icon: Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ],
              selected: {_selectedUnit},
              onSelectionChanged: (val) {
                setState(() {
                  _selectedUnit = val.first;
                  _selectedValue = _selectedUnit == DeactivationUnit.hours ? 4 : 1;
                });
              },
            ),
            const SizedBox(height: 16),

            // Presets Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_selectedUnit == DeactivationUnit.hours
                      ? _hourPresets
                      : _dayPresets)
                  .map((val) {
                final isSelected = _selectedValue == val;
                final unitLabel = _selectedUnit == DeactivationUnit.hours
                    ? (val == 1 ? '1 Hour' : '$val Hours')
                    : (val == 1 ? '1 Day' : '$val Days');
                return ChoiceChip(
                  key: ValueKey('deactivate_chip_${_selectedUnit.name}_$val'),
                  label: Text(unitLabel),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedValue = val;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom Slider / Counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Custom Duration:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedUnit == DeactivationUnit.hours
                            ? '$_selectedValue ${_selectedValue == 1 ? 'hour' : 'hours'}'
                            : '$_selectedValue ${_selectedValue == 1 ? 'day' : 'days'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _selectedValue.toDouble(),
                    min: 1,
                    max: _selectedUnit == DeactivationUnit.hours ? 72 : 30,
                    divisions: _selectedUnit == DeactivationUnit.hours ? 71 : 29,
                    onChanged: (val) {
                      setState(() {
                        _selectedValue = val.round();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Unlock Target Time Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlocks on:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(_targetUnlockTime),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Warning Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFED4956).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFED4956).withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFED4956),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zero-Bypass Lockout: Once deactivated, the app will be completely locked until the timer finishes. There is NO emergency unlock, NO ignore button, and NO "one more minute" option.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Strict confirmation checkbox
            CheckboxListTile(
              key: const ValueKey('deactivate_confirm_checkbox'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I understand this lock cannot be cancelled or bypassed under any circumstances.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _hasConfirmedNoBypass,
              onChanged: (val) {
                setState(() {
                  _hasConfirmedNoBypass = val ?? false;
                });
              },
            ),
            const SizedBox(height: 16),

            // Action Button
            FilledButton.icon(
              key: const ValueKey('deactivate_confirm_button'),
              onPressed: _hasConfirmedNoBypass
                  ? () async {
                      final duration = _selectedDuration;
                      await ref
                          .read(limitsConfigProvider.notifier)
                          .deactivateApp(duration);

                      if (context.mounted) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  : null,
              icon: const Icon(Icons.lock_rounded, size: 20),
              label: Text(
                'Deactivate for ${_selectedUnit == DeactivationUnit.hours ? '$_selectedValue ${_selectedValue == 1 ? 'Hour' : 'Hours'}' : '$_selectedValue ${_selectedValue == 1 ? 'Day' : 'Days'}'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFED4956),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Never Mind, Stay Active'),
            ),
          ],
        ),
      ),
    );
  }
}
