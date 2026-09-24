import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/services/speech/text_to_speech_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/review_grade.dart';
import '../card_detail/card_detail_view.dart';

/// A spaced-repetition study session for one deck: cards due for review are
/// shown one at a time, flipped to reveal the answer, then graded on
/// Anki's four-level scale. Grading persists the SM-2 schedule immediately
/// (`DeckRepository.submitReview`); an "Again" grade also requeues the card
/// a few cards later in this same session.
class StudySessionView extends StatefulWidget {
  const StudySessionView({
    super.key,
    required this.flashcards,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final List<Flashcard> flashcards;
  final String? sourceLanguage;
  final String targetLanguage;

  @override
  State<StudySessionView> createState() => _StudySessionViewState();
}

class _StudySessionViewState extends State<StudySessionView>
    with SingleTickerProviderStateMixin {
  DeckRepository get _deckRepository => Get.find<DeckRepository>();

  late final List<Flashcard> _queue;
  late final int _initialTotal;
  late final bool _nothingWasDue;
  int _cardInstanceKey = 0;
  bool _isSubmitting = false;

  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  final _gradeTally = {for (final grade in ReviewGrade.values) grade: 0};

  @override
  void initState() {
    super.initState();
    final due = widget.flashcards.where((card) => card.isDue).toList();
    _nothingWasDue = due.isEmpty;
    _queue = due.isEmpty ? List.of(widget.flashcards) : due;
    _initialTotal = _queue.length;
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Flashcard? get _current => _queue.isEmpty ? null : _queue.first;

  void _reveal() {
    if (_flipController.isAnimating || _flipController.value > 0) return;
    _flipController.forward();
  }

  Future<void> _grade(ReviewGrade grade) async {
    final card = _current;
    if (card == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final updated = await _deckRepository.submitReview(card, grade);
      _gradeTally[grade] = (_gradeTally[grade] ?? 0) + 1;

      setState(() {
        _queue.removeAt(0);
        if (grade == ReviewGrade.again) {
          final reinsertAt = min(3, _queue.length);
          _queue.insert(reinsertAt, updated);
        }
        _cardInstanceKey++;
        _isSubmitting = false;
      });
      _flipController.value = 0;
    } catch (_) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: Get.back,
        ),
        title: current == null
            ? null
            : Text(
                LocaleKeys.studyProgress.trParams({
                  'current':
                      '${(_initialTotal - _queue.length).clamp(0, _initialTotal)}',
                  'total': '$_initialTotal',
                }),
                style: AppTextStyles.bodyMedium,
              ),
        actions: [
          if (current != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => Get.to(
                () => CardDetailView(
                  card: current,
                  sourceLanguage: widget.sourceLanguage,
                  targetLanguage: widget.targetLanguage,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: current == null
            ? _SummaryView(
                totalReviewed: _initialTotal,
                gradeTally: _gradeTally,
                onDone: () => Get.back(),
              )
            : Column(
                children: [
                  LinearProgressIndicator(
                    value: _initialTotal == 0
                        ? 0
                        : (_initialTotal - _queue.length) / _initialTotal,
                    minHeight: 3,
                    backgroundColor: context.colorSurface,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                  if (_nothingWasDue)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Text(
                        LocaleKeys.studyNothingDueBody.tr,
                        style: AppTextStyles.caption.copyWith(
                          color: context.colorInkMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _FlipCard(
                          key: ValueKey(_cardInstanceKey),
                          card: current,
                          sourceLanguage: widget.sourceLanguage,
                          targetLanguage: widget.targetLanguage,
                          flipController: _flipController,
                          onTapFront: _reveal,
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _flipController,
                    builder: (context, child) => AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _flipController.value > 0.5 ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: _flipController.value <= 0.5,
                        child: child,
                      ),
                    ),
                    child: _GradeButtonRow(
                      isSubmitting: _isSubmitting,
                      onGrade: _grade,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    super.key,
    required this.card,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.flipController,
    required this.onTapFront,
  });

  final Flashcard card;
  final String? sourceLanguage;
  final String targetLanguage;
  final AnimationController flipController;
  final VoidCallback onTapFront;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipController,
      builder: (context, _) {
        final angle = flipController.value * pi;
        final showBack = angle > pi / 2;
        return GestureDetector(
          onTap: showBack ? null : onTapFront,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _CardFace(
                      isBack: true,
                      card: card,
                      sourceLanguage: sourceLanguage,
                      targetLanguage: targetLanguage,
                    ),
                  )
                : _CardFace(
                    isBack: false,
                    card: card,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                  ),
          ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.isBack,
    required this.card,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  final bool isBack;
  final Flashcard card;
  final String? sourceLanguage;
  final String targetLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isBack ? card.translation : card.word,
              style: AppTextStyles.heading1.copyWith(
                color: isBack ? AppColors.accent : context.colorInk,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.volume_up_outlined),
              color: AppColors.accent,
              onPressed: () => Get.find<TextToSpeechService>().speak(
                isBack ? card.translation : card.word,
                languageCode: isBack ? targetLanguage : sourceLanguage,
              ),
            ),
            if (!isBack) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.studyTapToReveal.tr,
                style: AppTextStyles.caption.copyWith(
                  color: context.colorInkMuted,
                ),
              ),
            ],
            if (isBack && card.wordDescription != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                card.wordDescription!,
                style: AppTextStyles.body.copyWith(
                  color: context.colorInkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeButtonRow extends StatelessWidget {
  const _GradeButtonRow({required this.isSubmitting, required this.onGrade});

  final bool isSubmitting;
  final ValueChanged<ReviewGrade> onGrade;

  static const _colors = {
    ReviewGrade.again: AppColors.error,
    ReviewGrade.hard: Color(0xFFD98A3D),
    ReviewGrade.good: AppColors.success,
    ReviewGrade.easy: Color(0xFF3B82C4),
  };

  static const _labels = {
    ReviewGrade.again: LocaleKeys.studyGradeAgain,
    ReviewGrade.hard: LocaleKeys.studyGradeHard,
    ReviewGrade.good: LocaleKeys.studyGradeGood,
    ReviewGrade.easy: LocaleKeys.studyGradeEasy,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          for (final grade in ReviewGrade.values) ...[
            if (grade != ReviewGrade.again)
              const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: isSubmitting ? null : () => onGrade(grade),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _colors[grade],
                  side: BorderSide(color: _colors[grade]!),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
                child: Text(_labels[grade]!.tr),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.totalReviewed,
    required this.gradeTally,
    required this.onDone,
  });

  final int totalReviewed;
  final Map<ReviewGrade, int> gradeTally;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.celebration_outlined,
            size: 56,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            LocaleKeys.studyCompleteTitle.tr,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.studyCompleteBody.trParams({'count': '$totalReviewed'}),
            style: AppTextStyles.body.copyWith(color: context.colorInkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              for (final grade in ReviewGrade.values)
                _TallyChip(
                  color: _GradeButtonRow._colors[grade]!,
                  label: _GradeButtonRow._labels[grade]!.tr,
                  count: gradeTally[grade] ?? 0,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg * 1.5),
          AppButton(label: LocaleKeys.studyDone.tr, onPressed: onDone),
        ],
      ),
    );
  }
}

class _TallyChip extends StatelessWidget {
  const _TallyChip({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '$count $label',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
