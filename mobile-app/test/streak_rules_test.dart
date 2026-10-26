import 'package:flutter_test/flutter_test.dart';
import 'package:lexisnap/app/core/services/streak/streak_rules.dart';

/// A moment on day [day] of September 2026, at [hour] local time. The study
/// day rolls over at 4am, so anything before that belongs to the day before.
DateTime at(int day, [int hour = 12]) => DateTime(2026, 9, day, hour);

/// Runs a user's day exactly as the app does: reconcile on arrival, then
/// record whatever they studied.
StudyStreak studyOn(StudyStreak streak, DateTime when, [int count = 5]) =>
    StreakRules.recordStudy(StreakRules.reconcile(streak, when), when, count);

/// Studies every day from [from] to [to] inclusive.
StudyStreak studyEachDay(StudyStreak streak, int from, int to) {
  for (var day = from; day <= to; day++) {
    streak = studyOn(streak, at(day));
  }
  return streak;
}

void main() {
  group('building a streak', () {
    test('first ever review starts a one-day streak', () {
      final s = studyOn(const StudyStreak(), at(1), 3);
      expect(s.current, 1);
      expect(s.longest, 1);
      expect(s.reviewsToday, 3);
    });

    test('consecutive days extend it', () {
      final s = studyEachDay(const StudyStreak(), 1, 4);
      expect(s.current, 4);
      expect(s.longest, 4);
    });

    test('a second session the same day adds reviews, not days', () {
      var s = studyOn(const StudyStreak(), at(1, 9), 5);
      s = studyOn(s, at(1, 20), 7);
      expect(s.current, 1);
      expect(s.reviewsToday, 12);
    });

    test('many sessions in one day store that day once', () {
      // Reviews are credited per card, so a single sitting records dozens
      // of times. Without deduplication the stored history would grow by
      // one entry per card.
      var s = const StudyStreak();
      for (var hour = 5; hour <= 23; hour++) {
        s = studyOn(s, at(1, hour), 1);
      }
      expect(s.recentStudyDays, [DateTime(2026, 9, 1, 4)]);
    });

    test('1am belongs to the study day before, not the calendar day', () {
      var s = studyOn(const StudyStreak(), at(1, 20));
      // 01:00 on the 2nd is still the study day that began at 04:00 on the 1st.
      s = studyOn(s, at(2, 1));
      expect(s.current, 1, reason: 'same study day, no extension');
      s = studyOn(s, at(2, 5));
      expect(s.current, 2, reason: 'after 4am it is a new study day');
    });

    test('reviewsToday resets when a new study day begins', () {
      var s = studyOn(const StudyStreak(), at(1), 9);
      s = StreakRules.reconcile(s, at(2));
      expect(s.reviewsToday, 0);
    });
  });

  group('missing days without freezes', () {
    test('one missed day breaks the streak', () {
      var s = studyEachDay(const StudyStreak(), 1, 5);
      s = StreakRules.reconcile(s, at(7)); // the 6th was missed
      expect(s.current, 0);
      expect(s.longest, 5, reason: 'the record survives the break');
    });

    test('studying after a break starts again from one', () {
      var s = studyEachDay(const StudyStreak(), 1, 5);
      s = studyOn(s, at(7));
      expect(s.current, 1);
    });

    test('yesterday counts: returning the next day is not a miss', () {
      var s = studyEachDay(const StudyStreak(), 1, 5);
      s = StreakRules.reconcile(s, at(6));
      expect(s.current, 5);
    });
  });

  group('earning freezes', () {
    test('reaching day 7 earns one', () {
      final s = studyEachDay(const StudyStreak(), 1, 7);
      expect(s.freezes, 1);
    });

    test('day 6 has not earned one yet', () {
      final s = studyEachDay(const StudyStreak(), 1, 6);
      expect(s.freezes, 0);
    });

    test('a second session on day 7 does not earn a second', () {
      var s = studyEachDay(const StudyStreak(), 1, 7);
      s = studyOn(s, at(7, 21));
      expect(s.freezes, 1);
    });

    test('day 14 earns another', () {
      final s = studyEachDay(const StudyStreak(), 1, 14);
      expect(s.freezes, 2);
    });

    test('the bank is capped', () {
      final s = studyEachDay(const StudyStreak(), 1, 28);
      expect(s.freezes, StreakRules.maxFreezes);
    });
  });

  group('spending freezes', () {
    test('one freeze covers one missed day and keeps the streak', () {
      var s = studyEachDay(const StudyStreak(), 1, 7); // 7 days, 1 freeze
      s = StreakRules.reconcile(s, at(9)); // missed the 8th
      expect(s.current, 7);
      expect(s.freezes, 0);
      expect(s.frozenDays.single, DateTime(2026, 9, 8, 4));
    });

    test('a frozen day holds the streak but does not grow it', () {
      var s = studyEachDay(const StudyStreak(), 1, 7);
      s = studyOn(s, at(9)); // missed the 8th, back on the 9th
      expect(s.current, 8, reason: '7 studied days + today; the 8th adds 0');
    });

    test('two freezes cover a missed weekend', () {
      var s = studyEachDay(const StudyStreak(), 1, 14); // 2 freezes
      s = StreakRules.reconcile(s, at(17)); // missed 15th and 16th
      expect(s.current, 14);
      expect(s.freezes, 0);
      expect(s.frozenDays.take(2), [
        DateTime(2026, 9, 16, 4),
        DateTime(2026, 9, 15, 4),
      ]);
    });

    test('a gap wider than the bank breaks it and keeps the freezes', () {
      var s = studyEachDay(const StudyStreak(), 1, 7); // 1 freeze
      s = StreakRules.reconcile(s, at(10)); // missed the 8th and 9th
      expect(s.current, 0);
      expect(s.freezes, 1, reason: 'not burned on a streak it could not save');
      expect(s.frozenDays, isEmpty);
    });

    test('missing again the day after returning spends the next freeze', () {
      var s = studyEachDay(const StudyStreak(), 1, 14); // 2 freezes
      s = StreakRules.reconcile(s, at(16)); // missed the 15th, came back
      expect(s.freezes, 1);
      s = StreakRules.reconcile(s, at(17)); // opened, never studied the 16th
      expect(s.current, 14);
      expect(s.freezes, 0);
    });

    test('reconcile is idempotent within a study day', () {
      var s = studyEachDay(const StudyStreak(), 1, 7);
      s = StreakRules.reconcile(s, at(9, 8));
      final again = StreakRules.reconcile(s, at(9, 22));
      expect(identical(again, s), isTrue, reason: 'nothing spent twice');
    });

    test('a broken streak is not "saved" by freezes earned later', () {
      var s = studyEachDay(const StudyStreak(), 1, 7);
      s = StreakRules.reconcile(s, at(20)); // long gap, broken
      s = StreakRules.reconcile(s, at(21));
      expect(s.current, 0);
    });
  });

  group('what the UI reads', () {
    test('the week strip shows studied, frozen and missed days', () {
      var s = studyEachDay(const StudyStreak(), 1, 7);
      s = studyOn(s, at(9)); // 8th frozen, 9th studied
      expect(StreakRules.week(s, at(9)), [
        StreakDay.studied, // 3rd
        StreakDay.studied, // 4th
        StreakDay.studied, // 5th
        StreakDay.studied, // 6th
        StreakDay.studied, // 7th
        StreakDay.frozen, // 8th
        StreakDay.studied, // 9th, today
      ]);
    });

    test('an unstudied today reads as missed until it is not', () {
      final s = studyEachDay(const StudyStreak(), 1, 3);
      expect(StreakRules.week(s, at(4)).last, StreakDay.missed);
    });

    test('the "freeze saved you" count is live only on the day back', () {
      var s = studyEachDay(const StudyStreak(), 1, 14);
      s = StreakRules.reconcile(s, at(17)); // 15th and 16th frozen
      expect(StreakRules.justCovered(s, at(17)), 2);

      s = studyOn(s, at(17));
      expect(
        StreakRules.justCovered(s, at(18)),
        0,
        reason: 'the day before was studied, so nothing was just covered',
      );
    });

    test('days to the next freeze counts down and stops when full', () {
      expect(StreakRules.daysToNextFreeze(const StudyStreak()), 7);
      expect(
        StreakRules.daysToNextFreeze(studyEachDay(const StudyStreak(), 1, 5)),
        2,
      );
      expect(
        StreakRules.daysToNextFreeze(studyEachDay(const StudyStreak(), 1, 14)),
        isNull,
      );
    });
  });

  group('calendar edges', () {
    test('a streak across a month boundary stays consecutive', () {
      var s = studyOn(const StudyStreak(), DateTime(2026, 9, 30, 12));
      s = studyOn(s, DateTime(2026, 10, 1, 12));
      expect(s.current, 2);
    });

    test('a streak across the October DST change stays consecutive', () {
      // Europe falls back on 2026-10-25: that calendar day is 25 hours long.
      var s = const StudyStreak();
      for (var day = 23; day <= 27; day++) {
        s = studyOn(s, DateTime(2026, 10, day, 12));
      }
      expect(s.current, 5);
    });

    test('a freeze across the March DST change covers the right day', () {
      // Europe springs forward on 2026-03-29: a 23-hour day.
      var s = const StudyStreak();
      for (var day = 21; day <= 27; day++) {
        s = studyOn(s, DateTime(2026, 3, day, 12));
      }
      expect(s.freezes, 1);
      s = StreakRules.reconcile(s, DateTime(2026, 3, 29, 12)); // missed 28th
      expect(s.current, 7);
      expect(s.frozenDays.single, DateTime(2026, 3, 28, 4));
    });
  });
}
