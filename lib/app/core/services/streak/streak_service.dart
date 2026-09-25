import 'dart:math';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/study_day.dart';

/// A snapshot of how consistently the user has been studying.
class StudyStreak {
  const StudyStreak({
    this.current = 0,
    this.longest = 0,
    this.reviewsToday = 0,
    this.dailyGoal = StreakService.defaultDailyGoal,
    this.lastStudiedAt,
    this.recentStudyDays = const [],
  });

  /// Consecutive study days up to and including today.
  final int current;
  final int longest;
  final int reviewsToday;
  final int dailyGoal;
  final DateTime? lastStudiedAt;

  /// Study-day boundaries the user actually studied on, newest first.
  /// Only the recent past is kept - enough to draw the week strip.
  final List<DateTime> recentStudyDays;

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
  }) {
    return StudyStreak(
      current: current ?? this.current,
      longest: longest ?? this.longest,
      reviewsToday: reviewsToday ?? this.reviewsToday,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
      recentStudyDays: recentStudyDays ?? this.recentStudyDays,
    );
  }
}

/// Tracks study-day streaks and today's review count, on-device only.
///
/// Consistency is the thing that actually decides whether spaced
/// repetition works, and it is the one part of the loop the scheduler
/// can't influence - so the app surfaces it. Days roll over at the study
/// day boundary (see `study_day.dart`), not midnight, so finishing a
/// session at 1am still counts toward the day it felt like.
class StreakService extends GetxService {
  static const defaultDailyGoal = 20;

  /// Days of history retained. The week strip shows seven; the rest is
  /// slack so a day isn't dropped the moment it scrolls out of view.
  static const _historyLength = 14;

  static const _currentKey = 'streak_current';
  static const _longestKey = 'streak_longest';
  static const _reviewsTodayKey = 'streak_reviews_today';
  static const _dailyGoalKey = 'streak_daily_goal';
  static const _lastStudiedKey = 'streak_last_studied_at';
  static const _historyKey = 'streak_study_days';

  final streak = const StudyStreak().obs;

  /// Seven flags, oldest first, with index 6 being today - the week strip
  /// reads straight from this.
  List<bool> get weekProgress {
    final today = studyDayStart(DateTime.now());
    final days = streak.value.recentStudyDays;

    return List.generate(
      7,
      (index) => days.any((day) => studyDaysBetween(day, today) == 6 - index),
    );
  }

  Future<StreakService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudiedRaw = prefs.getString(_lastStudiedKey);
    final lastStudiedAt = lastStudiedRaw == null
        ? null
        : DateTime.tryParse(lastStudiedRaw);

    final daysSince = lastStudiedAt == null
        ? null
        : studyDaysBetween(lastStudiedAt, DateTime.now());

    // A streak survives one night's gap (yesterday counts); anything older
    // has already been broken, and today's count starts fresh.
    final isToday = daysSince == 0;
    final isUnbroken = daysSince != null && daysSince <= 1;
    final current = isUnbroken ? prefs.getInt(_currentKey) ?? 0 : 0;

    var history = _readHistory(prefs);
    if (history.isEmpty && lastStudiedAt != null) {
      // Upgrading from a build that only stored the streak length: infer
      // the days it must have covered so the strip isn't blank on first
      // launch, then persist so this runs once.
      history = _inferHistory(
        lastStudiedAt: lastStudiedAt,
        streakLength: prefs.getInt(_currentKey) ?? 0,
      );
      await _writeHistory(prefs, history);
    }

    streak.value = StudyStreak(
      current: current,
      longest: prefs.getInt(_longestKey) ?? 0,
      reviewsToday: isToday ? prefs.getInt(_reviewsTodayKey) ?? 0 : 0,
      dailyGoal: prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal,
      lastStudiedAt: lastStudiedAt,
      recentStudyDays: history,
    );
    return this;
  }

  /// Folds [count] finished reviews into today's tally, extending or
  /// restarting the streak as needed.
  Future<void> recordReviews(int count) async {
    if (count <= 0) return;

    final now = DateTime.now();
    final today = studyDayStart(now);
    final previous = streak.value;
    final daysSince = previous.lastStudiedAt == null
        ? null
        : studyDaysBetween(previous.lastStudiedAt!, now);

    final isSameDay = daysSince == 0;
    final current = isSameDay
        ? max(previous.current, 1)
        : (daysSince == 1 ? previous.current + 1 : 1);

    final history = [...previous.recentStudyDays];
    if (!history.any((day) => day.isAtSameMomentAs(today))) {
      history.insert(0, today);
    }
    history.removeWhere((day) => studyDaysBetween(day, today) >= _historyLength);

    final updated = previous.copyWith(
      current: current,
      longest: max(current, previous.longest),
      reviewsToday: isSameDay ? previous.reviewsToday + count : count,
      lastStudiedAt: now,
      recentStudyDays: history,
    );
    streak.value = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentKey, updated.current);
    await prefs.setInt(_longestKey, updated.longest);
    await prefs.setInt(_reviewsTodayKey, updated.reviewsToday);
    await prefs.setString(_lastStudiedKey, now.toIso8601String());
    await _writeHistory(prefs, history);
  }

  Future<void> setDailyGoal(int goal) async {
    final clamped = goal.clamp(5, 100);
    streak.value = streak.value.copyWith(dailyGoal: clamped);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, clamped);
  }

  List<DateTime> _readHistory(SharedPreferences prefs) {
    final today = studyDayStart(DateTime.now());
    final stored = prefs.getStringList(_historyKey) ?? const [];

    final days = [
      for (final raw in stored)
        if (DateTime.tryParse(raw) case final day?)
          if (studyDaysBetween(day, today) < _historyLength) day,
    ];
    days.sort((a, b) => b.compareTo(a));
    return days;
  }

  Future<void> _writeHistory(
    SharedPreferences prefs,
    List<DateTime> history,
  ) async {
    await prefs.setStringList(_historyKey, [
      for (final day in history) day.toIso8601String(),
    ]);
  }

  List<DateTime> _inferHistory({
    required DateTime lastStudiedAt,
    required int streakLength,
  }) {
    final anchor = studyDayStart(lastStudiedAt);
    return [
      for (var i = 0; i < min(streakLength, _historyLength); i++)
        DateTime(
          anchor.year,
          anchor.month,
          anchor.day - i,
          studyDayRolloverHour,
        ),
    ];
  }
}
