import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/services/streak/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/review_grade.dart';

/// The end-of-session screen.
///
/// Deliberately leads with streak and daily goal rather than the grade
/// breakdown: what keeps spaced repetition working is coming back
/// tomorrow, so that is what the screen rewards.
class SessionSummary extends StatelessWidget {
  const SessionSummary({
    super.key,
    required this.reviewedCount,
    required this.accuracy,
    required this.tally,
    required this.streak,
    required this.remainingDueCount,
    required this.onDone,
    required this.onContinue,
  });

  final int reviewedCount;
  final double accuracy;
  final Map<ReviewGrade, int> tally;
  final StudyStreak streak;

  /// Cards that were due but fell outside this session's cap.
  final int remainingDueCount;

  final VoidCallback onDone;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _AccuracyRing(accuracy: accuracy),
          const SizedBox(height: AppSpacing.lg),
          Text(
            LocaleKeys.studyCompleteTitle.tr,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.studyCompleteBody.trParams({'count': '$reviewedCount'}),
            style: AppTextStyles.body.copyWith(color: context.colorInkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _StreakCard(streak: streak),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final grade in ReviewGrade.values)
                if ((tally[grade] ?? 0) > 0)
                  _TallyChip(
                    color: gradeColors[grade]!,
                    label: gradeLabels[grade]!.tr,
                    count: tally[grade]!,
                  ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg * 1.5),
          if (remainingDueCount > 0) ...[
            AppButton(
              label: LocaleKeys.studyContinue.trParams({
                'count': '$remainingDueCount',
              }),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              onPressed: onContinue,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              variant: AppButtonVariant.text,
              label: LocaleKeys.studyDone.tr,
              onPressed: onDone,
            ),
          ] else
            AppButton(label: LocaleKeys.studyDone.tr, onPressed: onDone),
        ],
      ),
    );
  }
}

/// Grade colors and labels, shared with anywhere else that shows a tally.
const gradeColors = {
  ReviewGrade.again: AppColors.error,
  ReviewGrade.hard: Color(0xFFD98A3D),
  ReviewGrade.good: AppColors.success,
  ReviewGrade.easy: Color(0xFF3B82C4),
};

const gradeLabels = {
  ReviewGrade.again: LocaleKeys.studyGradeAgain,
  ReviewGrade.hard: LocaleKeys.studyGradeHard,
  ReviewGrade.good: LocaleKeys.studyGradeGood,
  ReviewGrade.easy: LocaleKeys.studyGradeEasy,
};

class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({required this.accuracy});

  final double accuracy;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: accuracy),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: 132,
          width: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: context.colorSurface,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: AppTextStyles.heading1.copyWith(
                      color: context.colorInk,
                    ),
                  ),
                  Text(
                    LocaleKeys.studyAccuracy.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final StudyStreak streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                streak.current <= 1
                    ? LocaleKeys.studyStreakStarted.tr
                    : LocaleKeys.studyStreakDays.trParams({
                        'count': '${streak.current}',
                      }),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colorInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: streak.goalProgress,
              minHeight: 8,
              backgroundColor: context.colorBorder,
              valueColor: AlwaysStoppedAnimation(
                streak.goalMet ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            streak.goalMet
                ? LocaleKeys.studyGoalMet.tr
                : LocaleKeys.studyGoalProgress.trParams({
                    'done': '${streak.reviewsToday}',
                    'goal': '${streak.dailyGoal}',
                  }),
            style: AppTextStyles.caption.copyWith(
              color: streak.goalMet
                  ? AppColors.success
                  : context.colorInkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TallyChip extends StatelessWidget {
  const _TallyChip({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$count $label',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
