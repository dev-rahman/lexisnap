import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The user's current study streak, as a compact flame pill.
///
/// The number counts up rather than appearing, so returning from a
/// session that extended the streak reads as something being earned.
class StreakFlame extends StatelessWidget {
  const StreakFlame({
    super.key,
    required this.count,
    this.replayToken = 0,
    this.celebrate = false,
  });

  final int count;

  /// Bumped by the caller to replay the animation - after a session, so
  /// the streak visibly ticks up on the screen the user lands back on.
  final int replayToken;

  /// Adds a one-shot pop, used when the day's goal has just been met.
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final isDim = count == 0;
    final color = isDim ? context.colorInkMuted : AppColors.accent;

    return TweenAnimationBuilder<double>(
      key: ValueKey(replayToken),
      tween: Tween(begin: 0, end: count.toDouble()),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDim ? 0.08 : 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Flame(color: color, celebrate: celebrate),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${value.round()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Flame extends StatelessWidget {
  const _Flame({required this.color, required this.celebrate});

  final Color color;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.local_fire_department_rounded,
      color: color,
      size: 20,
    );

    if (!celebrate) return icon;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      // Overshoot and settle, so hitting the goal registers without
      // anything continuing to move afterwards.
      builder: (context, value, child) {
        final scale = 1 + 0.18 * (value < 0.5 ? value * 2 : (1 - value) * 2);
        return Transform.scale(scale: scale, child: child);
      },
      child: icon,
    );
  }
}
