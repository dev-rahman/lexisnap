import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_sheet.dart';
import 'app_button.dart';

/// Asks the user to confirm an action that's hard to take back - signing
/// out, deleting the account - and resolves to whether they did.
///
/// Only asks; the caller performs the action afterwards, so its progress
/// shows on the screen the user is looking at once the sheet is gone,
/// rather than on a sheet that's already sliding away.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  // Alert red on the dark sheet is too dim to carry the icon, so dark
  // mode flips to a white icon on a stronger tint.
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final confirmed = await showAppSheet<bool>(
    context,
    // A plain sheet is capped at 9/16 of the screen, which this one - two
    // full-size buttons and a paragraph, longer still in German - outgrows
    // on a small phone. Scroll-controlled, it's as tall as it needs to be.
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        // The drag handle above already reserves the top gap.
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
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: isDark ? 0.28 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? Colors.white : AppColors.alert),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              style: AppTextStyles.body.copyWith(color: context.colorInkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: confirmLabel,
              color: AppColors.alert,
              onPressed: () => Navigator.pop(sheetContext, true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: LocaleKeys.commonCancel.tr,
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}
