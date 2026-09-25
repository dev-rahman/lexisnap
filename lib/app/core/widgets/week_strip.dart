import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The last seven study days as a row of dots, oldest first.
///
/// A streak number says how long you've kept it up; this says which days
/// you actually showed up - including the gap you're about to create by
/// skipping today, which is the part that motivates.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days});

  /// Seven flags, oldest first. The last entry is today.
  final List<bool> days;

  static const _dotSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          if (index != 0) const SizedBox(width: AppSpacing.xs),
          _Dot(
            isStudied: days[index],
            isToday: index == days.length - 1,
            // Staggered so the strip fills in left to right, reading as
            // history accumulating rather than seven dots blinking on.
            delayMilliseconds: index * 40,
          ),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.isStudied,
    required this.isToday,
    required this.delayMilliseconds,
  });

  final bool isStudied;
  final bool isToday;
  final int delayMilliseconds;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + delayMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        height: WeekStrip._dotSize,
        width: WeekStrip._dotSize,
        decoration: BoxDecoration(
          color: isStudied ? AppColors.accent : context.colorBorder,
          shape: BoxShape.circle,
          border: isToday && !isStudied
              ? Border.all(color: context.colorInkMuted, width: 1.5)
              : null,
        ),
      ),
    );
  }
}
