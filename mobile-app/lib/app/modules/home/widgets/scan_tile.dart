import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/locale_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/press_scale.dart';

/// The entry point into scanning, fronted by a small animated viewfinder.
///
/// The design tokens reserve coral for the primary action "and the
/// scan-line motif" - this is that motif. The line sweeps once and then
/// rests, so the tile has life without becoming something that twitches
/// in the corner of your eye while you read the rest of the screen.
class ScanTile extends StatelessWidget {
  const ScanTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colorBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const _Viewfinder(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.homeScanCtaTitle.tr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.colorInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleKeys.homeScanCtaSubtitle.tr,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: context.colorInkMuted),
          ],
        ),
      ),
    );
  }
}

class _Viewfinder extends StatefulWidget {
  const _Viewfinder();

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder>
    with SingleTickerProviderStateMixin {
  static const _size = 60.0;

  /// The full cycle. The sweep occupies the first stretch of it and the
  /// remainder is deliberate stillness.
  static const _cycle = Duration(milliseconds: 2600);
  static const _sweepEnd = 0.54;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  late final Animation<double> _sweep = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, _sweepEnd, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the repainting line from dirtying the rest of the tile.
    return RepaintBoundary(
      child: SizedBox(
        height: _size,
        width: _size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: context.colorPaper),
              CustomPaint(
                size: const Size.square(_size),
                painter: _CornerBracketsPainter(
                  color: AppColors.accent.withValues(alpha: 0.55),
                ),
              ),
              AnimatedBuilder(
                animation: _sweep,
                builder: (context, _) {
                  final progress = _sweep.value;
                  return Align(
                    alignment: Alignment(0, -1 + 2 * progress),
                    child: Opacity(
                      // Fades in and out at the ends of the travel so the
                      // line never pops into or out of existence.
                      opacity: math.sin(math.pi * progress),
                      child: Container(
                        height: 2,
                        width: _size,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.accent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four corner brackets, echoing the framing marks in the app icon.
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter({required this.color});

  final Color color;

  static const _inset = 7.0;
  static const _arm = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = _inset;
    final top = _inset;
    final right = size.width - _inset;
    final bottom = size.height - _inset;

    canvas
      ..drawPath(
        Path()
          ..moveTo(left, top + _arm)
          ..lineTo(left, top)
          ..lineTo(left + _arm, top),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(right - _arm, top)
          ..lineTo(right, top)
          ..lineTo(right, top + _arm),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(right, bottom - _arm)
          ..lineTo(right, bottom)
          ..lineTo(right - _arm, bottom),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(left + _arm, bottom)
          ..lineTo(left, bottom)
          ..lineTo(left, bottom - _arm),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _CornerBracketsPainter oldDelegate) =>
      oldDelegate.color != color;
}
