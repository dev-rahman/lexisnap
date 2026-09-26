import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/services/streak/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/daily_goal_ring.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/study_mode_sheet.dart';
import '../../../data/models/study_mode.dart';

/// Home's focal panel: where today stands, and the one thing to do about it.
///
/// This used to carry the streak pill and the week strip as well, which
/// made five separate things compete inside one card - and the thing that
/// mattered, the button, was the last of them. Both now live in the week
/// card below, leaving this panel with one job: progress, then the action
/// that moves it.
///
/// Navy is what marks it as *the* panel on the screen. The first attempt
/// used a low-alpha coral gradient over paper, which came out muddy peach;
/// solid navy is both louder and more readable, and coral on navy has far
/// more pull than coral on a coral tint. Everything in here is therefore
/// white or near-white rather than theme-aware - the panel is dark in both
/// themes, so its contents don't flip.
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.streak,
    required this.sessionSize,
    required this.reviewMinutes,
    required this.mode,
    required this.previousGoalProgress,
    required this.replayToken,
    required this.hasDecks,
    required this.isLoading,
    required this.onStart,
    required this.canPractice,
    required this.practiceCount,
    required this.isLoadingPractice,
    required this.onPractice,
  });

  final StudyStreak streak;

  /// Cards this session will actually serve - not the whole due backlog,
  /// which the session caps. The button has to promise what it delivers.
  final int sessionSize;
  final int reviewMinutes;
  final StudyMode mode;

  /// Where the goal ring should animate from, so returning from a session
  /// replays the progress that session earned instead of jumping.
  final double previousGoalProgress;
  final int replayToken;

  final bool hasDecks;
  final bool isLoading;
  final VoidCallback onStart;

  /// Whether an extra, ahead-of-schedule round is available once the day's
  /// reviews are cleared.
  final bool canPractice;
  final int practiceCount;
  final bool isLoadingPractice;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colorPanel,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On its own row rather than beside the ring: sharing that row
          // squeezed the count and the streak line into what was left of
          // a small phone's width after a 64px ring and a 90px chip.
          Align(
            alignment: Alignment.centerRight,
            child: _ModeChip(mode: mode),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              DailyGoalRing(
                onDark: true,
                from: previousGoalProgress,
                to: streak.goalProgress,
                reviewsToday: streak.reviewsToday,
                goalMet: streak.goalMet,
                replayToken: replayToken,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  // Past the goal, "47 of 10" reads like a bug - the
                  // ring's check already says the goal was met.
                  streak.goalMet
                      ? LocaleKeys.homeCardsToday.trParams({
                          'count': '${streak.reviewsToday}',
                        })
                      : LocaleKeys.homeGoalToday.trParams({
                          'done': '${streak.reviewsToday}',
                          'goal': '${streak.dailyGoal}',
                        }),
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: _buildAction(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (isLoading && !hasDecks) {
      return Container(
        key: const ValueKey('loading'),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      );
    }

    // Nothing to study yet: the scan tile below carries the screen.
    if (!hasDecks) return const SizedBox.shrink(key: ValueKey('empty'));

    if (sessionSize == 0) return _buildCaughtUp(context);

    final isListening = mode == StudyMode.listen;

    return PressScale(
      key: const ValueKey('review'),
      onTap: onStart,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: AppGradients.action,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isListening
                      ? Icons.headphones_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                // Flexible, not bare: the label is translated, and the
                // longest locales ("13 Karten wiederholen") leave almost
                // no room on a 320px phone. Wrapping to a second line is
                // survivable; overflowing is not.
                Flexible(
                  child: Text(
                    isListening
                        ? LocaleKeys.deckListen.tr
                        : sessionSize == 1
                        ? LocaleKeys.homeReviewCtaOne.tr
                        : LocaleKeys.homeReviewCta.trParams({
                            'count': '$sessionSize',
                          }),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            if (!isListening) ...[
              const SizedBox(height: 2),
              Text(
                LocaleKeys.homeReviewEstimate.trParams({
                  'count': '$reviewMinutes',
                }),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaughtUp(BuildContext context) {
    return Column(
      key: const ValueKey('caught-up'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // `confirm` is a dark green tuned for paper - on navy it comes
            // out at roughly 2.5:1. Moss's dark value is the same idea at
            // a contrast that works here.
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.moss.dark,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                // "Come back tomorrow" is a lie once there's an extra
                // round on offer right below it.
                canPractice
                    ? LocaleKeys.homeCaughtUpToday.tr
                    : LocaleKeys.homeAllCaughtUp.tr,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.moss.dark,
                ),
              ),
            ),
          ],
        ),
        // Clearing the day is an achievement, not a locked door. Someone
        // who wants to keep going gets another short round - outlined,
        // not filled, because it's a bonus rather than the day's work.
        if (canPractice) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            variant: AppButtonVariant.outlined,
            color: Colors.white,
            label: LocaleKeys.homePracticeCta.trParams({
              'count': '$practiceCount',
            }),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            isLoading: isLoadingPractice,
            onPressed: onPractice,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.homePracticeNote.tr,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Opens the study-mode picker. Small on purpose: the mode is a setting
/// people change rarely, so it shouldn't compete with the action.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final StudyMode mode;

  @override
  Widget build(BuildContext context) {
    return Material(
      // On the navy panel, so it tints the panel rather than punching a
      // paper-coloured hole in it.
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => showStudyModeSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                studyModeIcons[mode],
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                studyModeLabels[mode]!.tr,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
