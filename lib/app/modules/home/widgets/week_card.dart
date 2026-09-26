import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/services/streak/streak_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/streak_flame.dart';
import '../../../core/widgets/week_strip.dart';

/// The streak and the week behind it, in one card below the hero.
///
/// Both of these used to live in the hero panel, where they competed with
/// the day's goal and the button. The streak pill then spent a version up
/// beside the greeting, where it collided with the floating account avatar
/// in the same corner.
///
/// Here they finally sit together, which is where they belonged: the pill
/// is how long you've kept it up, the strip is which days - one claim and
/// its evidence. Amber runs through both, so they read as one thing and
/// stay clear of coral, which means "tap this".
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.days,
    required this.streak,
    required this.replayToken,
  });

  final List<bool> days;
  final StudyStreak streak;
  final int replayToken;

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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _streakLine,
                  style: AppTextStyles.caption.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          WeekStrip(days: days),
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
}
