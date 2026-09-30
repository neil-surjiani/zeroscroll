import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/limits_state_provider.dart';

/// Modal dialog imposing an intentional 5-second pause before opening reels from DMs.
class ReplyFrictionDialog extends ConsumerStatefulWidget {
  const ReplyFrictionDialog({super.key});

  /// Displays the reply-friction dialog. Returns `true` if the user intentionally
  /// confirmed opening the reel after the countdown, or `false` if avoided/cancelled.
  static Future<bool> show(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ReplyFrictionDialog(),
    );

    final didConfirm = result == true;
    if (!didConfirm) {
      await ref.read(limitsConfigProvider.notifier).recordReelsAvoided();
    }
    return didConfirm;
  }

  @override
  ConsumerState<ReplyFrictionDialog> createState() => _ReplyFrictionDialogState();
}

class _ReplyFrictionDialogState extends ConsumerState<ReplyFrictionDialog> {
  int _secondsRemaining = 5;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _secondsRemaining = 0;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReady = _secondsRemaining == 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pause_circle_outline_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mindful Pause',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to open this reel?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A brief pause helps you decide if you truly want to watch this now, preventing unintended rabbit holes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isReady
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isReady
                    ? '✓ You can now open this reel'
                    : 'Pause for $_secondsRemaining second${_secondsRemaining == 1 ? "" : "s"}...',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isReady ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          key: const ValueKey('reply_friction_cancel_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Skip Reel (Avoid)'),
        ),
        FilledButton(
          key: const ValueKey('reply_friction_continue_button'),
          onPressed: isReady ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Open Reel'),
        ),
      ],
    );
  }
}
