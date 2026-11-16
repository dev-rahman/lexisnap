// Port of lib/app/core/utils/study_day.dart.
//
// LexiSnap counts a "study day" from 4am to 4am (like Anki), so a card
// finished late at night still counts toward the day it felt like, and
// "due in 1 day" means "waiting for you tomorrow morning".

export const STUDY_DAY_ROLLOVER_HOUR = 4;

/** The rollover instant that opens the study day containing [at]. */
export function studyDayStart(at: Date): Date {
  const rollover = new Date(
    at.getFullYear(),
    at.getMonth(),
    at.getDate(),
    STUDY_DAY_ROLLOVER_HOUR,
  );
  if (at.getTime() < rollover.getTime()) {
    return new Date(
      at.getFullYear(),
      at.getMonth(),
      at.getDate() - 1,
      STUDY_DAY_ROLLOVER_HOUR,
    );
  }
  return rollover;
}

/**
 * The rollover instant [intervalDays] study days after [reviewedAt]'s day.
 * An interval of 0 returns a moment already past, which is how a lapsed card
 * becomes due again immediately.
 */
export function dueDateAfter(reviewedAt: Date, intervalDays: number): Date {
  const start = studyDayStart(reviewedAt);
  return new Date(
    start.getFullYear(),
    start.getMonth(),
    start.getDate() + intervalDays,
    STUDY_DAY_ROLLOVER_HOUR,
  );
}

/**
 * Whole study days from [from] to [to]. Rounded from hours so a daylight-
 * saving shift can't turn a 23-hour calendar day into zero days.
 */
export function studyDaysBetween(from: Date, to: Date): number {
  const start = studyDayStart(from);
  const end = studyDayStart(to);
  const hours = (end.getTime() - start.getTime()) / (1000 * 60 * 60);
  return Math.round(hours / 24);
}

/** The study day [offset] days from [day], built from calendar components. */
export function studyDayOffset(day: Date, offset: number): Date {
  return new Date(
    day.getFullYear(),
    day.getMonth(),
    day.getDate() + offset,
    STUDY_DAY_ROLLOVER_HOUR,
  );
}
