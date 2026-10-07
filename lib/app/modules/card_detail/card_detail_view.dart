import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/study_day.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/flashcard.dart';
import 'card_edit_view.dart';

/// Full detail for a single flashcard - word, translation, description,
/// every example sentence, and its spaced-repetition status. Pushed from
/// deck detail's compact card row, or from within a study session via the
/// "show details" button.
///
/// The card can be edited or deleted from here (see [CardEditView]); the
/// screen holds the card in state so an edit shows immediately, and a
/// delete pops back to the deck.
class CardDetailView extends StatefulWidget {
  const CardDetailView({super.key, required this.card});

  final Flashcard card;

  @override
  State<CardDetailView> createState() => _CardDetailViewState();
}

class _CardDetailViewState extends State<CardDetailView> {
  late Flashcard _card = widget.card;

  Future<void> _edit() async {
    final updated = await Get.to<Flashcard>(
      () => CardEditView(card: _card),
    );
    if (updated != null) {
      setState(() => _card = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.delete_outline_rounded,
      title: LocaleKeys.cardDeleteTitle.tr,
      body: LocaleKeys.cardDeleteBody.trParams({'word': _card.word}),
      confirmLabel: LocaleKeys.cardDeleteConfirm.tr,
    );
    if (!confirmed) return;

    try {
      await Get.find<DeckRepository>().deleteFlashcard(_card.id);
      Get.back();
      AppSnackbar.success(LocaleKeys.cardDeletedSuccess.tr);
    } catch (_) {
      AppSnackbar.error(LocaleKeys.cardDeleteError.tr);
    }
  }

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
            icon: const Icon(Icons.edit_outlined),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(_card.word, style: AppTextStyles.heading1),
                  ),
                  if (_card.level != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _LevelBadge(level: _card.level!),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () => Get.find<TextToSpeechService>().speak(
                      _card.word,
                      languageCode: _card.sourceLanguage,
                    ),
                    color: AppColors.accent,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _card.translation,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () => Get.find<TextToSpeechService>().speak(
                      _card.translation,
                      languageCode: _card.targetLanguage,
                    ),
                    color: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _srsStatus(context),
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
              if (_card.wordDescription != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(_card.wordDescription!, style: AppTextStyles.body),
              ],
              if (_card.exampleSentences.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                for (final sentence in _card.exampleSentences) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colorSurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      sentence,
                      style: AppTextStyles.body.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _srsStatus(BuildContext context) {
    if (_card.repetitions == 0) return LocaleKeys.cardDetailNotReviewedYet.tr;

    final reviewedLabel = _card.repetitions == 1
        ? LocaleKeys.cardDetailReviewedOnce.tr
        : LocaleKeys.cardDetailReviewedTimes.trParams({
            'count': '${_card.repetitions}',
          });

    // Counted in whole study days rather than raw 24-hour spans: due dates
    // sit on the 4am boundary, so a truncating subtraction reports a card
    // due in six days as five.
    final daysUntilDue = studyDaysBetween(DateTime.now(), _card.dueAt);
    final dueLabel = daysUntilDue <= 0
        ? LocaleKeys.cardDetailNextReviewToday.tr
        : LocaleKeys.cardDetailNextReviewInDays.trParams({
            'count': '$daysUntilDue',
          });

    return '$reviewedLabel · $dueLabel';
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
        ),
      ),
    );
  }
}
