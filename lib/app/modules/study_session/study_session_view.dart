import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/localization/locale_keys.dart';
import '../../core/services/deck/deck_repository.dart';
import '../../core/services/streak/streak_service.dart';
import '../../core/services/study/study_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/review_grade.dart';
import '../card_detail/card_detail_view.dart';
import 'study_session_engine.dart';
import 'widgets/choice_round.dart';
import 'widgets/session_progress_bar.dart';
import 'widgets/session_summary.dart';
import 'widgets/swipe_flashcard.dart';

/// A spaced-repetition study session for one deck.
///
/// The session asks each card the way the chosen study mode says -
/// multiple choice, a flip card, or in Smart mode a random mix of the two
/// - and never asks the learner to grade themselves. Answers are either a
/// tap on an option or a swipe, and the SM-2 grade is inferred from the
/// answer plus how long it took (see [ReviewGrade.infer]).
///
/// Sessions are capped at the user's daily goal so they always end.
class StudySessionView extends StatefulWidget {
  const StudySessionView({
    super.key,
    required this.flashcards,
    this.practiceOnly = false,
    this.cap,
  });

  final List<Flashcard> flashcards;

  /// Practice ahead of schedule: grades are shown and counted, but no
  /// SM-2 update is written.
  ///
  /// SM-2 assumes a card was reviewed *when it came due*. Grading a card
  /// five days early and stretching its interval from that would inflate
  /// the schedule for retention the learner hasn't demonstrated yet, so
  /// extra rounds deliberately leave `due_at`, the interval and the ease
  /// factor exactly where the scheduler put them.
  final bool practiceOnly;

  /// Cards to serve in this sitting. Defaults to the user's daily goal,
  /// which is the right cap for the day's real reviews; extra practice
  /// passes its own smaller number.
  final int? cap;

  @override
  State<StudySessionView> createState() => _StudySessionViewState();
}

class _StudySessionViewState extends State<StudySessionView> {
  DeckRepository get _deckRepository => Get.find<DeckRepository>();
  StreakService get _streakService => Get.find<StreakService>();

  /// The deck as this session knows it, kept current as cards are graded
  /// so a follow-on round can be started without refetching.
  late List<Flashcard> _deck = List.of(widget.flashcards);

  late StudySessionEngine _engine = _newEngine();

  int _stepKey = 0;
  bool _isSubmitting = false;

  /// Freezes banked when this round began. A higher count at the summary
  /// means the round itself earned one, which is worth saying out loud.
  ///
  /// Captured in [initState], deliberately not a lazy `late` initializer:
  /// that would run on first read - the summary - after the freeze had
  /// already been banked, and the round would never report earning one.
  late int _freezesAtStart;

  @override
  void initState() {
    super.initState();
    _freezesAtStart = _streakService.streak.value.freezes;
  }

  StudySessionEngine _newEngine() => StudySessionEngine(
    deck: _deck,
    cap: widget.cap ?? _streakService.streak.value.dailyGoal,
    mode: Get.find<StudyPreferencesService>().mode.value,
  );

  Future<void> _answer(bool recalled, Duration timeToAnswer) async {
    final step = _engine.currentStep;
    if (step == null || _isSubmitting) return;

    _isSubmitting = true;
    final grade = ReviewGrade.infer(
      recalled: recalled,
      timeToAnswer: timeToAnswer,
    );

    try {
      // Practice rounds leave the schedule alone - see [practiceOnly].
      final updated = widget.practiceOnly
          ? step.card
          : await _deckRepository.submitReview(step.card, grade);
      if (!mounted) return;

      final retiredBefore = _engine.retiredCount;
      setState(() {
        _deck = [
          for (final card in _deck) card.id == updated.id ? updated : card,
        ];
        _engine.complete(updated, grade);
        _stepKey++;
      });

      // Credited per card, the moment it's done - not once at the end.
      // The reviews themselves were already saved card by card, so crediting
      // only a *finished* session meant someone could answer fifteen of
      // twenty cards, close the session, and still wake up to a broken
      // streak for a day they plainly studied.
      final retired = _engine.retiredCount - retiredBefore;
      if (retired > 0) await _streakService.recordReviews(retired);
    } catch (_) {
      AppSnackbar.error(LocaleKeys.commonSomethingWentWrong.tr);
    } finally {
      _isSubmitting = false;
    }
  }

  bool _isConfirmingLeave = false;

  /// Asks before walking out of a session part-way through. Every answer is
  /// saved the moment it's given, so leaving loses nothing - the sheet is
  /// there for the accidental tap on the X or a stray back swipe.
  Future<void> _confirmLeave() async {
    if (_isConfirmingLeave) return;
    _isConfirmingLeave = true;

    final remaining = _engine.plannedTotal - _engine.retiredCount;
    final leave = await showConfirmSheet(
      context,
      icon: Icons.exit_to_app_rounded,
      title: LocaleKeys.studyLeaveTitle.tr,
      body: remaining == 1
          ? LocaleKeys.studyLeaveBodyOne.tr
          : LocaleKeys.studyLeaveBody.trParams({'count': '$remaining'}),
      confirmLabel: LocaleKeys.studyLeaveConfirm.tr,
      cancelLabel: LocaleKeys.studyLeaveKeepGoing.tr,
      destructive: false,
    );

    _isConfirmingLeave = false;
    // A direct pop, not Get.back: that one closes an open snackbar instead
    // of the screen.
    if (leave && mounted) Navigator.of(context).pop();
  }

  void _startNextRound() => setState(() {
    _engine = _newEngine();
    _stepKey++;
    // Each round's summary reports only what that round earned.
    _freezesAtStart = _streakService.streak.value.freezes;
  });

  @override
  Widget build(BuildContext context) {
    final step = _engine.currentStep;

    // Mid-session, every way out - the X, Android's back button, the iOS
    // swipe - goes through [_confirmLeave]. Once the summary is up there's
    // nothing left to interrupt, so leaving is free.
    return PopScope(
      canPop: step == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: step == null
              ? null
              : Text(
                  LocaleKeys.studyProgress.trParams({
                    'current': '${_engine.retiredCount}',
                    'total': '${_engine.plannedTotal}',
                  }),
                  style: AppTextStyles.caption.copyWith(
                    color: context.colorInkMuted,
                  ),
                ),
          actions: [
            if (step != null)
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => Get.to(() => CardDetailView(card: step.card)),
              ),
          ],
        ),
        body: SafeArea(
          child: step == null ? _buildSummary() : _buildStep(context, step),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Obx(
      () => SessionSummary(
        reviewedCount: _engine.retiredCount,
        accuracy: _engine.accuracy,
        tally: _engine.tally,
        streak: _streakService.streak.value,
        freezeEarned: _streakService.streak.value.freezes > _freezesAtStart,
        remainingDueCount: _engine.skippedDueCount,
        onDone: Get.back,
        onContinue: _startNextRound,
      ),
    );
  }

  Widget _buildStep(BuildContext context, StudyStep step) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SessionProgressBar(
            total: _engine.plannedTotal,
            completed: _engine.retiredCount,
          ),
        ),
        if (_engine.nothingWasDue)
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
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_stepKey),
                child: switch (step.kind) {
                  StudyStepKind.choice => ChoiceRound(
                    card: step.card,
                    options: step.options,
                    answerIndex: step.answerIndex,
                    onAnswer: _answer,
                  ),
                  StudyStepKind.recall => SwipeFlashcard(
                    card: step.card,
                    onAnswer: _answer,
                  ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
