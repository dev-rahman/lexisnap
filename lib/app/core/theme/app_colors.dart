import 'package:flutter/material.dart';

/// LexiSnap design tokens, drawn from the three colors in the app icon
/// (ink-navy tile, paper-white flashcard, coral folded corner). Change
/// values here to re-theme the whole app.
class AppColors {
  AppColors._();

  // Ink: the brand/identity color - text, the icon tile, anything that
  // should read as "brand." Sampled directly from the app icon artwork.
  static const Color ink = Color(0xFF1C2541);
  static const Color inkMuted = Color(0xFF5C6178);

  // Paper: the default background. Warm, not stark white. Sampled from the
  // app icon's flashcard/background - keep this exact so the app icon and
  // wordmark art (which bake this color in) blend seamlessly into screens.
  static const Color paper = Color(0xFFF7F4EE);

  // Surface/border: quiet neutrals cards and dividers sit on.
  static const Color surface = Color(0xFFEDE9DF);
  static const Color border = Color(0xFFDFD9CD);

  // Accent: coral, reserved for the single primary action on a screen and
  // the scan-line motif. Keep it rare so it keeps its pull. Sampled from
  // the app icon's folded corner.
  static const Color accent = Color(0xFFE7623C);
  static const Color accent600 = Color(0xFFBD5031); // pressed/hover state

  // Reserved for flashcard review (marking a card right or wrong) only -
  // do not reuse for generic system/form error states, see [alert].
  static const Color success = Color(0xFF2E9E5B);
  static const Color error = Color(0xFFE5484D);

  // Generic system states (failed requests/validation, and general
  // confirmation toasts) - kept visually distinct (muted, darker) from the
  // bright review [error]/[success] colors so those stay exclusive to
  // flashcard review.
  static const Color alert = Color(0xFFA33B2A);
  static const Color confirm = Color(0xFF3D7A57);

  // Dark-mode variants. The brief only specifies a light system so far;
  // these are a reasonable first pass, not part of the spec yet.
  static const Color inkDark = Color(0xFFF3F1EA);
  static const Color inkMutedDark = Color(0xFFB4B7C8);
  static const Color paperDark = Color(0xFF14162A);
  static const Color surfaceDark = Color(0xFF1E2138);
  static const Color borderDark = Color(0xFF343854);
}
