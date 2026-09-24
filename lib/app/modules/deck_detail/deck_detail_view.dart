import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/flashcard.dart';
import '../../data/vocabulary_languages.dart';
import '../card_detail/card_detail_view.dart';
import '../study_session/study_session_view.dart';
import 'deck_detail_controller.dart';

class DeckDetailView extends GetView<DeckDetailController> {
  const DeckDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _showDeleteConfirmation(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final deck = controller.deck.value;
          if (deck == null) {
            return Center(child: Text(LocaleKeys.deckLoadError.tr));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _showRenameSheet(context, controller, deck.name),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(deck.name, style: AppTextStyles.heading1),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: context.colorInkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  LocaleKeys.deckSummary.trParams({
                    'source':
                        VocabularyLanguages.byCode(deck.sourceLanguage)?.flag ??
                        deck.sourceLanguage ??
                        '?',
                    'target':
                        VocabularyLanguages.byCode(deck.targetLanguage)?.flag ??
                        deck.targetLanguage,
                    'count': '${deck.cardCount}',
                  }),
                  style: AppTextStyles.caption.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: controller.dueCount > 0
                      ? LocaleKeys.deckStudyDue.trParams({
                          'count': '${controller.dueCount}',
                        })
                      : LocaleKeys.deckStudy.tr,
                  icon: const Icon(Icons.style_rounded, size: 18),
                  onPressed: controller.flashcards.isEmpty
                      ? null
                      : () async {
                          await Get.to(
                            () => StudySessionView(
                              flashcards: List.of(controller.flashcards),
                              sourceLanguage: deck.sourceLanguage,
                              targetLanguage: deck.targetLanguage,
                            ),
                          );
                          controller.reload();
                        },
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final card in controller.flashcards) ...[
                  _FlashcardTile(
                    card: card,
                    sourceLanguage: deck.sourceLanguage,
                    targetLanguage: deck.targetLanguage,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({
    required this.card,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final Flashcard card;
  final String? sourceLanguage;
  final String targetLanguage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Get.to(
          () => CardDetailView(
            card: card,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up_outlined, size: 20),
                onPressed: () => Get.find<TextToSpeechService>().speak(
                  card.word,
                  languageCode: sourceLanguage,
                ),
                color: AppColors.accent,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            card.word,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.colorInk,
                            ),
                          ),
                        ),
                        if (card.level != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _LevelBadge(level: card.level!),
                        ],
                      ],
                    ),
                    Text(
                      card.translation,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.colorInkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        level,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

void _showRenameSheet(
  BuildContext context,
  DeckDetailController controller,
  String currentName,
) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: currentName);

  showModalBottomSheet(
    context: context,
    backgroundColor: context.colorPaper,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.deckRenameTitle.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: LocaleKeys.deckRenameTitle.tr,
                controller: nameController,
                textInputAction: TextInputAction.done,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? LocaleKeys.validatorFieldRequired.tr
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: LocaleKeys.commonSave.tr,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(sheetContext);
                    controller.renameDeck(nameController.text.trim());
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                variant: AppButtonVariant.text,
                label: LocaleKeys.commonCancel.tr,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showDeleteConfirmation(
  BuildContext context,
  DeckDetailController controller,
) {
  showModalBottomSheet(
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
              Text(
                LocaleKeys.deckDeleteTitle.tr,
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                LocaleKeys.deckDeleteBody.tr,
                style: AppTextStyles.body.copyWith(
                  color: sheetContext.colorInkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: LocaleKeys.deckDeleteConfirm.tr,
                variant: AppButtonVariant.outlined,
                color: AppColors.alert,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  controller.deleteDeck();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                variant: AppButtonVariant.text,
                label: LocaleKeys.commonCancel.tr,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}
