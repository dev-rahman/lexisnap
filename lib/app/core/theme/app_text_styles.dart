import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LexiSnap type scale. Space Grotesk carries the display sizes (screen
/// titles, deck names) - distinctive enough to double as the wordmark face.
/// Everything else uses the native system font stack, which keeps
/// flashcard content fast and legible on both iOS and Android.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading1 => GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get heading2 => GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
