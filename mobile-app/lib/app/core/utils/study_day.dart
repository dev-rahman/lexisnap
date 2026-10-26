/// LexiSnap counts a "study day" from 4am to 4am rather than midnight to
/// midnight - the same convention Anki uses. Without it, a card finished
/// at 11pm comes due again at 11pm the following night, so an evening
/// learner keeps finding their deck half-empty at the hour they actually
/// study. Anchoring intervals to this boundary means "due in 1 day" always
/// means "waiting for you tomorrow morning."
const int studyDayRolloverHour = 4;

/// The rollover instant that opens the study day containing [at].
DateTime studyDayStart(DateTime at) {
  final rollover = DateTime(at.year, at.month, at.day, studyDayRolloverHour);
  return at.isBefore(rollover)
      ? DateTime(at.year, at.month, at.day - 1, studyDayRolloverHour)
      : rollover;
}

/// The rollover instant [intervalDays] study days after [reviewedAt]'s day.
/// An interval of 0 returns a moment already past, which is how a lapsed
/// card becomes due again immediately.
DateTime dueDateAfter(DateTime reviewedAt, int intervalDays) {
  final start = studyDayStart(reviewedAt);
  return DateTime(
    start.year,
    start.month,
    start.day + intervalDays,
    studyDayRolloverHour,
  );
}

/// Whole study days from [from] to [to]. Rounded from hours so a daylight-
/// saving shift can't turn a 23-hour calendar day into zero days.
int studyDaysBetween(DateTime from, DateTime to) {
  final start = studyDayStart(from);
  final end = studyDayStart(to);
  return (end.difference(start).inHours / 24).round();
}
