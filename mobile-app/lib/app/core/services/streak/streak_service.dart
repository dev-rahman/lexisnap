import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/study_day.dart';
import 'streak_rules.dart';

export 'streak_rules.dart' show StreakDay, StudyStreak;

/// Tracks study-day streaks and today's review count, on-device only.
///
/// Consistency is the thing that actually decides whether spaced
/// repetition works, and it is the one part of the loop the scheduler
/// can't influence - so the app surfaces it. Days roll over at the study
/// day boundary (see `study_day.dart`), not midnight, so finishing a
/// session at 1am still counts toward the day it felt like.
///
/// This class owns storage and timing only. Every rule about what a missed
/// day costs, and what a freeze buys back, lives in [StreakRules].
class StreakService extends GetxService with WidgetsBindingObserver {
  static const defaultDailyGoal = StreakRules.defaultDailyGoal;

  static const _currentKey = 'streak_current';
  static const _longestKey = 'streak_longest';
  static const _reviewsTodayKey = 'streak_reviews_today';
  static const _dailyGoalKey = 'streak_daily_goal';
  static const _lastStudiedKey = 'streak_last_studied_at';
  static const _historyKey = 'streak_study_days';
  static const _freezesKey = 'streak_freezes';
  static const _frozenDaysKey = 'streak_frozen_days';

  final streak = const StudyStreak().obs;

  /// The last seven study days, oldest first, with the last being today -
  /// the week strip reads straight from this.
  List<StreakDay> get weekProgress =>
      StreakRules.week(streak.value, DateTime.now());

  /// Missed days a freeze has just covered, for the "freeze saved you"
  /// notice. Zero on every day except the one the user comes back.
  int get justCovered => StreakRules.justCovered(streak.value, DateTime.now());

  int? get daysToNextFreeze => StreakRules.daysToNextFreeze(streak.value);

  Future<StreakService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudiedAt = DateTime.tryParse(
      prefs.getString(_lastStudiedKey) ?? '',
    );

    var history = _readDays(prefs, _historyKey);
    if (history.isEmpty && lastStudiedAt != null) {
      // Upgrading from a build that only stored the streak length: infer
      // the days it must have covered so the strip isn't blank on first
      // launch, then persist so this runs once.
      history = _inferHistory(
        lastStudiedAt: lastStudiedAt,
        streakLength: prefs.getInt(_currentKey) ?? 0,
      );
      await _writeDays(prefs, _historyKey, history);
    }

    // Loaded exactly as stored - including a streak that has since lapsed.
    // Whether it lapsed, or a freeze saved it, is reconcile's call to make,
    // and it can only make it if it sees what the streak was.
    streak.value = StudyStreak(
      current: prefs.getInt(_currentKey) ?? 0,
      longest: prefs.getInt(_longestKey) ?? 0,
      reviewsToday: prefs.getInt(_reviewsTodayKey) ?? 0,
      dailyGoal: prefs.getInt(_dailyGoalKey) ?? defaultDailyGoal,
      lastStudiedAt: lastStudiedAt,
      recentStudyDays: history,
      freezes: prefs.getInt(_freezesKey) ?? 0,
      frozenDays: _readDays(prefs, _frozenDaysKey),
    );
    await _reconcile();

    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// A phone app is resumed far more often than it is cold-started. Without
  /// this, coming back the morning after a missed day would show yesterday's
  /// streak - unspent freeze, stale tally - until the first review.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reconcile();
  }

  /// Folds [count] finished reviews into today's tally, extending, starting
  /// or restoring the streak as needed.
  Future<void> recordReviews(int count) async {
    if (count <= 0) return;

    final now = DateTime.now();
    final updated = StreakRules.recordStudy(
      StreakRules.reconcile(streak.value, now),
      now,
      count,
    );
    streak.value = updated;
    await _persist(updated);
  }

  Future<void> setDailyGoal(int goal) async {
    final clamped = goal.clamp(5, 100);
    streak.value = streak.value.copyWith(dailyGoal: clamped);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, clamped);
  }

  /// Forgets all of the user's study history on this device. Used when
  /// the account itself is deleted, so none of it outlives the account.
  Future<void> reset() async {
    streak.value = const StudyStreak();

    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _currentKey,
      _longestKey,
      _reviewsTodayKey,
      _dailyGoalKey,
      _lastStudiedKey,
      _historyKey,
      _freezesKey,
      _frozenDaysKey,
    ]) {
      await prefs.remove(key);
    }
  }

  Future<void> _reconcile() async {
    final before = streak.value;
    final after = StreakRules.reconcile(before, DateTime.now());
    if (identical(after, before)) return;

    streak.value = after;
    await _persist(after);
  }

  Future<void> _persist(StudyStreak s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentKey, s.current);
    await prefs.setInt(_longestKey, s.longest);
    await prefs.setInt(_reviewsTodayKey, s.reviewsToday);
    await prefs.setInt(_freezesKey, s.freezes);
    if (s.lastStudiedAt != null) {
      await prefs.setString(
        _lastStudiedKey,
        s.lastStudiedAt!.toIso8601String(),
      );
    }
    await _writeDays(prefs, _historyKey, s.recentStudyDays);
    await _writeDays(prefs, _frozenDaysKey, s.frozenDays);
  }

  List<DateTime> _readDays(SharedPreferences prefs, String key) {
    final today = studyDayStart(DateTime.now());
    final days = [
      for (final raw in prefs.getStringList(key) ?? const <String>[])
        if (DateTime.tryParse(raw) case final day?)
          if (studyDaysBetween(day, today) < StreakRules.historyLength) day,
    ];
    days.sort((a, b) => b.compareTo(a));
    return days;
  }

  Future<void> _writeDays(
    SharedPreferences prefs,
    String key,
    List<DateTime> days,
  ) async {
    await prefs.setStringList(key, [
      for (final day in days) day.toIso8601String(),
    ]);
  }

  List<DateTime> _inferHistory({
    required DateTime lastStudiedAt,
    required int streakLength,
  }) {
    final anchor = studyDayStart(lastStudiedAt);
    return [
      for (var i = 0; i < min(streakLength, StreakRules.historyLength); i++)
        DateTime(
          anchor.year,
          anchor.month,
          anchor.day - i,
          studyDayRolloverHour,
        ),
    ];
  }
}
