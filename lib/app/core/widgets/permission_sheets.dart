import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../localization/locale_keys.dart';
import '../services/permission/permission_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Explains why a permission is needed *before* the OS prompt ever shows,
/// so the one shot most platforms give an app at asking isn't spent on a
/// bare system dialog with no context. Returns true if the person tapped
/// "Allow" (the caller still has to actually request the permission).
Future<bool> showPermissionPrimerSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.colorPaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PermissionIcon(icon: icon),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: sheetContext.colorInk,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTextStyles.body.copyWith(
                  color: sheetContext.colorInkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: LocaleKeys.permissionAllow.tr,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                variant: AppButtonVariant.text,
                label: LocaleKeys.permissionNotNow.tr,
                onPressed: () => Navigator.pop(sheetContext, false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}

/// Shown when a permission is permanently denied - the OS won't prompt
/// again, so the only way forward is the app's Settings page.
Future<void> showPermissionDeniedSheet(
  BuildContext context, {
  required IconData icon,
  required String body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colorPaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PermissionIcon(icon: icon),
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.permissionDeniedTitle.tr,
                style: AppTextStyles.heading2.copyWith(
                  color: sheetContext.colorInk,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: AppTextStyles.body.copyWith(
                  color: sheetContext.colorInkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: LocaleKeys.permissionOpenSettings.tr,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Get.find<PermissionService>().openSettings();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                variant: AppButtonVariant.text,
                label: LocaleKeys.permissionNotNow.tr,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Runs the full check -> (primer ->) request -> (denied sheet) flow for a
/// single permission and reports whether it ended up granted. [status] and
/// [request] are the non-prompting check and the actual (possibly
/// OS-prompting) request, respectively - kept as separate callbacks so this
/// stays reusable for both camera and photos.
Future<bool> ensurePermissionGranted(
  BuildContext context, {
  required Future<AppPermissionStatus> Function() status,
  required Future<AppPermissionStatus> Function() request,
  required IconData icon,
  required String primerTitle,
  required String primerBody,
  required String deniedBody,
}) async {
  final current = await status();
  if (current == AppPermissionStatus.granted) return true;

  if (current == AppPermissionStatus.permanentlyDenied) {
    if (context.mounted) {
      await showPermissionDeniedSheet(context, icon: icon, body: deniedBody);
    }
    return false;
  }

  if (!context.mounted) return false;
  final proceed = await showPermissionPrimerSheet(
    context,
    icon: icon,
    title: primerTitle,
    body: primerBody,
  );
  if (!proceed) return false;

  final result = await request();
  if (result == AppPermissionStatus.granted) return true;

  if (result == AppPermissionStatus.permanentlyDenied && context.mounted) {
    await showPermissionDeniedSheet(context, icon: icon, body: deniedBody);
  }
  return false;
}

class _PermissionIcon extends StatelessWidget {
  const _PermissionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.accent),
    );
  }
}
