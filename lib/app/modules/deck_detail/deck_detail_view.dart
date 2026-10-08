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
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/deck_badge.dart';
import '../../core/widgets/deck_destination_sheet.dart';
import '../../core/widgets/study_mode_sheet.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/study_mode.dart';
import '../../data/vocabulary_languages.dart';
import '../card_detail/card_detail_view.dart';
import '../listen_session/listen_session_view.dart';
import '../study_session/study_session_view.dart';
import 'deck_detail_controller.dart';

/// The overflow-menu actions on a deck: fold it into another deck, or delete
/// it outright.
enum _DeckMenuAction { merge, delete }

class DeckDetailView extends GetView<DeckDetailController> {
  const DeckDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(
          () => controller.isSelecting.value
              ? _selectionAppBar(context)
              : AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: Get.back,
                  ),
                  actions: [
                    PopupMenuButton<_DeckMenuAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _DeckMenuAction.merge:
                            _mergeDeck(context);
                          case _DeckMenuAction.delete:
                            _showDeleteConfirmation(context, controller);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _DeckMenuAction.merge,
                          child: Text(LocaleKeys.deckMergeMenu.tr),
                        ),
                        PopupMenuItem(
                          value: _DeckMenuAction.delete,
                          child: Text(LocaleKeys.deckDeleteConfirm.tr),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isSelecting.value
            ? _SelectionActionBar(
                onMove: () => _pickDestination(context, copy: false),
                onCopy: () => _pickDestination(context, copy: true),
                onDelete: () => _confirmDeleteSelected(context),
              )
            : const SizedBox.shrink(),
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
                for (final card in controller.flashcards)
                  _FlashcardTile(card: card),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// The app bar while picking cards: close the mode, show the count, and
  /// select or clear everything.
  AppBar _selectionAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: controller.exitSelection,
      ),
      title: Text(
        LocaleKeys.cardsSelectedCount.trParams({
          'count': '${controller.selectedCount}',
        }),
      ),
      actions: [
        TextButton(
          onPressed: controller.toggleSelectAll,
          child: Text(
            controller.allSelected
                ? LocaleKeys.cardsDeselectAll.tr
                : LocaleKeys.cardsSelectAll.tr,
          ),
        ),
      ],
    );
  }

  /// Opens the deck picker for a move or a copy. Only decks sharing this
  /// deck's languages are offered, plus the option of a brand-new deck - so
  /// cards can be pulled out into their own deck, not just an existing one.
  Future<void> _pickDestination(
    BuildContext context, {
    required bool copy,
  }) async {
    if (controller.selectedCount == 0) return;

    final count = controller.selectedCount;
    final destination = await showDeckDestinationSheet(
      context,
      decks: controller.compatibleDecks,
      wordCount: count,
      title: (copy ? LocaleKeys.cardsCopyTitle : LocaleKeys.cardsMoveTitle)
          .trParams({'count': '$count'}),
      subtitle: LocaleKeys.cardsDestinationSubtitle.tr,
      newDeckHint: LocaleKeys.cardsNewDeckHint.tr,
    );

    switch (destination) {
      case null:
        return;
      case NewDeckDestination():
        if (!context.mounted) return;
        final name = await _promptNewDeckName(context);
        if (name == null || name.isEmpty) return;
        if (copy) {
          await controller.copySelectedToNewDeck(name);
        } else {
          await controller.moveSelectedToNewDeck(name);
        }
      case ExistingDeckDestination(:final deck):
        if (copy) {
          await controller.copySelectedTo(deck);
        } else {
          await controller.moveSelectedTo(deck);
        }
    }
  }

  /// A small sheet to name a deck being created to receive moved or copied
  /// cards. Returns the trimmed name, or null if cancelled.
  Future<String?> _promptNewDeckName(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();

    return showAppSheet<String>(
      context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
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
                  LocaleKeys.cardsNewDeckTitle.tr,
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
                      Navigator.pop(sheetContext, nameController.text.trim());
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

  /// Merges this whole deck into another: pick a compatible deck, confirm
  /// that this deck will be emptied and removed, then do it.
  Future<void> _mergeDeck(BuildContext context) async {
    final targets = controller.compatibleDecks;
    if (targets.isEmpty) {
      AppSnackbar.info(LocaleKeys.cardsNoTargetDecks.tr);
      return;
    }

    final count = controller.flashcards.length;
    final destination = await showDeckDestinationSheet(
      context,
      decks: targets,
      wordCount: count,
      allowNewDeck: false,
      title: LocaleKeys.deckMergeTitle.tr,
      subtitle: LocaleKeys.deckMergeSubtitle.tr,
    );
    if (destination is! ExistingDeckDestination) return;
    if (!context.mounted) return;

    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.merge_rounded,
      title: LocaleKeys.deckMergeConfirmTitle.trParams({
        'name': destination.deck.name,
      }),
      body: LocaleKeys.deckMergeConfirmBody.trParams({
        'count': '$count',
        'name': destination.deck.name,
      }),
      confirmLabel: LocaleKeys.deckMergeConfirm.tr,
    );
    if (confirmed) await controller.mergeIntoDeck(destination.deck);
  }

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    if (controller.selectedCount == 0) return;

    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.delete_outline_rounded,
      title: LocaleKeys.cardsDeleteTitle.trParams({
        'count': '${controller.selectedCount}',
      }),
      body: LocaleKeys.cardsDeleteBody.tr,
      confirmLabel: LocaleKeys.cardsDeleteConfirm.tr,
    );
    if (confirmed) await controller.deleteSelected();
  }
}

/// The action bar shown while picking cards: move, copy, or delete the
/// selection. The actions are disabled until at least one card is picked, so
/// the bar is visible the moment selection starts without offering a no-op.
class _SelectionActionBar extends GetView<DeckDetailController> {
  const _SelectionActionBar({
    required this.onMove,
    required this.onCopy,
    required this.onDelete,
  });

  final VoidCallback onMove;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorPaper,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Obx(() {
            final enabled = controller.hasSelection;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SelectionAction(
                  icon: Icons.drive_file_move_rounded,
                  label: LocaleKeys.cardsMove.tr,
                  onTap: enabled ? onMove : null,
                ),
                _SelectionAction(
                  icon: Icons.copy_all_rounded,
                  label: LocaleKeys.cardsCopy.tr,
                  onTap: enabled ? onCopy : null,
                ),
                _SelectionAction(
                  icon: Icons.delete_outline_rounded,
                  label: LocaleKeys.cardsDelete.tr,
                  onTap: enabled ? onDelete : null,
                  destructive: true,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? context.colorInkMuted.withValues(alpha: 0.4)
        : destructive
        ? AppColors.alert
        : context.colorInk;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ),
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

class _FlashcardTile extends GetView<DeckDetailController> {
  const _FlashcardTile({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    // The tile has two modes. In selection mode the whole list is a picker,
    // so the row shows a checkbox and a tap toggles it; otherwise a tap opens
    // the card, a long-press starts selecting, and a left-swipe deletes.
    return Obx(() {
      if (controller.isSelecting.value) {
        return _selectableRow(
          context,
          selected: controller.isSelected(card.id),
        );
      }
      return _swipeToDeleteRow(context);
    });
  }

  Widget _selectableRow(BuildContext context, {required bool selected}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.12)
            : context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => controller.toggleSelection(card.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.accent : context.colorInkMuted,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _CardInfo(card: card)),
                if (card.isDue)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swipeToDeleteRow(BuildContext context) {
    // Swipe left to delete: the red panel is revealed as the row slides,
    // and completing the swipe asks for confirmation before anything is
    // removed. The bottom margin lives on both the panel and the row so the
    // gap between cards slides away with the row instead of being orphaned.
    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.alert,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showConfirmSheet(
          context,
          icon: Icons.delete_outline_rounded,
          title: LocaleKeys.cardDeleteTitle.tr,
          body: LocaleKeys.cardDeleteBody.trParams({'word': card.word}),
          confirmLabel: LocaleKeys.cardDeleteConfirm.tr,
        );
        if (!confirmed) return false;
        return controller.deleteCard(card);
      },
      onDismissed: (_) =>
          controller.flashcards.removeWhere((c) => c.id == card.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: context.colorSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            // Silent reload on return: a card may have been edited, and the
            // list is already on screen, so refresh it without the
            // full-screen loading spinner.
            onTap: () async {
              await Get.to(() => CardDetailView(card: card));
              controller.reload(silent: true);
            },
            onLongPress: () => controller.enterSelection(card.id),
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
                  Expanded(child: _CardInfo(card: card)),
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colorInkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The word, its level badge, and its translation - the part of a card row
/// that is the same whether the list is being read or multi-selected.
class _CardInfo extends StatelessWidget {
  const _CardInfo({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: AppTextStyles.caption.copyWith(color: AppColors.accent),
        ),
      ],
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
