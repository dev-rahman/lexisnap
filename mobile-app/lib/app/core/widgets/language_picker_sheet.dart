import 'app_bottom_sheet.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/app_locales.dart';
import '../localization/locale_keys.dart';
import '../services/locale/locale_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// The language-picking bottom sheet, shared by every place in the app
/// that lets someone change language (Profile > Language, and the compact
/// [LanguageSelector] on the pre-auth screens) - one sheet, one behavior.
void showLanguagePickerSheet(BuildContext context) {
  final localeService = Get.find<LocaleService>();

  showAppSheet(
    context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          // Top padding is 0: the drag handle above already
          // reserves a 48dp block, and adding lg on top of it
          // pushed every sheet title a third of the way down.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.profileLanguage.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Column(
                  children: [
                    for (final option in AppLocales.supported)
                      _LanguageOption(
                        flag: option.flag,
                        label: option.nativeName,
                        isSelected:
                            localeService.locale.value.languageCode ==
                            option.locale.languageCode,
                        onTap: () {
                          localeService.setLocale(option.locale);
                          Get.back();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.accent : context.colorInk,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, color: AppColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
