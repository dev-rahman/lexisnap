import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/deck_badge.dart';
import '../../core/widgets/study_mode_sheet.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_mode.dart';
import '../../data/vocabulary_languages.dart';
import '../card_detail/card_detail_view.dart';
import '../listen_session/listen_session_view.dart';
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
                // The deck's hue, same badge as the row you tapped to get
                // here - otherwise the colour in the list would be
                // decoration rather than the deck's identity.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeckBadge(deckId: deck.id),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () => _showRenameSheet(
                              context,
                              controller,
                              deck.name,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    deck.name,
                                    style: AppTextStyles.heading1,
                                  ),
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
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            LocaleKeys.deckSummary.trParams({
                              'source':
                                  VocabularyLanguages.byCode(
                                    deck.sourceLanguage,
                                  )?.flag ??
                                  deck.sourceLanguage ??
                                  '?',
                              'target':
                                  VocabularyLanguages.byCode(
                                    deck.targetLanguage,
                                  )?.flag ??
                                  deck.targetLanguage,
                              'count': '${deck.cardCount}',
                            }),
                            style: AppTextStyles.caption.copyWith(
                              color: context.colorInkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StudyHeroCard(
                  dueCount: controller.dueCount,
                  isEmpty: controller.flashcards.isEmpty,
                  onStudy: () async {
                    await Get.to(
                      () => StudySessionView(
                        flashcards: List.of(controller.flashcards),
                      ),
                    );
                    controller.reload();
                  },
                  onListen: () => Get.to(
                    () => ListenSessionView(
                      flashcards: List.of(controller.flashcards),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final card in controller.flashcards) ...[
                  _FlashcardTile(card: card),
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

/// The deck's entry point into studying: what's waiting, how the streak
/// is doing, the two ways in, and the study mode they'll use - changeable
/// right here, so trying a deck as flip cards doesn't mean a trip to
/// Profile first.
///
/// It leads with the due count and the streak rather than the deck's card
/// list because those are the two numbers that decide whether the user
/// starts a session at all.
class _StudyHeroCard extends StatelessWidget {
  const _StudyHeroCard({
    required this.dueCount,
    required this.isEmpty,
    required this.onStudy,
    required this.onListen,
  });

  final int dueCount;
  final bool isEmpty;
  final VoidCallback onStudy;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final hasDue = dueCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasDue)
                      Text(
                        '$dueCount',
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.accent,
                          fontSize: 34,
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.confirm,
                        size: 30,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        hasDue
                            ? LocaleKeys.deckDueNow.trParams({
                                'count': '$dueCount',
                              })
                            : LocaleKeys.deckAllCaughtUp.tr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.colorInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Obx(
                () => StudyModeChip(
                  mode: Get.find<StudyPreferencesService>().mode.value,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(() {
            final mode = Get.find<StudyPreferencesService>().mode.value;
            final isListening = mode == StudyMode.listen;

            return AppButton(
              label: isListening
                  ? LocaleKeys.deckListen.tr
                  : hasDue
                  ? LocaleKeys.deckStudyDue.trParams({'count': '$dueCount'})
                  : LocaleKeys.deckStudy.tr,
              icon: Icon(
                isListening ? Icons.headphones_rounded : Icons.style_rounded,
                size: 18,
              ),
              onPressed: isEmpty ? null : (isListening ? onListen : onStudy),
            );
          }),
        ],
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Get.to(() => CardDetailView(card: card)),
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
                  languageCode: card.sourceLanguage,
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
              if (card.isDue)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
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

  showAppSheet(
    context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          // The drag handle already reserves the top gap.
          0,
          AppSpacing.lg,
          // See the note in profile_view: the keyboard inset and the
          // system nav inset swap over, so the sheet needs both.
          MediaQuery.of(sheetContext).viewInsets.bottom +
              MediaQuery.of(sheetContext).padding.bottom +
              AppSpacing.lg,
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
