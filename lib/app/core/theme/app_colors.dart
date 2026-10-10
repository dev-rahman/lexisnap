import 'package:flutter/material.dart';

/// LexiSnap design tokens, drawn from the three colors in the app icon
/// (ink-navy tile, paper-white flashcard, coral folded corner). Change
/// values here to re-theme the whole app.
/// One hue from the additive palette, with its dark-mode twin.
///
/// A hue is a pair, not a colour, because every use of it has to work on
/// both backgrounds. Holding them together makes picking only one of them
/// awkward, which is the point.
class AppHue {
  const AppHue(this.name, this.light, this.dark);

  /// Identifies the hue in debug output; not shown to users.
  final String name;

  final Color light;
  final Color dark;

  /// The value to actually paint with.
  Color resolve(BuildContext context) => context.isDarkMode ? dark : light;

  /// A background wash of this hue - for a tile or a card that should read
  /// as belonging to the hue without shouting it. Dark mode needs more
  /// alpha because a translucent colour over a dark surface loses its
  /// identity much faster than over paper.
  Color tint(BuildContext context) =>
      resolve(context).withValues(alpha: context.isDarkMode ? 0.22 : 0.12);
}

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

  // Panel: the background of the one focal card on a screen (Home's
  // progress panel). Deep navy in both themes.
  //
  // This replaced a low-alpha coral/amber gradient washed over paper,
  // which came out muddy peach - a tint that weak reads as a printing
  // fault rather than a colour. Solid navy is both more colourful *and*
  // more legible: white on it clears 16:1, so the panel can carry a
  // caption, and coral sitting on navy is far louder than coral sitting
  // on a coral-tinted card.
  static const Color panel = ink;
  static const Color panelDark = Color(0xFF252A4A);

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

  // [caution]: a deep amber for warning toasts - something happened that the
  // user should notice but that isn't a failure (e.g. duplicate cards
  // skipped). [notice]: a muted blue for neutral/info toasts. Both sit in the
  // same darkened register as [alert]/[confirm] so the four toast tones read
  // as one family, each dark enough to carry white text.
  static const Color caution = Color(0xFFA8701A);
  static const Color notice = Color(0xFF2F6AA6);

  // ---------------------------------------------------------------------
  // Hues: the additive palette.
  //
  // These do NOT compete with [accent]. Coral still means "the primary
  // action here", and it stays the only thing that means that. These carry
  // the two jobs a single accent can't do: *identity* (which deck is this)
  // and *data* (which number am I looking at). A screen full of decks that
  // are all the same grey is harder to use than one where your Spanish
  // deck is always teal - that's recognition instead of reading.
  //
  // Each hue ships a dark-mode twin, lightened so it keeps roughly the
  // same contrast against [paperDark] that the light value has against
  // [paper]. Always resolve through [AppHue.resolve], never pick a raw
  // value, or dark mode goes muddy.
  // ---------------------------------------------------------------------

  static const AppHue teal = AppHue(
    'teal',
    Color(0xFF2A9D8F),
    Color(0xFF4FC3B5),
  );
  static const AppHue violet = AppHue(
    'violet',
    Color(0xFF7C5CD3),
    Color(0xFFA28BEA),
  );
  static const AppHue amber = AppHue(
    'amber',
    Color(0xFFE9A23B),
    Color(0xFFF3BC6A),
  );
  static const AppHue rose = AppHue(
    'rose',
    Color(0xFFD9547B),
    Color(0xFFEC7D9D),
  );
  static const AppHue sky = AppHue('sky', Color(0xFF3B82C4), Color(0xFF6FAEE4));
  static const AppHue moss = AppHue(
    'moss',
    Color(0xFF5A9E4B),
    Color(0xFF83C275),
  );

  /// [accent] as an [AppHue], so a widget that colours itself by hue can
  /// use the action colour without a special case. The same value in both
  /// themes - coral was picked to read correctly on paper and paperDark
  /// alike, which is why it has no dark twin anywhere else either.
  static const AppHue accentHue = AppHue('accent', accent, accent);

  /// The rotation decks are coloured from. Ordered so neighbours in a list
  /// land on clearly different hues rather than two adjacent blues.
  static const List<AppHue> deckHues = [teal, amber, violet, moss, rose, sky];

  /// A stable hue for [seed], normally a deck id.
  ///
  /// Deliberately not `seed.hashCode`: Dart makes no promise that string
  /// hashes stay the same across runs or platforms, and a deck that was
  /// teal yesterday and violet today is worse than no colour at all. This
  /// is a plain FNV-1a fold, so the same id always lands on the same hue.
  static AppHue hueFor(String seed) {
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return deckHues[hash % deckHues.length];
  }

  // Dark-mode variants of the neutrals above. accent/accent600/success/
  // error/alert/confirm are used as-is in both themes.
  static const Color inkDark = Color(0xFFF3F1EA);
  static const Color inkMutedDark = Color(0xFFB4B7C8);
  static const Color paperDark = Color(0xFF14162A);
  static const Color surfaceDark = Color(0xFF1E2138);
  static const Color borderDark = Color(0xFF343854);
}

/// Theme-aware access to the neutral tokens above (ink/paper/surface/
/// border all have light + dark variants). Any custom widget that shows
/// one of these colors must read it through here, not through the
/// [AppColors] constants directly - those are always the light values and
/// would stay wrong in dark mode.
extension AppColorsContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get colorInk => isDarkMode ? AppColors.inkDark : AppColors.ink;
  Color get colorInkMuted =>
      isDarkMode ? AppColors.inkMutedDark : AppColors.inkMuted;
  Color get colorPaper => isDarkMode ? AppColors.paperDark : AppColors.paper;
  Color get colorSurface =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surface;
  Color get colorBorder => isDarkMode ? AppColors.borderDark : AppColors.border;

  /// Background for the one focal panel on a screen. Always dark, so the
  /// text on it is white in both themes rather than theme-aware.
  Color get colorPanel => isDarkMode ? AppColors.panelDark : AppColors.panel;
}
