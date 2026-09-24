import 'dart:math';

import '../../data/models/review_grade.dart';

/// The next scheduling state for a flashcard, produced by [calculateNextReview].
class SrsUpdate {
  const SrsUpdate({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
  });

  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
}

/// SM-2, the spaced-repetition algorithm behind Anki. [grade] maps to the
/// classic 0-5 "quality of recall" scale as: again=0, hard=3, good=4, easy=5.
SrsUpdate calculateNextReview({
  required double easeFactor,
  required int intervalDays,
  required int repetitions,
  required ReviewGrade grade,
  DateTime? now,
}) {
  final reviewedAt = now ?? DateTime.now();
  final quality = switch (grade) {
    ReviewGrade.again => 0,
    ReviewGrade.hard => 3,
    ReviewGrade.good => 4,
    ReviewGrade.easy => 5,
  };

  var newEaseFactor =
      easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
  newEaseFactor = max(1.3, newEaseFactor);

  int newRepetitions;
  int newIntervalDays;
  if (quality < 3) {
    newRepetitions = 0;
    newIntervalDays = 1;
  } else {
    newRepetitions = repetitions + 1;
    if (newRepetitions == 1) {
      newIntervalDays = 1;
    } else if (newRepetitions == 2) {
      newIntervalDays = 6;
    } else {
      newIntervalDays = (intervalDays * newEaseFactor).round();
    }
  }

  return SrsUpdate(
    easeFactor: newEaseFactor,
    intervalDays: newIntervalDays,
    repetitions: newRepetitions,
    dueAt: reviewedAt.add(Duration(days: newIntervalDays)),
  );
}
