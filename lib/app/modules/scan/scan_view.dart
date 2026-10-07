import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_system_ui.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/deck_destination_sheet.dart';
import '../../core/widgets/language_select_sheet.dart';
import '../../data/models/vocabulary_word.dart';
import 'scan_controller.dart';

/// The scan flow: pick a source (camera/gallery) -> review the photo -> run
/// on-device OCR + AI extraction -> tap-to-select the words worth learning
/// -> choose where they go (a new deck, or one you already have) -> translate
/// and save that batch. The remaining words stay selectable, so one scan can
/// be split across several decks. See [ScanController.fileToNewDeck] and
/// [ScanController.fileToExistingDeck].
class ScanView extends GetView<ScanController> {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stage = controller.stage.value;
      final isDarkStage =
          stage == ScanStage.pickingImage ||
          stage == ScanStage.reviewing ||
          stage == ScanStage.processing ||
          stage == ScanStage.savingDeck;

      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDarkStage
            ? AppSystemUi.onDarkSurface
            : AppSystemUi.forBrightness(Theme.of(context).brightness),
        child: Scaffold(
          backgroundColor: isDarkStage ? AppColors.ink : context.colorPaper,
          body: SafeArea(
            child: switch (stage) {
              // No label: the system picker covers this within a frame,
              // so anything written here would only flash.
              ScanStage.pickingImage => const _ProcessingOverlay(),
              ScanStage.reviewing => const _ImageReview(),
              ScanStage.processing => _ProcessingOverlay(
                label: LocaleKeys.scanReadingText.tr,
              ),
              ScanStage.wordSelection => const _WordSelection(),
              ScanStage.savingDeck => _ProcessingOverlay(
                label: controller.savingLabel.value ?? LocaleKeys.scanSavingDeck.tr,
              ),
              ScanStage.empty => const _NoTextFound(),
            },
          ),
        ),
      );
    });
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({this.dark = true, this.onPressed});

  final bool dark;

  /// Defaults to a plain pop; the word-selection screen overrides it so
  /// closing after filing some words still finishes with a summary.
  final VoidCallback? onPressed;

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
          onPressed: onPressed ?? Get.back,
        ),
      ),
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
  const _ProcessingOverlay({this.label});

  /// Omitted while the system picker is opening, when there is nothing
  /// worth saying for the frame or two before it covers the screen.
  final String? label;

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
              if (label != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  label!,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ],
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
        _CloseButton(dark: false, onPressed: controller.requestClose),
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
                controller.hasFiled
                    ? LocaleKeys.scanSelectMoreSubtitle.tr
                    : LocaleKeys.scanSelectWordsSubtitle.tr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (controller.hasFiled) ...[
                const SizedBox(height: AppSpacing.sm),
                _FiledProgress(count: controller.filedWordCount.value),
              ],
              if (controller.sourceLanguageName.value != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LocaleKeys.scanDetectedLanguage.trParams({
                    'language': controller.sourceLanguageName.value!,
                  }),
                  style: AppTextStyles.caption.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
              ],
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
              () => Column(
                children: [
                  for (final word in controller.candidateWords) ...[
                    _WordCard(
                      word: word,
                      isSelected: controller.selectedWords.contains(word),
                      onTap: () => controller.toggleWord(word),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
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
              label: LocaleKeys.scanAddToDeckButton.tr,
              onPressed: controller.selectedWords.isEmpty
                  ? null
                  : () => _chooseDestination(context, controller),
            ),
          ),
        ),
      ],
    );
  }
}

/// A quiet line under the header once the first batch is filed, so the user
/// can see the split is adding up rather than replacing earlier choices.
class _FiledProgress extends StatelessWidget {
  const _FiledProgress({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: AppColors.accent,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          LocaleKeys.scanFiledProgress.trParams({'count': '$count'}),
          style: AppTextStyles.caption.copyWith(color: AppColors.accent),
        ),
      ],
    );
  }
}

/// Asks where the selected words should go, then hands off to the matching
/// controller method. A new deck needs a target language first; an existing
/// one already has one.
Future<void> _chooseDestination(
  BuildContext context,
  ScanController controller,
) async {
  final destination = await showDeckDestinationSheet(
    context,
    decks: controller.existingDecks,
    wordCount: controller.selectedWords.length,
  );
  if (destination == null) return;

  switch (destination) {
    case NewDeckDestination():
      if (!context.mounted) return;
      final targetLanguage = await showLanguageSelectSheet(
        context,
        title: LocaleKeys.scanTargetLanguageTitle.tr,
        subtitle: LocaleKeys.scanTargetLanguageBody.tr,
      );
      if (targetLanguage != null) {
        await controller.fileToNewDeck(targetLanguage);
      }
    case ExistingDeckDestination(:final deck):
      await controller.fileToExistingDeck(deck);
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.word,
    required this.isSelected,
    required this.onTap,
  });

  final VocabularyWord word;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : context.colorInk;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? Colors.white : context.colorInkMuted,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          word.word,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textColor,
                          ),
                        ),
                        if (word.level != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _LevelBadge(level: word.level!, dark: isSelected),
                        ],
                      ],
                    ),
                    if (word.exampleSentence != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        word.exampleSentence!,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.85)
                              : context.colorInkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.dark});

  final String level;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.22)
            : AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        level,
        style: AppTextStyles.caption.copyWith(
          color: dark ? Colors.white : AppColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
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
