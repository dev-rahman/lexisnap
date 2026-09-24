import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/flashcard.dart';

/// Full detail for a single flashcard - word, translation, description,
/// every example sentence, and its spaced-repetition status. Pushed from
/// deck detail's compact card row, or from within a study session via the
/// "show details" button.
class CardDetailView extends StatelessWidget {
  const CardDetailView({
    super.key,
    required this.card,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final Flashcard card;
  final String? sourceLanguage;
  final String targetLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
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
                    child: Text(card.word, style: AppTextStyles.heading1),
                  ),
                  if (card.level != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _LevelBadge(level: card.level!),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () => Get.find<TextToSpeechService>().speak(
                      card.word,
                      languageCode: sourceLanguage,
                    ),
                    color: AppColors.accent,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.translation,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () => Get.find<TextToSpeechService>().speak(
                      card.translation,
                      languageCode: targetLanguage,
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
              if (card.wordDescription != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(card.wordDescription!, style: AppTextStyles.body),
              ],
              if (card.exampleSentences.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                for (final sentence in card.exampleSentences) ...[
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
    if (card.repetitions == 0) return LocaleKeys.cardDetailNotReviewedYet.tr;

    final reviewedLabel = card.repetitions == 1
        ? LocaleKeys.cardDetailReviewedOnce.tr
        : LocaleKeys.cardDetailReviewedTimes.trParams({
            'count': '${card.repetitions}',
          });

    final daysUntilDue = card.dueAt.difference(DateTime.now()).inDays;
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
