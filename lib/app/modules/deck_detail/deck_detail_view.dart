import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
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
                _StudyHeroCard(
                  dueCount: controller.dueCount,
                  isEmpty: controller.flashcards.isEmpty,
                  onStudy: () async {
                    await Get.to(
                      () => StudySessionView(
                        flashcards: List.of(controller.flashcards),
                        sourceLanguage: deck.sourceLanguage,
                        targetLanguage: deck.targetLanguage,
                      ),
                    );
                    controller.reload();
                  },
                  onListen: () => Get.to(
                    () => ListenSessionView(
                      flashcards: List.of(controller.flashcards),
                      sourceLanguage: deck.sourceLanguage,
                      targetLanguage: deck.targetLanguage,
                    ),
                  ),
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

/// The deck's entry point into studying: what's waiting, how the streak
/// is doing, and the two ways in.
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
                        color: AppColors.success,
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
              const _StreakBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _DailyGoalBar(),
          const SizedBox(height: AppSpacing.md),
          const _StudyModePicker(),
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

/// Lets the learner choose how they're asked, instead of the app always
/// deciding for them. "Smart" keeps the adaptive behaviour as the default
/// so nobody has to care, and the rest are one tap away and remembered.
class _StudyModePicker extends StatelessWidget {
  const _StudyModePicker();

  static const _icons = {
    StudyMode.smart: Icons.auto_awesome_rounded,
    StudyMode.quiz: Icons.checklist_rounded,
    StudyMode.flip: Icons.swipe_rounded,
    StudyMode.listen: Icons.headphones_rounded,
  };

  static const _labels = {
    StudyMode.smart: LocaleKeys.studyModeSmart,
    StudyMode.quiz: LocaleKeys.studyModeQuiz,
    StudyMode.flip: LocaleKeys.studyModeFlip,
    StudyMode.listen: LocaleKeys.deckListen,
  };

  static const _hints = {
    StudyMode.smart: LocaleKeys.studyModeSmartHint,
    StudyMode.quiz: LocaleKeys.studyModeQuizHint,
    StudyMode.flip: LocaleKeys.studyModeFlipHint,
    StudyMode.listen: LocaleKeys.studyModeListenHint,
  };

  @override
  Widget build(BuildContext context) {
    final service = Get.find<StudyPreferencesService>();

    return Obx(() {
      final selected = service.mode.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final mode in StudyMode.values) ...[
                if (mode != StudyMode.values.first)
                  const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ModeChip(
                    icon: _icons[mode]!,
                    label: _labels[mode]!.tr,
                    isSelected: mode == selected,
                    onTap: () => service.setMode(mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _hints[selected]!.tr,
            style: AppTextStyles.caption.copyWith(color: context.colorInkMuted),
          ),
        ],
      );
    });
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.white : context.colorInkMuted;

    return Material(
      color: isSelected ? AppColors.accent : context.colorPaper,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: foreground,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streak = Get.find<StreakService>().streak.value;
      if (streak.current == 0) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.accent,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${streak.current}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              LocaleKeys.deckStreakLabel.tr,
              style: AppTextStyles.caption.copyWith(color: AppColors.accent),
            ),
          ],
        ),
      );
    });
  }
}

class _DailyGoalBar extends StatelessWidget {
  const _DailyGoalBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streak = Get.find<StreakService>().streak.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: streak.goalProgress,
              minHeight: 6,
              backgroundColor: context.colorBorder,
              valueColor: AlwaysStoppedAnimation(
                streak.goalMet ? AppColors.success : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            streak.goalMet
                ? LocaleKeys.studyGoalMet.tr
                : LocaleKeys.deckGoalProgress.trParams({
                    'done': '${streak.reviewsToday}',
                    'goal': '${streak.dailyGoal}',
                  }),
            style: AppTextStyles.caption.copyWith(
              color: streak.goalMet
                  ? AppColors.success
                  : context.colorInkMuted,
            ),
          ),
        ],
      );
    });
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
