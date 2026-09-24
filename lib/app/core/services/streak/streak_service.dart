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
  });

  /// Consecutive study days up to and including today.
  final int current;
  final int longest;
  final int reviewsToday;
  final int dailyGoal;
  final DateTime? lastStudiedAt;

  bool get goalMet => reviewsToday >= dailyGoal;

  double get goalProgress =>
      dailyGoal <= 0 ? 1 : (reviewsToday / dailyGoal).clamp(0.0, 1.0);
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

  static const _currentKey = 'streak_current';
  static const _longestKey = 'streak_longest';
  static const _reviewsTodayKey = 'streak_reviews_today';
  static const _dailyGoalKey = 'streak_daily_goal';
  static const _lastStudiedKey = 'streak_last_studied_at';

  final streak = const StudyStreak().obs;

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

    streak.value = StudyStreak(
      current: isUnbroken ? prefs.getInt(_currentKey) ?? 0 : 0,
      longest: prefs.getInt(_longestKey) ?? 0,
      reviewsToday: isToday ? prefs.getInt(_reviewsTodayKey) ?? 0 : 0,
      dailyGoal: prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal,
      lastStudiedAt: lastStudiedAt,
    );
    return this;
  }

  /// Folds [count] finished reviews into today's tally, extending or
  /// restarting the streak as needed.
  Future<void> recordReviews(int count) async {
    if (count <= 0) return;

    final now = DateTime.now();
    final previous = streak.value;
    final daysSince = previous.lastStudiedAt == null
        ? null
        : studyDaysBetween(previous.lastStudiedAt!, now);

    final isSameDay = daysSince == 0;
    final current = isSameDay
        ? max(previous.current, 1)
        : (daysSince == 1 ? previous.current + 1 : 1);

    final updated = StudyStreak(
      current: current,
      longest: max(current, previous.longest),
      reviewsToday: isSameDay ? previous.reviewsToday + count : count,
      dailyGoal: previous.dailyGoal,
      lastStudiedAt: now,
    );
    streak.value = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentKey, updated.current);
    await prefs.setInt(_longestKey, updated.longest);
    await prefs.setInt(_reviewsTodayKey, updated.reviewsToday);
    await prefs.setString(_lastStudiedKey, now.toIso8601String());
  }

  Future<void> setDailyGoal(int goal) async {
    final clamped = goal.clamp(5, 100);
    final previous = streak.value;
    streak.value = StudyStreak(
      current: previous.current,
      longest: previous.longest,
      reviewsToday: previous.reviewsToday,
      dailyGoal: clamped,
      lastStudiedAt: previous.lastStudiedAt,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, clamped);
  }
}
