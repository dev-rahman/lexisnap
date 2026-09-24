import 'dart:math';

import '../../data/models/flashcard.dart';
import '../../data/models/review_grade.dart';

/// How a single card is being asked this time round.
enum StudyStepKind {
  /// Pick the right translation out of four. Cheap to answer, grades
  /// itself, and gives a card the learner barely knows a way to be
  /// answered right - which a blank flip card does not.
  choice,

  /// Free recall: look at the word, answer in your head, flip to check.
  /// Harder and more valuable, so it's reserved for cards already known.
  recall,
}

/// One prompt in a session: a card, how it's being asked, and (for a
/// multiple-choice step) the options to show.
class StudyStep {
  const StudyStep({
    required this.card,
    required this.kind,
    this.options = const [],
    this.answerIndex = -1,
  });

  final Flashcard card;
  final StudyStepKind kind;
  final List<String> options;
  final int answerIndex;
}

/// Drives one study session: which cards, in what order, asked which way.
///
/// Pure logic with no Flutter or GetX dependency, so the session rules can
/// be reasoned about (and tested) without building a widget tree.
class StudySessionEngine {
  StudySessionEngine({
    required List<Flashcard> deck,
    required int cap,
    Random? random,
  }) : _pool = List.of(deck),
       _random = random ?? Random() {
    final due = deck.where((card) => card.isDue).toList();
    nothingWasDue = due.isEmpty;

    final selected = nothingWasDue ? List.of(deck) : due;
    selected.shuffle(_random);
    _queue = selected.take(cap).toList();

    plannedTotal = _queue.length;
    skippedDueCount = max(0, due.length - plannedTotal);
    _step = _buildStep();
  }

  static const _optionCount = 4;

  /// A lapsed card comes back this many cards later - far enough that it
  /// isn't just echoed back, close enough to be re-earned in this sitting.
  static const _requeueGap = 3;

  /// Below this many successful reviews a card is still being learned, so
  /// it's asked as multiple choice rather than free recall.
  static const _recallFromRepetitions = 3;

  final List<Flashcard> _pool;
  final Random _random;

  late final List<Flashcard> _queue;

  /// Cards this session set out to review, before any lapses were requeued.
  late final int plannedTotal;

  /// True when the whole deck was already scheduled ahead - the session
  /// falls back to free practice over every card.
  late final bool nothingWasDue;

  /// Cards that were due but didn't fit under the session cap. Surfaced in
  /// the summary so a second round is one tap away.
  late final int skippedDueCount;

  final Map<ReviewGrade, int> tally = {
    for (final grade in ReviewGrade.values) grade: 0,
  };

  int _retired = 0;
  StudyStep? _step;

  StudyStep? get currentStep => _step;

  bool get isComplete => _step == null;

  int get reviewedCount =>
      tally.values.fold(0, (sum, count) => sum + count);

  /// Cards finished for good, over cards planned. Lapses deliberately
  /// don't advance it - the bar stalling is honest feedback.
  double get progress => plannedTotal == 0 ? 0 : _retired / plannedTotal;

  int get retiredCount => _retired;

  /// Share of answers recalled on the first try, across the session.
  double get accuracy {
    final total = reviewedCount;
    if (total == 0) return 0;
    return (total - tally[ReviewGrade.again]!) / total;
  }

  /// Records [grade] for the current step and moves to the next prompt.
  /// [updated] is the card carrying its new schedule.
  void complete(Flashcard updated, ReviewGrade grade) {
    tally[grade] = tally[grade]! + 1;

    _queue.removeAt(0);
    if (grade == ReviewGrade.again) {
      _queue.insert(min(_requeueGap, _queue.length), updated);
    } else {
      _retired++;
    }

    _step = _buildStep();
  }

  StudyStep? _buildStep() {
    if (_queue.isEmpty) return null;

    final card = _queue.first;
    final distractors = _distractorsFor(card);

    if (card.repetitions >= _recallFromRepetitions ||
        distractors.length < _optionCount - 1) {
      return StudyStep(card: card, kind: StudyStepKind.recall);
    }

    final options = [...distractors, card.translation]..shuffle(_random);
    return StudyStep(
      card: card,
      kind: StudyStepKind.choice,
      options: options,
      answerIndex: options.indexOf(card.translation),
    );
  }

  /// Wrong answers drawn from the same deck, so they're plausible enough
  /// to test the word rather than the process of elimination.
  List<String> _distractorsFor(Flashcard card) {
    final seen = <String>{card.translation};
    final candidates = <String>[];

    for (final other in _pool) {
      if (other.id == card.id) continue;
      if (seen.add(other.translation)) candidates.add(other.translation);
    }

    candidates.shuffle(_random);
    return candidates.take(_optionCount - 1).toList();
  }
}
