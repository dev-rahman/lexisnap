/// How well a user recalled a flashcard during a study session, in the
/// same four-level scale Anki uses.
///
/// Learners never pick one of these themselves - asking someone to rate
/// their own recall on a four-point scale is a scheduling decision they
/// have no way to make well, and it costs a deliberate tap on every card.
/// The study session collects a yes/no ("did you get it?") and infers the
/// grade from how long the answer took; see [ReviewGrade.infer].
enum ReviewGrade {
  again,
  hard,
  good,
  easy;

  /// Answered this fast, the word is genuinely known rather than worked out.
  static const quickThreshold = Duration(seconds: 4);

  /// Past this, a correct answer was reconstructed, not recalled - worth
  /// showing again sooner than a confident one.
  static const laboredThreshold = Duration(seconds: 10);

  /// Maps a yes/no answer plus [timeToAnswer] onto the four-level scale.
  /// [timeToAnswer] runs from the moment the prompt appeared to the moment
  /// the learner committed - tapping an option, or tapping to reveal.
  static ReviewGrade infer({
    required bool recalled,
    required Duration timeToAnswer,
  }) {
    if (!recalled) return ReviewGrade.again;
    if (timeToAnswer <= quickThreshold) return ReviewGrade.easy;
    if (timeToAnswer <= laboredThreshold) return ReviewGrade.good;
    return ReviewGrade.hard;
  }
}
