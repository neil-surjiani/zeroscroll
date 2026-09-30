import 'dart:async';
import 'package:flutter/material.dart';

/// Confirmation dialog enforcing a 10-second reflection pause before
/// any mindful consumption restriction can be loosened.
class LooseningConfirmationDialog extends StatefulWidget {
  const LooseningConfirmationDialog({
    super.key,
    required this.title,
    required this.descriptions,
    required this.is24hDelayActive,
    required this.onConfirmed,
  });

  final String title;
  final List<String> descriptions;
  final bool is24hDelayActive;
  final VoidCallback onConfirmed;

  @override
  State<LooseningConfirmationDialog> createState() =>
      _LooseningConfirmationDialogState();
}

class _LooseningConfirmationDialogState
    extends State<LooseningConfirmationDialog> {
  int _secondsRemaining = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTimerDone = _secondsRemaining == 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.hourglass_bottom_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are requesting to loosen the following restrictions:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.descriptions.map(
              (desc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: colorScheme.primary)),
                    Expanded(child: Text(desc)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.is24hDelayActive
                    ? '24-hour delay is active. Upon confirmation, these changes will take effect in 24 hours.'
                    : 'To help prevent impulsive digital consumption, please pause for a moment before unlocking.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!isTimerDone)
              Center(
                child: Text(
                  'Wait $_secondsRemaining seconds...',
                  key: const ValueKey('loosening_modal_wait_label'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('loosening_modal_cancel_btn'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('loosening_modal_confirm_btn'),
          onPressed: isTimerDone
              ? () {
                  Navigator.of(context).pop();
                  widget.onConfirmed();
                }
              : null,
          child: Text(isTimerDone ? 'Confirm' : 'Wait (${_secondsRemaining}s)'),
        ),
      ],
    );
  }
}
