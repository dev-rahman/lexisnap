import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/scan_source.dart';
import '../../routes/app_routes.dart';
import '../localization/locale_keys.dart';
import '../services/permission/permission_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'permission_sheets.dart';

/// Asks where the photo should come from, then starts the scan flow.
///
/// This replaced a full-screen dark takeover that was the scan route's
/// first stage. Two buttons do not need a whole screen, and paying for them
/// with a route push meant the bottom bar disappeared and the app looked
/// like it had been exited - before the user had committed to anything.
///
/// A sheet keeps the screen behind it, bar included, so choosing a source
/// reads as a menu rather than a departure, and backing out costs one tap
/// on the scrim instead of finding a close button.
///
/// Permission is settled here too, while the user is still on a screen they
/// recognise. Asking after the push meant a primer sheet appearing over a
/// black screen that had no content of its own to explain itself with.
Future<void> startScanFlow(BuildContext context) async {
  final source = await showModalBottomSheet<ScanSource>(
    context: context,
    backgroundColor: context.colorPaper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LocaleKeys.scanSourceTitle.tr, style: AppTextStyles.heading2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              LocaleKeys.scanSourceSubtitle.tr,
              style: AppTextStyles.body.copyWith(color: context.colorInkMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SourceOption(
              icon: Icons.camera_alt_rounded,
              label: LocaleKeys.scanTakePhoto.tr,
              isPrimary: true,
              onTap: () => Navigator.pop(sheetContext, ScanSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SourceOption(
              icon: Icons.photo_library_rounded,
              label: LocaleKeys.scanChooseFromGallery.tr,
              onTap: () => Navigator.pop(sheetContext, ScanSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return;
  if (!context.mounted) return;
  if (!await _ensurePermission(context, source)) return;

  await Get.toNamed(AppRoutes.scan, arguments: source);
}

Future<bool> _ensurePermission(BuildContext context, ScanSource source) {
  final service = Get.find<PermissionService>();

  return switch (source) {
    ScanSource.camera => ensurePermissionGranted(
      context,
      status: service.cameraStatus,
      request: service.requestCamera,
      icon: Icons.camera_alt_rounded,
      primerTitle: LocaleKeys.permissionCameraTitle.tr,
      primerBody: LocaleKeys.permissionCameraBody.tr,
      deniedBody: LocaleKeys.permissionCameraDeniedBody.tr,
    ),
    ScanSource.gallery => ensurePermissionGranted(
      context,
      status: service.photosStatus,
      request: service.requestPhotos,
      icon: Icons.photo_library_rounded,
      primerTitle: LocaleKeys.permissionGalleryTitle.tr,
      primerBody: LocaleKeys.permissionGalleryBody.tr,
      deniedBody: LocaleKeys.permissionGalleryDeniedBody.tr,
    ),
  };
}

/// One source row. The camera is filled because it's what the scan feature
/// is actually for; the gallery is the fallback for a photo you already
/// took, so it stays quiet.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? Colors.white : context.colorInk;

    return Material(
      color: isPrimary ? AppColors.accent : context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.button.copyWith(color: foreground),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.8)
                    : context.colorInkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
