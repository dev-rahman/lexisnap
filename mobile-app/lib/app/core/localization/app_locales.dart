import 'package:flutter/widgets.dart';

class AppLocaleOption {
  const AppLocaleOption(this.locale, this.nativeName, this.flag);

  final Locale locale;

  /// Shown in the language picker in the language's own script, not
  /// translated into whatever language is currently active - the whole
  /// point is that someone can find their language even if they can't
  /// read the current one.
  final String nativeName;

  /// Flag emoji for the language's most associated country, shown next to
  /// [nativeName] so the option is recognizable at a glance.
  final String flag;
}

class AppLocales {
  AppLocales._();

  static const supported = [
    AppLocaleOption(Locale('en'), 'English', '🇺🇸'),
    AppLocaleOption(Locale('de'), 'Deutsch', '🇩🇪'),
    AppLocaleOption(Locale('fr'), 'Français', '🇫🇷'),
    AppLocaleOption(Locale('es'), 'Español', '🇪🇸'),
    AppLocaleOption(Locale('ko'), '한국어', '🇰🇷'),
  ];

  static const fallback = Locale('en');
}
