import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One segment per card in the session, filling left to right.
///
/// A segmented bar answers "how much is left?" at a glance in a way a
/// continuous bar can't - the learner can count the remaining ticks, which
/// is what makes a capped session feel finishable rather than open-ended.
class SessionProgressBar extends StatelessWidget {
  const SessionProgressBar({
    super.key,
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  /// Past this many cards the ticks get too thin to read, so the bar
  /// falls back to a continuous fill.
  static const _maxSegments = 24;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox(height: 6);

    final track = context.colorBorder;

    if (total > _maxSegments) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: completed / total,
          minHeight: 6,
          backgroundColor: track,
          valueColor: const AlwaysStoppedAnimation(AppColors.accent),
        ),
      );
    }

    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index != 0) const SizedBox(width: 3),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                decoration: BoxDecoration(
                  color: index < completed ? AppColors.accent : track,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
