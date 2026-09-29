import 'package:flutter/material.dart';

import '../services/streak/streak_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/study_day.dart';

/// The last seven study days, oldest first, each dot under its weekday
/// letter.
///
/// A streak number says how long you've kept it up; this says which days
/// you actually showed up - including the gap you're about to create by
/// skipping today, which is the part that motivates.
///
/// The letters matter: seven bare dots tell you *how many* days you
/// managed but not *which*, so "I always skip Sundays" is invisible. They
/// come from [MaterialLocalizations], so they follow the app's locale
/// instead of hardcoding English initials.
///
/// Studied days are amber, not coral. Coral means "tap this" everywhere
/// else in the app, and history isn't tappable - amber is the streak's
/// colour, shared with [StreakFlame]. Frozen days are sky-blue with a
/// snowflake: the streak survived them, and the strip should say how,
/// rather than quietly drawing them as though they were studied.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days});

  /// Seven days, oldest first. The last entry is today.
  final List<StreakDay> days;

  static const _dotSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final narrowWeekdays = MaterialLocalizations.of(context).narrowWeekdays;
    // The study day, not the calendar day: between midnight and 4am the
    // last dot is still yesterday, and labelling it with today's letter
    // would misreport which day was studied - or which one a freeze saved.
    final today = studyDayStart(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var index = 0; index < days.length; index++)
          _Day(
            // `days` is oldest-first and ends on today, so the entry at
            // `index` is that many days back from the end. Built from
            // calendar components, not by subtracting 24-hour durations,
            // so a daylight-saving change can't shift a letter.
            letter:
                narrowWeekdays[DateTime(
                      today.year,
                      today.month,
                      today.day - (days.length - 1 - index),
                    ).weekday %
                    7],
            state: days[index],
            isToday: index == days.length - 1,
            // Staggered so the strip fills in left to right, reading as
            // history accumulating rather than seven dots blinking on.
            delayMilliseconds: index * 40,
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.letter,
    required this.state,
    required this.isToday,
    required this.delayMilliseconds,
  });

  final String letter;
  final StreakDay state;
  final bool isToday;
  final int delayMilliseconds;

  @override
  Widget build(BuildContext context) {
    final (fill, icon) = switch (state) {
      StreakDay.studied => (
        AppColors.amber.resolve(context),
        Icons.check_rounded,
      ),
      StreakDay.frozen => (
        AppColors.sky.resolve(context),
        Icons.ac_unit_rounded,
      ),
      StreakDay.missed => (context.colorBorder, null),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          letter,
          style: AppTextStyles.label.copyWith(
            color: isToday ? context.colorInk : context.colorInkMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 240 + delayMilliseconds),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: child),
          child: Container(
            height: WeekStrip._dotSize,
            width: WeekStrip._dotSize,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              // Today gets a ring while it's still unearned, so the one
              // day you can still do something about stands out.
              border: isToday && state == StreakDay.missed
                  ? Border.all(color: AppColors.accent, width: 2)
                  : null,
            ),
            child: icon == null
                ? null
                : Icon(icon, color: Colors.white, size: 15),
          ),
        ),
      ],
    );
  }
}
