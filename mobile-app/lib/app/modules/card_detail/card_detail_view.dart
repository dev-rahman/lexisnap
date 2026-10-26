import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/study_day.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/vocabulary_language.dart';
import '../../data/vocabulary_languages.dart';
import 'card_edit_view.dart';

/// Full detail for a single flashcard - the word and its translation shown
/// together as a flashcard, each pronounceable, with the card's definition,
/// listenable example sentences, and its spaced-repetition status. Pushed
/// from deck detail's compact card row, or from within a study session via
/// the "show details" button.
///
/// The card can be edited from here (see [CardEditView]); the screen holds
/// the card in state so an edit shows immediately. Deleting is done by
/// swiping the card's row in the deck list, not from this screen.
class CardDetailView extends StatefulWidget {
  const CardDetailView({super.key, required this.card});

  final Flashcard card;

  @override
  State<CardDetailView> createState() => _CardDetailViewState();
}

class _CardDetailViewState extends State<CardDetailView> {
  late Flashcard _card = widget.card;

  Future<void> _edit() async {
    final updated = await Get.to<Flashcard>(() => CardEditView(card: _card));
    if (updated != null) {
      setState(() => _card = updated);
    }
  }

  void _speak(String text, {String? languageCode}) =>
      Get.find<TextToSpeechService>().speak(text, languageCode: languageCode);

  @override
  Widget build(BuildContext context) {
    // A stable colour per language pair, so the same deck's cards always
    // wear the same hue - recognition rather than a random tint each visit.
    final hue = AppColors.hueFor(_card.sourceLanguage ?? _card.targetLanguage);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: LocaleKeys.cardDetailEdit.tr,
            onPressed: _edit,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
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
              _FlashcardHero(
                card: _card,
                hue: hue,
                onSpeakWord: () =>
                    _speak(_card.word, languageCode: _card.sourceLanguage),
                onSpeakTranslation: () => _speak(
                  _card.translation,
                  languageCode: _card.targetLanguage,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusPill(label: _srsStatus(context)),
              if (_card.wordDescription != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(LocaleKeys.cardDetailMeaning.tr),
                const SizedBox(height: AppSpacing.sm),
                Text(_card.wordDescription!, style: AppTextStyles.body),
              ],
              if (_card.exampleSentences.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(LocaleKeys.cardEditExamples.tr),
                const SizedBox(height: AppSpacing.sm),
                for (final sentence in _card.exampleSentences)
                  _ExampleCard(
                    sentence: sentence,
                    hue: hue,
                    onSpeak: () =>
                        _speak(sentence, languageCode: _card.sourceLanguage),
                  ),
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

/// The focal flashcard: the word and its translation stacked on one tinted
/// panel - the word on top (the "front"), the translation below the divider
/// (the "back") - each with a tap-to-hear button so pronunciation is the
/// obvious thing to do here.
class _FlashcardHero extends StatelessWidget {
  const _FlashcardHero({
    required this.card,
    required this.hue,
    required this.onSpeakWord,
    required this.onSpeakTranslation,
  });

  final Flashcard card;
  final AppHue hue;
  final VoidCallback onSpeakWord;
  final VoidCallback onSpeakTranslation;

  @override
  Widget build(BuildContext context) {
    final color = hue.resolve(context);
    final pair = _pairLabel();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hue.tint(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (pair != null)
                Expanded(
                  child: Text(
                    pair,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colorInkMuted,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (card.level != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _LevelBadge(level: card.level!),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Front: the word, with the one bright "hear it" action.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(card.word, style: AppTextStyles.heading1),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SpeakButton(
                onPressed: onSpeakWord,
                prominent: true,
                color: color,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: color.withValues(alpha: 0.25)),
          ),
          // Back: the translation, with a quieter listen button.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  card.translation,
                  style: AppTextStyles.heading2.copyWith(
                    color: context.colorInk,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _SpeakButton(onPressed: onSpeakTranslation, color: color),
            ],
          ),
        ],
      ),
    );
  }

  /// "🇫🇷 French → 🇬🇧 English", or just the one side that's known, or null
  /// when neither language resolves to a catalog entry.
  String? _pairLabel() {
    final source = VocabularyLanguages.byCode(card.sourceLanguage);
    final target = VocabularyLanguages.byCode(card.targetLanguage);
    String label(VocabularyLanguage l) => '${l.flag} ${l.name}';
    if (source != null && target != null) {
      return '${label(source)}  →  ${label(target)}';
    }
    if (target != null) return label(target);
    if (source != null) return label(source);
    return null;
  }
}

/// A round "hear this" button. [prominent] fills it with the accent colour
/// for the screen's one primary action (hearing the word); otherwise it's a
/// quiet tinted button for secondary listens (the translation, examples).
class _SpeakButton extends StatelessWidget {
  const _SpeakButton({
    required this.onPressed,
    required this.color,
    this.prominent = false,
  });

  final VoidCallback onPressed;
  final Color color;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final fill = prominent ? AppColors.accent : color.withValues(alpha: 0.16);
    final iconColor = prominent ? Colors.white : color;
    final size = prominent ? 48.0 : 40.0;

    return Material(
      color: fill,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.volume_up_rounded,
            color: iconColor,
            size: prominent ? 24 : 20,
            semanticLabel: LocaleKeys.cardDetailListen.tr,
          ),
        ),
      ),
    );
  }
}

/// One example sentence on its own card, the whole row tappable to hear it
/// read aloud in the word's language.
class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.sentence,
    required this.hue,
    required this.onSpeak,
  });

  final String sentence;
  final AppHue hue;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onSpeak,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    sentence,
                    style: AppTextStyles.body.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.volume_up_rounded,
                  size: 20,
                  color: hue.resolve(context),
                  semanticLabel: LocaleKeys.cardDetailListen.tr,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small tracked-out label that heads a section (Meaning, Examples).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.label.copyWith(color: context.colorInkMuted),
    );
  }
}

/// The spaced-repetition status, shown as a quiet pill rather than a bare
/// line so it reads as a status chip, not body copy.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: context.colorInkMuted,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: context.colorInkMuted,
              ),
            ),
          ),
        ],
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
        ),
      ),
    );
  }
}
