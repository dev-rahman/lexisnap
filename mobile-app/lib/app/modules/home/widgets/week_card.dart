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
/// The pill is how long you've kept it up, the strip is which days - one
/// claim and its evidence. Amber runs through both, so they read as one
/// thing and stay clear of coral, which means "tap this".
///
/// Freezes live here too, in sky-blue: a chip for the ones banked, a line
/// counting down to the next, and - on the day one is spent - a line
/// saying so. That last one is the moment the whole feature exists for.
/// Coming back after a missed day to "your streak survived" rather than to
/// a zero is what keeps a bad week from becoming the week someone quit.
class WeekCard extends StatelessWidget {
  const WeekCard({
    super.key,
    required this.days,
    required this.streak,
    required this.replayToken,
    required this.justCovered,
    required this.daysToNextFreeze,
    required this.onTap,
  });

  final List<StreakDay> days;
  final StudyStreak streak;
  final int replayToken;

  /// Missed days a freeze has just covered - non-zero only on the day back.
  final int justCovered;

  /// Null once the bank is full.
  final int? daysToNextFreeze;

  /// Opens the explanation of how streaks and freezes work.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sky = AppColors.sky.resolve(context);
    final subline = _subline;

    // The whole card is the tap target, not just the flame: anything here
    // - the pill, the chip, a snowflake in the strip - is a reasonable
    // thing to tap when wondering "what does this mean?".
    return Material(
      color: context.colorSurface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.colorBorder),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                  if (streak.freezes > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _FreezeChip(count: streak.freezes),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          justCovered > 0 ? _savedLine : _streakLine,
                          style: AppTextStyles.caption.copyWith(
                            // The saved notice takes the freeze's colour, so
                            // it reads as news rather than the usual caption.
                            color: justCovered > 0
                                ? sky
                                : context.colorInkMuted,
                            fontWeight: justCovered > 0
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                        if (subline != null)
                          Text(
                            subline,
                            style: AppTextStyles.caption.copyWith(
                              color: context.colorInkMuted.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Says the card opens something, without competing with it.
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: context.colorInkMuted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              WeekStrip(days: days),
            ],
          ),
        ),
      ),
    );
  }

  String get _savedLine => justCovered == 1
      ? LocaleKeys.streakFreezeSavedOne.tr
      : LocaleKeys.streakFreezeSavedMany.trParams({'count': '$justCovered'});

  /// Progress toward the next freeze. Omitted with no streak to protect -
  /// the start-your-streak hint already says what to do - and omitted when
  /// the bank is full, since there is nothing left to earn.
  String? get _subline {
    final remaining = daysToNextFreeze;
    if (streak.current == 0 || remaining == null) return null;
    return remaining == 1
        ? LocaleKeys.streakFreezeNextOne.tr
        : LocaleKeys.streakFreezeNext.trParams({'count': '$remaining'});
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

/// Banked freezes, beside the flame. Sized and shaped like the flame pill
/// so the two read as a pair: the streak, and what's protecting it.
class _FreezeChip extends StatelessWidget {
  const _FreezeChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final sky = AppColors.sky.resolve(context);

    return Semantics(
      label: LocaleKeys.streakFreezesReady.trParams({'count': '$count'}),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.sky.tint(context),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ac_unit_rounded, color: sky, size: 18),
            const SizedBox(width: 2),
            Text(
              '$count',
              style: AppTextStyles.bodyMedium.copyWith(
                color: sky,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
