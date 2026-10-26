import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_text_styles.dart';

/// Today's reviews against the daily goal, as a ring with the count in it.
///
/// Tweens from [from] to [to] rather than from zero, so coming back from
/// a session shows the progress that session actually earned.
///
/// The arc is painted rather than handed to [CircularProgressIndicator],
/// which only takes a flat colour. The gradient is the point: progress
/// warms from coral into amber as it goes round, so how far along you are
/// is legible from the hue alone, before you've read the number.
class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({
    super.key,
    required this.from,
    required this.to,
    required this.reviewsToday,
    required this.goalMet,
    this.replayToken = 0,
    this.size = 64,
    this.onDark = false,
  });

  final double from;
  final double to;
  final int reviewsToday;
  final bool goalMet;
  final int replayToken;
  final double size;

  /// Set when the ring sits on a dark panel. The track and the number are
  /// the only theme-aware parts; the progress gradient reads correctly on
  /// either background, so it doesn't change.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    // Goal-met uses `confirm`/moss, not `success`: the design tokens
    // reserve success/error for grading a flashcard.
    final (fromColor, toColor) = goalMet
        ? (AppColors.confirm, AppColors.moss.resolve(context))
        : (AppColors.accent, AppColors.amber.resolve(context));

    return TweenAnimationBuilder<double>(
      key: ValueKey(replayToken),
      tween: Tween(begin: from, end: to),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: size,
          width: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              track: onDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : context.colorBorder,
              gradient: AppGradients.ring(fromColor, toColor),
            ),
            child: Center(
              child: goalMet
                  ? Icon(Icons.check_rounded, color: toColor, size: size * 0.42)
                  : Text(
                      '$reviewsToday',
                      style: AppTextStyles.display.copyWith(
                        color: onDark ? Colors.white : context.colorInk,
                        fontSize: size * 0.32,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.gradient,
  });

  final double progress;
  final Color track;
  final SweepGradient gradient;

  static const _stroke = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(_stroke / 2);

    canvas.drawCircle(
      inset.center,
      inset.width / 2,
      Paint()
        ..color = track
        ..strokeWidth = _stroke
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      inset,
      -math.pi / 2,
      // Never quite a full turn: a 360° arc with round caps laps its own
      // start and leaves a visible notch where the two ends meet.
      2 * math.pi * progress.clamp(0.0, 0.999),
      false,
      Paint()
        ..shader = gradient.createShader(inset)
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.track != track;
}
