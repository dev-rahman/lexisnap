import 'dart:math';

import '../../utils/study_day.dart';

/// How one study day went, as the week strip draws it.
enum StreakDay { studied, frozen, missed }

/// A snapshot of how consistently the user has been studying.
class StudyStreak {
  const StudyStreak({
    this.current = 0,
    this.longest = 0,
    this.reviewsToday = 0,
    this.dailyGoal = StreakRules.defaultDailyGoal,
    this.lastStudiedAt,
    this.recentStudyDays = const [],
    this.freezes = 0,
    this.frozenDays = const [],
  });

  /// Consecutive days the streak has been alive, up to and including today.
  /// Frozen days hold the streak together but don't add to it.
  final int current;
  final int longest;
  final int reviewsToday;
  final int dailyGoal;
  final DateTime? lastStudiedAt;

  /// Study-day boundaries the user actually studied on, newest first.
  /// Only the recent past is kept - enough to draw the week strip.
  final List<DateTime> recentStudyDays;

  /// Streak freezes banked and ready to cover a missed day.
  final int freezes;

  /// Study days a freeze covered, newest first. Kept so the week strip can
  /// show *why* the streak survived a gap instead of just papering over it.
  final List<DateTime> frozenDays;

  bool get goalMet => reviewsToday >= dailyGoal;

  double get goalProgress =>
      dailyGoal <= 0 ? 1 : (reviewsToday / dailyGoal).clamp(0.0, 1.0);

  StudyStreak copyWith({
    int? current,
    int? longest,
    int? reviewsToday,
    int? dailyGoal,
    DateTime? lastStudiedAt,
    List<DateTime>? recentStudyDays,
    int? freezes,
    List<DateTime>? frozenDays,
  }) {
    return StudyStreak(
      current: current ?? this.current,
      longest: longest ?? this.longest,
      reviewsToday: reviewsToday ?? this.reviewsToday,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      recentStudyDays: recentStudyDays ?? this.recentStudyDays,
      freezes: freezes ?? this.freezes,
      frozenDays: frozenDays ?? this.frozenDays,
    );
  }
}

/// The streak's rules, as pure functions of a [StudyStreak] and a moment in
/// time. Kept free of storage and Flutter so that the date arithmetic - the
/// part most likely to be wrong by exactly one day - can be tested directly.
///
/// ## Why freezes exist at all
///
/// Spaced repetition already punishes absence: miss four days and you come
/// back to a pile of overdue cards. A streak that *also* drops to zero at
/// that moment stacks a second loss on the first, right when the user is
/// deciding whether to come back at all. Freezes make one or two missed
/// days recoverable, so the streak rewards consistency without turning a
/// single bad week into a reason to quit.
///
/// They are earned by studying, never bought. A freeze costs nothing to
/// provide, and selling protection from a loss the app itself imposes is
/// monetising the user's anxiety.
class StreakRules {
  StreakRules._();

  static const defaultDailyGoal = 20;

  /// Freezes a user can hold at once. Two covers a weekend away; more than
  /// that and a missed week would cost nothing, which is no streak at all.
  static const maxFreezes = 2;

  /// Study days of streak it takes to earn one freeze.
  static const daysPerFreeze = 7;

  /// Study days of history retained. The week strip shows seven; the rest is
  /// slack so a day isn't dropped the moment it scrolls out of view.
  static const historyLength = 14;

  /// The most recent study day the streak was alive on, studied or frozen.
  static DateTime? lastActiveDay(StudyStreak streak) {
    final studied = streak.lastStudiedAt == null
        ? null
        : studyDayStart(streak.lastStudiedAt!);
    final frozen = streak.frozenDays.isEmpty ? null : streak.frozenDays.first;

    if (studied == null) return frozen;
    if (frozen == null) return studied;
    return frozen.isAfter(studied) ? frozen : studied;
  }

  /// Brings [streak] up to [now]: resets today's tally on a new study day,
  /// then spends banked freezes on every day missed since the streak was
  /// last alive - or breaks it, if there aren't enough to cover the gap.
  ///
  /// Idempotent: a streak already reconciled for today comes back as the
  /// same object, so callers can run this on every launch and resume.
  static StudyStreak reconcile(StudyStreak streak, DateTime now) {
    final today = studyDayStart(now);
    var next = streak;

    final lastStudied = streak.lastStudiedAt;
    if (lastStudied != null &&
        studyDaysBetween(lastStudied, now) > 0 &&
        streak.reviewsToday != 0) {
      next = next.copyWith(reviewsToday: 0);
    }

    final lastActive = lastActiveDay(next);
    if (lastActive == null || next.current == 0) return next;

    final missed = studyDaysBetween(lastActive, today) - 1;
    if (missed <= 0) return next;

    if (missed <= next.freezes) {
      return next.copyWith(
        freezes: next.freezes - missed,
        frozenDays: _trim([
          // Newest first, like everything else in the history.
          for (var offset = missed; offset >= 1; offset--)
            _studyDayOffset(lastActive, offset),
          ...next.frozenDays,
        ], today),
      );
    }

    // More days missed than freezes can cover. The freezes are kept rather
    // than burned on a streak they could never have saved.
    return next.copyWith(current: 0);
  }

  /// Records [count] finished reviews at [now]. Expects [streak] to have
  /// been [reconcile]d for [now] first, so any gap is already settled.
  static StudyStreak recordStudy(StudyStreak streak, DateTime now, int count) {
    if (count <= 0) return streak;

    final today = studyDayStart(now);
    final lastStudied = streak.lastStudiedAt;
    final studiedToday =
        lastStudied != null && studyDaysBetween(lastStudied, now) == 0;
    final lastActive = lastActiveDay(streak);

    final int current;
    if (studiedToday) {
      current = max(streak.current, 1);
    } else if (streak.current > 0 &&
        lastActive != null &&
        studyDaysBetween(lastActive, today) == 1) {
      current = streak.current + 1;
    } else {
      current = 1;
    }

    // Earned only when the streak *grows onto* a multiple of the interval,
    // so a second session on day 7 can't earn a second freeze. Frozen days
    // never grow the streak, so freezes can't be farmed with freezes.
    final earned = current > streak.current && current % daysPerFreeze == 0;

    return streak.copyWith(
      current: current,
      longest: max(current, streak.longest),
      reviewsToday: (studiedToday ? streak.reviewsToday : 0) + count,
      lastStudiedAt: now,
      recentStudyDays: _trim([
        today,
        for (final day in streak.recentStudyDays)
          if (studyDaysBetween(day, today) != 0) day,
      ], today),
      freezes: earned ? min(streak.freezes + 1, maxFreezes) : streak.freezes,
    );
  }

  /// The last seven study days, oldest first, ending on today.
  static List<StreakDay> week(StudyStreak streak, DateTime now) {
    final today = studyDayStart(now);

    bool contains(List<DateTime> days, DateTime day) =>
        days.any((d) => studyDaysBetween(d, day) == 0);

    return [
      for (var back = 6; back >= 0; back--)
        if (contains(streak.recentStudyDays, _studyDayOffset(today, -back)))
          StreakDay.studied
        else if (contains(streak.frozenDays, _studyDayOffset(today, -back)))
          StreakDay.frozen
        else
          StreakDay.missed,
    ];
  }

  /// How many missed days freezes covered in the run ending yesterday.
  ///
  /// Non-zero only on the day the user comes back, which is exactly when
  /// saying so matters - by tomorrow, yesterday was a studied day again.
  static int justCovered(StudyStreak streak, DateTime now) {
    final today = studyDayStart(now);
    var count = 0;
    for (var back = 1; back <= streak.frozenDays.length; back++) {
      final day = _studyDayOffset(today, -back);
      if (!streak.frozenDays.any((d) => studyDaysBetween(d, day) == 0)) break;
      count++;
    }
    return count;
  }

  /// Study days until the next freeze is earned, or null when the bank is
  /// full and there is nothing to count down to.
  static int? daysToNextFreeze(StudyStreak streak) {
    if (streak.freezes >= maxFreezes) return null;
    return daysPerFreeze - (streak.current % daysPerFreeze);
  }

  /// The study day [offset] days from [day]. Built from calendar components
  /// rather than by adding 24-hour durations, which would drift by an hour
  /// across a daylight-saving change and land on the wrong side of 4am.
  static DateTime _studyDayOffset(DateTime day, int offset) =>
      DateTime(day.year, day.month, day.day + offset, studyDayRolloverHour);

  static List<DateTime> _trim(List<DateTime> days, DateTime today) => [
    for (final day in days)
      if (studyDaysBetween(day, today) < historyLength) day,
  ];
}
