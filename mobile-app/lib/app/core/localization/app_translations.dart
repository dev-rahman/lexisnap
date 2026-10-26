import 'package:get/get.dart';

import 'translations/de.dart';
import 'translations/en.dart';
import 'translations/es.dart';
import 'translations/fr.dart';
import 'translations/ko.dart';

/// GetX translation source. Registered on `GetMaterialApp(translations:
/// AppTranslations())`. Every user-facing string in the app should be a
/// `LocaleKeys` constant used as `LocaleKeys.xxx.tr` (or `.trParams` for
/// strings with a `@placeholder`), never a hardcoded literal, so it's
/// covered by every language below.
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en': en,
    'de': de,
    'fr': fr,
    'es': es,
    'ko': ko,
  };
}
