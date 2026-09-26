import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's gradients, kept here so "colourful" stays a system rather
/// than a thing each screen improvises.
///
/// Gradients are used in exactly two places and nowhere else: the primary
/// action, and the ring that tracks the day. A gradient is an attention
/// device, so spreading it over every surface spends the effect and leaves
/// nothing pointing at the thing to tap.
class AppGradients {
  AppGradients._();

  /// The primary action's fill: full-strength coral into amber-orange,
  /// left to right. Carries white text, so both stops stay dark enough
  /// for it in either theme - which is why this one isn't theme-aware.
  static const LinearGradient action = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.accent, Color(0xFFF08A3C)],
  );

  /// The goal ring's sweep, so progress warms up as it fills rather than
  /// being one flat arc. Starts at the top (-90°) to match where the ring
  /// begins drawing.
  static SweepGradient ring(Color from, Color to) => SweepGradient(
    startAngle: -1.5707963267948966,
    endAngle: 4.71238898038469,
    colors: [from, to],
  );
}
