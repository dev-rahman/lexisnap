import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Today's reviews against the daily goal, as a ring with the count in it.
///
/// Tweens from [from] to [to] rather than from zero, so coming back from
/// a session shows the progress that session actually earned.
class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.from,
    required this.to,
    required this.reviewsToday,
    required this.goalMet,
    this.replayToken = 0,
    this.size = 60,
  });

  final double from;
  final double to;
  final int reviewsToday;
  final bool goalMet;
  final int replayToken;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Goal-met uses `confirm`, not `success`: the design tokens reserve
    // success/error for grading a flashcard.
    final color = goalMet ? AppColors.confirm : AppColors.accent;

    return TweenAnimationBuilder<double>(
      key: ValueKey(replayToken),
      tween: Tween(begin: from, end: to),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: context.colorBorder,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              if (goalMet)
                Icon(Icons.check_rounded, color: color, size: size * 0.42)
              else
                Text(
                  '$reviewsToday',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colorInk,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.3,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
