import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/services/streak/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/daily_goal_ring.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/streak_flame.dart';
import '../../../core/widgets/study_mode_sheet.dart';
import '../../../core/widgets/week_strip.dart';
import '../../../data/models/study_mode.dart';

/// Home's single focal panel: how you're doing, and the one thing to do
/// about it today.
///
/// Streak, week and goal are per-user facts, so they belong here at the
/// root rather than on any individual deck. The review action lives
/// inside the same card because those numbers are precisely what it
/// moves - tapping it and coming back should visibly change this panel.
class TodayHeroCard extends StatelessWidget {
  const TodayHeroCard({
    super.key,
    required this.streak,
    required this.weekProgress,
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
  final List<bool> weekProgress;

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
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StreakFlame(
                count: streak.current,
                replayToken: replayToken,
                celebrate: streak.goalMet,
              ),
              const Spacer(),
              _ModeChip(mode: mode),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WeekStrip(days: weekProgress),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              DailyGoalRing(
                from: previousGoalProgress,
                to: streak.goalProgress,
                reviewsToday: streak.reviewsToday,
                goalMet: streak.goalMet,
                replayToken: replayToken,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.colorInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _streakLine,
                      style: AppTextStyles.caption.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                  ],
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

  String get _streakLine {
    if (streak.current == 0) return LocaleKeys.homeStreakStartHint.tr;

    final days = LocaleKeys.studyStreakDays.trParams({
      'count': '${streak.current}',
    });
    if (streak.longest <= streak.current) return days;

    final best = LocaleKeys.homeStreakBest.trParams({
      'count': '${streak.longest}',
    });
    return '$days · $best';
  }

  Widget _buildAction(BuildContext context) {
    if (isLoading && !hasDecks) {
      return Container(
        key: const ValueKey('loading'),
        height: 52,
        decoration: BoxDecoration(
          color: context.colorBorder.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      );
    }

    // Nothing to study yet: the scan tile below carries the screen.
    if (!hasDecks) return const SizedBox.shrink(key: ValueKey('empty'));

    if (sessionSize == 0) {
      return Column(
        key: const ValueKey('caught-up'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.confirm,
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.confirm,
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
                color: context.colorInkMuted,
              ),
            ),
          ],
        ],
      );
    }

    final isListening = mode == StudyMode.listen;

    return PressScale(
      key: const ValueKey('review'),
      onTap: onStart,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
                Text(
                  isListening
                      ? LocaleKeys.deckListen.tr
                      : sessionSize == 1
                      ? LocaleKeys.homeReviewCtaOne.tr
                      : LocaleKeys.homeReviewCta.trParams({
                          'count': '$sessionSize',
                        }),
                  style: AppTextStyles.button.copyWith(color: Colors.white),
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
}

/// Opens the study-mode picker. Small on purpose: the mode is a setting
/// people change rarely, so it shouldn't compete with the action.
class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final StudyMode mode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorPaper,
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
                color: context.colorInkMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                studyModeLabels[mode]!.tr,
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: context.colorInkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
