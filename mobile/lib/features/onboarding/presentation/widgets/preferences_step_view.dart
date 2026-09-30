import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/domain/feature_preferences.dart';

enum _PreferencesSubStep {
  presetChooser,
  q1Reels,
  q2ReelBudget,
  q3Stories,
  q4StoriesPosting,
  q5SharedPosts,
  q6Notifications,
  summary,
}

/// Onboarding step allowing the user to select a mindful preset (Strict, Balanced, Custom)
/// or step through 6 granular questions, finishing on a review summary before changes are applied.
class PreferencesStepView extends ConsumerStatefulWidget {
  const PreferencesStepView({
    super.key,
    required this.onConfirmed,
    this.onBackToPreviousStep,
    this.initialPreferences,
    this.isStandaloneMigration = false,
  });

  final Future<void> Function(FeaturePreferences preferences) onConfirmed;
  final VoidCallback? onBackToPreviousStep;
  final FeaturePreferences? initialPreferences;
  final bool isStandaloneMigration;

  @override
  ConsumerState<PreferencesStepView> createState() =>
      PreferencesStepViewState();
}

class PreferencesStepViewState extends ConsumerState<PreferencesStepView> {
  late _PreferencesSubStep _currentSubStep;
  late FeaturePreferences _answers;
  bool _returnToSummaryAfterEdit = false;

  @override
  void initState() {
    super.initState();
    _answers = widget.initialPreferences ?? FeaturePreferences.balanced;
    _currentSubStep = _PreferencesSubStep.presetChooser;
  }

  void _selectPreset(FeaturePreferences preset) {
    setState(() {
      _answers = preset;
      _currentSubStep = _PreferencesSubStep.summary;
    });
  }

  void _startCustomQuestions() {
    setState(() {
      _returnToSummaryAfterEdit = false;
      _currentSubStep = _PreferencesSubStep.q1Reels;
    });
  }

  void _advanceFromQ1(bool reelsEnabled) {
    setState(() {
      _answers = _answers.copyWith(reelsFromDmsEnabled: reelsEnabled);
      if (!reelsEnabled) {
        if (_returnToSummaryAfterEdit) {
          _currentSubStep = _PreferencesSubStep.summary;
        } else {
          _currentSubStep = _PreferencesSubStep.q3Stories;
        }
      } else {
        _currentSubStep = _PreferencesSubStep.q2ReelBudget;
      }
    });
  }

  void _advanceFromQ2(int? budget) {
    setState(() {
      _answers = _answers.copyWith(
        dailyReelLimit: budget,
        clearDailyReelLimit: budget == null,
      );
      if (_returnToSummaryAfterEdit) {
        _currentSubStep = _PreferencesSubStep.summary;
      } else {
        _currentSubStep = _PreferencesSubStep.q3Stories;
      }
    });
  }

  void _advanceFromQ3(StoriesViewMode mode) {
    setState(() {
      _answers = _answers.copyWith(storiesViewMode: mode);
      if (_returnToSummaryAfterEdit) {
        _currentSubStep = _PreferencesSubStep.summary;
      } else {
        _currentSubStep = _PreferencesSubStep.q4StoriesPosting;
      }
    });
  }

  void _advanceFromQ4(bool postingEnabled) {
    setState(() {
      _answers = _answers.copyWith(storiesPostingEnabled: postingEnabled);
      if (_returnToSummaryAfterEdit) {
        _currentSubStep = _PreferencesSubStep.summary;
      } else {
        _currentSubStep = _PreferencesSubStep.q5SharedPosts;
      }
    });
  }

  void _advanceFromQ5(bool sharedPostsEnabled) {
    setState(() {
      _answers = _answers.copyWith(
        sharedPostsFromDmsEnabled: sharedPostsEnabled,
      );
      if (_returnToSummaryAfterEdit) {
        _currentSubStep = _PreferencesSubStep.summary;
      } else {
        _currentSubStep = _PreferencesSubStep.q6Notifications;
      }
    });
  }

  void _advanceFromQ6(bool messagesOnly) {
    setState(() {
      _answers = _answers.copyWith(
        messagesOnlyNotifications: messagesOnly,
      );
      _currentSubStep = _PreferencesSubStep.summary;
    });
  }

  void _handleBack() {
    setState(() {
      switch (_currentSubStep) {
        case _PreferencesSubStep.presetChooser:
          widget.onBackToPreviousStep?.call();
          break;
        case _PreferencesSubStep.q1Reels:
          if (_returnToSummaryAfterEdit) {
            _currentSubStep = _PreferencesSubStep.summary;
          } else {
            _currentSubStep = _PreferencesSubStep.presetChooser;
          }
          break;
        case _PreferencesSubStep.q2ReelBudget:
          _currentSubStep = _PreferencesSubStep.q1Reels;
          break;
        case _PreferencesSubStep.q3Stories:
          if (_returnToSummaryAfterEdit) {
            _currentSubStep = _PreferencesSubStep.summary;
          } else if (_answers.reelsFromDmsEnabled) {
            _currentSubStep = _PreferencesSubStep.q2ReelBudget;
          } else {
            _currentSubStep = _PreferencesSubStep.q1Reels;
          }
          break;
        case _PreferencesSubStep.q4StoriesPosting:
          if (_returnToSummaryAfterEdit) {
            _currentSubStep = _PreferencesSubStep.summary;
          } else {
            _currentSubStep = _PreferencesSubStep.q3Stories;
          }
          break;
        case _PreferencesSubStep.q5SharedPosts:
          if (_returnToSummaryAfterEdit) {
            _currentSubStep = _PreferencesSubStep.summary;
          } else {
            _currentSubStep = _PreferencesSubStep.q4StoriesPosting;
          }
          break;
        case _PreferencesSubStep.q6Notifications:
          if (_returnToSummaryAfterEdit) {
            _currentSubStep = _PreferencesSubStep.summary;
          } else {
            _currentSubStep = _PreferencesSubStep.q5SharedPosts;
          }
          break;
        case _PreferencesSubStep.summary:
          _currentSubStep = _PreferencesSubStep.presetChooser;
          break;
      }
    });
  }

  void _handleSkip() {
    switch (_currentSubStep) {
      case _PreferencesSubStep.q1Reels:
        // Safest: Reels off
        _advanceFromQ1(false);
        break;
      case _PreferencesSubStep.q2ReelBudget:
        // Safest: 1 reel per day
        _advanceFromQ2(1);
        break;
      case _PreferencesSubStep.q3Stories:
        // Safest: Stories off
        _advanceFromQ3(StoriesViewMode.off);
        break;
      case _PreferencesSubStep.q4StoriesPosting:
        // Safest: Posting off
        _advanceFromQ4(false);
        break;
      case _PreferencesSubStep.q5SharedPosts:
        // Safest: Block shared posts
        _advanceFromQ5(false);
        break;
      case _PreferencesSubStep.q6Notifications:
        // Safest: Messages only
        _advanceFromQ6(true);
        break;
      default:
        break;
    }
  }

  void _jumpToEdit(_PreferencesSubStep step) {
    setState(() {
      _returnToSummaryAfterEdit = true;
      _currentSubStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: _currentSubStep == _PreferencesSubStep.presetChooser,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_currentSubStep) {
          _PreferencesSubStep.presetChooser => _buildPresetChooser(theme, colorScheme),
          _PreferencesSubStep.q1Reels => _buildQ1(theme, colorScheme),
          _PreferencesSubStep.q2ReelBudget => _buildQ2(theme, colorScheme),
          _PreferencesSubStep.q3Stories => _buildQ3(theme, colorScheme),
          _PreferencesSubStep.q4StoriesPosting => _buildQ4(theme, colorScheme),
          _PreferencesSubStep.q5SharedPosts => _buildQ5(theme, colorScheme),
          _PreferencesSubStep.q6Notifications => _buildQ6(theme, colorScheme),
          _PreferencesSubStep.summary => _buildSummary(theme, colorScheme),
        },
      ),
    );
  }

  // --- SUB-STEP 0: PRESET CHOOSER ---
  Widget _buildPresetChooser(ThemeData theme, ColorScheme colorScheme) {
    return SingleChildScrollView(
      key: const ValueKey('preferences_preset_chooser_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isStandaloneMigration
                ? 'New: Choose your features'
                : 'Choose your preferences',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ZeroScroll puts you in control. Start with a mindful preset or customize every option.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // 1. Strict Preset
          _PresetCard(
            key: const ValueKey('onboarding_preset_strict'),
            title: 'Strict',
            badge: 'Maximum Focus',
            badgeColor: Colors.blueGrey,
            description:
                'Reels off • Stories off • Posting off • Shared posts off • Messages-only notifications',
            icon: Icons.lock_outline_rounded,
            onTap: () => _selectPreset(FeaturePreferences.strict),
          ),
          const SizedBox(height: 16),

          // 2. Balanced Preset
          _PresetCard(
            key: const ValueKey('onboarding_preset_balanced'),
            title: 'Balanced',
            badge: 'Recommended',
            badgeColor: colorScheme.primary,
            description:
                'Reels on with a budget of 3 • Stories from DMs only • Posting off • Shared posts on • Messages-only notifications',
            icon: Icons.balance_rounded,
            onTap: () => _selectPreset(FeaturePreferences.balanced),
          ),
          const SizedBox(height: 16),

          // 3. Custom Questions
          _PresetCard(
            key: const ValueKey('onboarding_preset_custom'),
            title: 'Custom',
            badge: 'Personalized',
            badgeColor: Colors.teal,
            description:
                'Answer 6 quick questions to tailor reels, stories, posts, and notification filters to your exact habits.',
            icon: Icons.tune_rounded,
            onTap: _startCustomQuestions,
          ),
        ],
      ),
    );
  }

  // --- SUB-STEP 1: Q1 REELS ---
  Widget _buildQ1(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q1_view'),
      questionNumber: 1,
      totalQuestions: 6,
      question: 'Do you want to view reels your friends send you?',
      consequence:
          'If No, all reels are disabled and can be turned on later in Settings.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q1_yes'),
          title: 'Yes',
          subtitle: 'Allow opening single reels sent in chat threads (one at a time)',
          icon: Icons.play_circle_outline_rounded,
          onTap: () => _advanceFromQ1(true),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q1_no'),
          title: 'No',
          subtitle: 'Disable all reels completely (Safest)',
          icon: Icons.block_flipped,
          isSafest: true,
          onTap: () => _advanceFromQ1(false),
        ),
      ],
    );
  }

  // --- SUB-STEP 2: Q2 REEL BUDGET ---
  Widget _buildQ2(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q2_view'),
      questionNumber: 2,
      totalQuestions: 6,
      question: 'How many reels per day?',
      consequence:
          'When your daily budget is reached, further reels are paused until tomorrow.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q2_1'),
          title: '1 reel per day',
          subtitle: 'Strict containment',
          icon: Icons.looks_one_outlined,
          onTap: () => _advanceFromQ2(1),
        ),
        const SizedBox(height: 12),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q2_3'),
          title: '3 reels per day',
          subtitle: 'Balanced default',
          icon: Icons.looks_3_outlined,
          isSafest: true,
          onTap: () => _advanceFromQ2(3),
        ),
        const SizedBox(height: 12),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q2_5'),
          title: '5 reels per day',
          subtitle: 'Moderate allowance',
          icon: Icons.looks_5_outlined,
          onTap: () => _advanceFromQ2(5),
        ),
        const SizedBox(height: 12),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q2_10'),
          title: '10 reels per day',
          subtitle: 'Higher allowance',
          icon: Icons.filter_9_plus_outlined,
          onTap: () => _advanceFromQ2(10),
        ),
        const SizedBox(height: 12),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q2_unlimited'),
          title: 'Unlimited',
          subtitle: 'No daily count restrictions',
          icon: Icons.all_inclusive_rounded,
          onTap: () => _advanceFromQ2(null),
        ),
      ],
    );
  }

  // --- SUB-STEP 3: Q3 STORIES ---
  Widget _buildQ3(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q3_view'),
      questionNumber: 3,
      totalQuestions: 6,
      question: 'Do you want to watch stories?',
      consequence:
          'Stories follow single-user session locks. Watching stories of people you follow is the most distracting option.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q3_no'),
          title: 'No',
          subtitle: 'Block and hide stories everywhere (Safest)',
          icon: Icons.amp_stories_outlined,
          isSafest: true,
          onTap: () => _advanceFromQ3(StoriesViewMode.off),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q3_chats'),
          title: 'Only ones sent in chats',
          subtitle: 'Allow opening stories directly shared by friends in DMs',
          icon: Icons.chat_outlined,
          onTap: () => _advanceFromQ3(StoriesViewMode.fromDmsOnly),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q3_following'),
          title: 'Stories of people I follow',
          subtitle: '⚠️ Warning: Most distracting option. Adds an isolated Stories tab.',
          icon: Icons.people_outline_rounded,
          onTap: () => _advanceFromQ3(StoriesViewMode.fromFollowing),
        ),
      ],
    );
  }

  // --- SUB-STEP 4: Q4 POST STORIES ---
  Widget _buildQ4(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q4_view'),
      questionNumber: 4,
      totalQuestions: 6,
      question: 'Do you want to post stories?',
      consequence:
          'Posting will hand off to your external camera or official app with an explicit sandbox warning.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q4_no'),
          title: 'No',
          subtitle: 'Disable all story posting entry points (Safest)',
          icon: Icons.block_flipped,
          isSafest: true,
          onTap: () => _advanceFromQ4(false),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q4_yes'),
          title: 'Yes',
          subtitle: 'Allow launching external app / camera to post',
          icon: Icons.camera_alt_outlined,
          onTap: () => _advanceFromQ4(true),
        ),
      ],
    );
  }

  // --- SUB-STEP 5: Q5 SHARED POSTS ---
  Widget _buildQ5(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q5_view'),
      questionNumber: 5,
      totalQuestions: 6,
      question: 'Posts your friends send in chats: view or block?',
      consequence:
          'View individual posts shared in DMs, or block feed posts completely.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q5_view'),
          title: 'View',
          subtitle: 'Allow opening single shared posts from chats',
          icon: Icons.image_outlined,
          onTap: () => _advanceFromQ5(true),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q5_block'),
          title: 'Block',
          subtitle: 'Block all shared feed posts (Safest)',
          icon: Icons.block_flipped,
          isSafest: true,
          onTap: () => _advanceFromQ5(false),
        ),
      ],
    );
  }

  // --- SUB-STEP 6: Q6 NOTIFICATIONS ---
  Widget _buildQ6(ThemeData theme, ColorScheme colorScheme) {
    return _QuestionScaffold(
      key: const ValueKey('onboarding_q6_view'),
      questionNumber: 6,
      totalQuestions: 6,
      question: 'Which notifications do you want?',
      consequence:
          'Messages only filters out likes, comments, and follows to protect your attention.',
      onBack: _handleBack,
      onSkip: _handleSkip,
      children: [
        _TappableOptionCard(
          key: const ValueKey('onboarding_q6_messages_only'),
          title: 'Messages only',
          subtitle: 'Direct message alerts only. Filters out algorithmic distractions (Safest)',
          icon: Icons.chat_bubble_outline_rounded,
          isSafest: true,
          onTap: () => _advanceFromQ6(true),
        ),
        const SizedBox(height: 16),
        _TappableOptionCard(
          key: const ValueKey('onboarding_q6_all'),
          title: 'Messages and activity',
          subtitle: 'Messages plus likes, comments, and follower alerts',
          icon: Icons.notifications_none_rounded,
          onTap: () => _advanceFromQ6(false),
        ),
      ],
    );
  }

  // --- SUB-STEP 7: SUMMARY SCREEN ---
  Widget _buildSummary(ThemeData theme, ColorScheme colorScheme) {
    final reelsText = _answers.reelsFromDmsEnabled
        ? 'Allowed (${_answers.dailyReelLimit != null ? "${_answers.dailyReelLimit}/day" : "Unlimited"})'
        : 'Disabled';
    final storiesText = switch (_answers.storiesViewMode) {
      StoriesViewMode.off => 'Off',
      StoriesViewMode.fromDmsOnly =>
        'From DMs only (${_answers.dailyStoryLimit != null ? "${_answers.dailyStoryLimit}/day" : "Unlimited"})',
      StoriesViewMode.fromFollowing =>
        'From Following (${_answers.dailyStoryLimit != null ? "${_answers.dailyStoryLimit}/day" : "Unlimited"})',
    };
    final postingText = _answers.storiesPostingEnabled ? 'Enabled' : 'Disabled';
    final sharedPostsText =
        _answers.sharedPostsFromDmsEnabled ? 'View' : 'Block';
    final notificationsText = _answers.messagesOnlyNotifications
        ? 'Messages only'
        : 'Messages and activity';

    return SingleChildScrollView(
      key: const ValueKey('preferences_summary_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Here's how ZeroScroll will work for you",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your preferences below. Nothing is applied until Confirm.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Choices Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                _SummaryTile(
                  key: const ValueKey('onboarding_edit_reels'),
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Reels from DMs',
                  value: reelsText,
                  onEdit: () => _jumpToEdit(_PreferencesSubStep.q1Reels),
                ),
                const Divider(height: 1),
                _SummaryTile(
                  key: const ValueKey('onboarding_edit_stories'),
                  icon: Icons.amp_stories_outlined,
                  title: 'Stories',
                  value: storiesText,
                  onEdit: () => _jumpToEdit(_PreferencesSubStep.q3Stories),
                ),
                const Divider(height: 1),
                _SummaryTile(
                  key: const ValueKey('onboarding_edit_posting'),
                  icon: Icons.camera_alt_outlined,
                  title: 'Story Posting',
                  value: postingText,
                  onEdit: () => _jumpToEdit(_PreferencesSubStep.q4StoriesPosting),
                ),
                const Divider(height: 1),
                _SummaryTile(
                  key: const ValueKey('onboarding_edit_posts'),
                  icon: Icons.image_outlined,
                  title: 'Shared Posts in Chats',
                  value: sharedPostsText,
                  onEdit: () => _jumpToEdit(_PreferencesSubStep.q5SharedPosts),
                ),
                const Divider(height: 1),
                _SummaryTile(
                  key: const ValueKey('onboarding_edit_notifications'),
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  value: notificationsText,
                  onEdit: () => _jumpToEdit(_PreferencesSubStep.q6Notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Start Over Link
          TextButton(
            key: const ValueKey('onboarding_start_over_btn'),
            onPressed: () {
              setState(() {
                _returnToSummaryAfterEdit = false;
                _currentSubStep = _PreferencesSubStep.presetChooser;
              });
            },
            child: const Text('Change Preset'),
          ),
          const SizedBox(height: 12),

          // Confirm Button
          FilledButton(
            key: const ValueKey('onboarding_preferences_confirm_btn'),
            onPressed: () async {
              final confirmed = _answers.copyWith(hasChosenFeatures: true);
              await widget.onConfirmed(confirmed);
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm & Continue',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE COMPONENTS ---

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    super.key,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String badge;
  final Color badgeColor;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: badgeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionScaffold extends StatelessWidget {
  const _QuestionScaffold({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
    required this.question,
    required this.consequence,
    required this.onBack,
    required this.onSkip,
    required this.children,
  });

  final int questionNumber;
  final int totalQuestions;
  final String question;
  final String consequence;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Back, Progress Dots, Skip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const ValueKey('onboarding_question_back_btn'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
                tooltip: 'Back',
              ),
              // Progress Dots
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalQuestions, (index) {
                  final isActive = index == (questionNumber - 1);
                  final isPassed = index < (questionNumber - 1);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: isActive
                          ? colorScheme.primary
                          : (isPassed
                              ? colorScheme.primary.withValues(alpha: 0.4)
                              : colorScheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                  );
                }),
              ),
              TextButton(
                key: const ValueKey('onboarding_question_skip_btn'),
                onPressed: onSkip,
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Question Title
          Text(
            question,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Consequence Line
          Text(
            consequence,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Options
          ...children,
        ],
      ),
    );
  }
}

class _TappableOptionCard extends StatelessWidget {
  const _TappableOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSafest = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSafest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSafest
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSafest ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSafest
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isSafest ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isSafest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Safest',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
