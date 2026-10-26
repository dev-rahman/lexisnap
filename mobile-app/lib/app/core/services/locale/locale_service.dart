import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../localization/app_locales.dart';

/// Persists and applies the user's language preference. `init()` must be
/// awaited once at startup (see `service_locator.dart`) before
/// `GetMaterialApp` reads `locale.value` for its initial locale.
class LocaleService {
  static const _key = 'app_locale';

  final locale = AppLocales.fallback.obs;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    // English on first install, regardless of device language - language
    // is a deliberate, visible choice the user makes (via the picker on
    // onboarding/login or in Profile), not something we guess at silently.
    if (saved == null) return;

    locale.value = AppLocales.supported
        .firstWhere(
          (option) => option.locale.languageCode == saved,
          orElse: () => const AppLocaleOption(AppLocales.fallback, '', ''),
        )
        .locale;
  }

  Future<void> setLocale(Locale newLocale) async {
    locale.value = newLocale;
    Get.updateLocale(newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newLocale.languageCode);
  }
}
