import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/app_locales.dart';
import '../services/locale/locale_service.dart';
import '../theme/app_colors.dart';
import 'language_picker_sheet.dart';

/// Small "🌐 English ⌄" control for pre-auth screens (onboarding, login)
/// so someone can pick their language before they even have an account -
/// opens the same picker as Profile > Language.
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();

    return Obx(() {
      final current = AppLocales.supported.firstWhere(
        (option) =>
            option.locale.languageCode ==
            localeService.locale.value.languageCode,
        orElse: () => AppLocales.supported.first,
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => showLanguagePickerSheet(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(current.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  current.nativeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colorInkMuted,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: context.colorInkMuted,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
