import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/permission/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_system_ui.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/permission_sheets.dart';
import 'scan_controller.dart';

/// The scan flow: pick a source (camera/gallery) -> review the photo -> run
/// on-device OCR -> tap-to-select the words worth learning.
///
/// Turning that selection into saved flashcards/decks is a separate,
/// not-yet-built step - see [ScanController.confirmSelection].
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stage = controller.stage.value;
      final isDarkStage =
          stage == ScanStage.source ||
          stage == ScanStage.reviewing ||
          stage == ScanStage.processing;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDarkStage
            ? AppSystemUi.onDarkSurface
            : AppSystemUi.forBrightness(Theme.of(context).brightness),
        child: Scaffold(
          backgroundColor: isDarkStage ? AppColors.ink : context.colorPaper,
          body: SafeArea(
            child: switch (stage) {
              ScanStage.source => const _SourcePicker(),
              ScanStage.reviewing => const _ImageReview(),
              ScanStage.processing => const _ProcessingOverlay(),
              ScanStage.wordSelection => const _WordSelection(),
              ScanStage.empty => const _NoTextFound(),
            },
          ),
        ),
      );
    });
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({this.dark = true});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: dark ? Colors.white : context.colorInk,
          ),
          onPressed: Get.back,
        ),
      ),
    );
  }
}

class _SourcePicker extends GetView<ScanController> {
  const _SourcePicker();

  Future<void> _takePhoto(BuildContext context) async {
    final permissionService = Get.find<PermissionService>();
    final granted = await ensurePermissionGranted(
      context,
      status: permissionService.cameraStatus,
      request: permissionService.requestCamera,
      icon: Icons.camera_alt_rounded,
      primerTitle: LocaleKeys.permissionCameraTitle.tr,
      primerBody: LocaleKeys.permissionCameraBody.tr,
      deniedBody: LocaleKeys.permissionCameraDeniedBody.tr,
    );
    if (!granted) return;
    await controller.captureFromCamera();
  }

  Future<void> _chooseFromGallery(BuildContext context) async {
    final permissionService = Get.find<PermissionService>();
    final granted = await ensurePermissionGranted(
      context,
      status: permissionService.photosStatus,
      request: permissionService.requestPhotos,
      icon: Icons.photo_library_rounded,
      primerTitle: LocaleKeys.permissionGalleryTitle.tr,
      primerBody: LocaleKeys.permissionGalleryBody.tr,
      deniedBody: LocaleKeys.permissionGalleryDeniedBody.tr,
    );
    if (!granted) return;
    await controller.pickFromGallery();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CloseButton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  LocaleKeys.scanSourceTitle.tr,
                  style: AppTextStyles.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LocaleKeys.scanSourceSubtitle.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              AppButton(
                label: LocaleKeys.scanTakePhoto.tr,
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                onPressed: () => _takePhoto(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _chooseFromGallery(context),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    LocaleKeys.scanChooseFromGallery.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageReview extends GetView<ScanController> {
  const _ImageReview();

  @override
  Widget build(BuildContext context) {
    final path = controller.imagePath.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (path != null) Image.file(File(path), fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0, 0.3, 1],
            ),
          ),
        ),
        Column(
          children: [
            const _CloseButton(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.retake,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                      ),
                      child: Text(
                        LocaleKeys.scanRetake.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: LocaleKeys.scanUsePhoto.tr,
                      onPressed: controller.confirmImage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProcessingOverlay extends GetView<ScanController> {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    final path = controller.imagePath.value;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (path != null) Image.file(File(path), fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.6)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.scanReadingText.tr,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WordSelection extends GetView<ScanController> {
  const _WordSelection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CloseButton(dark: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.scanSelectWordsTitle.tr,
                style: AppTextStyles.heading1,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LocaleKeys.scanSelectWordsSubtitle.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.scanSelectedCount.trParams({
                        'count': '${controller.selectedWords.length}',
                      }),
                      style: AppTextStyles.caption.copyWith(
                        color: context.colorInkMuted,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.toggleSelectAll,
                      child: Text(
                        controller.allSelected
                            ? LocaleKeys.scanDeselectAll.tr
                            : LocaleKeys.scanSelectAll.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Obx(
              () => Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final word in controller.candidateWords)
                    _WordChip(
                      word: word,
                      isSelected: controller.selectedWords.contains(word),
                      onTap: () => controller.toggleWord(word),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Obx(
            () => AppButton(
              label: LocaleKeys.scanContinueButton.tr,
              onPressed: controller.selectedWords.isEmpty
                  ? null
                  : controller.confirmSelection,
            ),
          ),
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  final String word;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.accent : context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            word,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : context.colorInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoTextFound extends GetView<ScanController> {
  const _NoTextFound();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CloseButton(dark: false),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: context.colorSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.text_fields_rounded,
                    color: context.colorInkMuted,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  LocaleKeys.scanNoTextFoundTitle.tr,
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LocaleKeys.scanNoTextFoundBody.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: LocaleKeys.scanTryAgain.tr,
            onPressed: controller.retake,
          ),
        ),
      ],
    );
  }
}
