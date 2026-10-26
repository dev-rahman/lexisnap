/// How the learner wants to be asked during a study session.
///
/// [smart] is the default and mixes the kinds of question, which suits
/// people who don't want to think about it. The rest are deliberate
/// overrides: study style is a matter of taste as much as pedagogy, and a
/// learner who prefers one way of working shouldn't have to put up with
/// the app's judgement.
enum StudyMode {
  /// Multiple choice and flip cards mixed at random, card by card,
  /// whatever each card's history.
  smart,

  /// Always four options. The lowest-effort way to review.
  quiz,

  /// Always flip-and-swipe. Harder, and better for retention.
  flip,

  /// Hands-free playback. Reviews nothing and changes no schedule.
  listen;

  bool get isReview => this != StudyMode.listen;
}
