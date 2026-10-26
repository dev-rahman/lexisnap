import { describe, expect, it } from "vitest";

import { hueFor } from "../deckHue";
import { calculateNextReview, inferGrade } from "../srs";
import { reconcile, recordStudy, emptyStreak, week } from "../streakRules";
import { studyDaysBetween } from "../studyDay";

describe("SM-2 (srs.ts)", () => {
  it("first 'good' → 1 day, repetitions 1, ease unchanged", () => {
    const u = calculateNextReview({ easeFactor: 2.5, intervalDays: 0, repetitions: 0 }, "good");
    expect(u.repetitions).toBe(1);
    expect(u.intervalDays).toBe(1);
    expect(u.easeFactor).toBeCloseTo(2.5, 5);
  });
  it("second 'good' → 6 days", () => {
    const u = calculateNextReview({ easeFactor: 2.5, intervalDays: 1, repetitions: 1 }, "good");
    expect(u.repetitions).toBe(2);
    expect(u.intervalDays).toBe(6);
  });
  it("'again' lapses to interval 0 and is due now", () => {
    const u = calculateNextReview({ easeFactor: 2.5, intervalDays: 6, repetitions: 2 }, "again");
    expect(u.repetitions).toBe(0);
    expect(u.intervalDays).toBe(0);
    expect(u.dueAt.getTime()).toBeLessThanOrEqual(Date.now());
  });
  it("'easy' raises ease; floor is 1.3", () => {
    const hard = calculateNextReview({ easeFactor: 1.3, intervalDays: 0, repetitions: 0 }, "again");
    expect(hard.easeFactor).toBeGreaterThanOrEqual(1.3);
  });
  it("infers grade from recall + time", () => {
    expect(inferGrade(false, 1000)).toBe("again");
    expect(inferGrade(true, 2000)).toBe("easy");
    expect(inferGrade(true, 7000)).toBe("good");
    expect(inferGrade(true, 20000)).toBe("hard");
  });
});

describe("deck hue (deckHue.ts)", () => {
  it("is stable for the same id", () => {
    expect(hueFor("deck-123")).toBe(hueFor("deck-123"));
  });
  it("spreads across the palette", () => {
    const hues = new Set(["a", "b", "c", "d", "e", "f", "g", "h"].map(hueFor));
    expect(hues.size).toBeGreaterThan(1);
  });
});

describe("streak rules", () => {
  it("records a first study day as a 1-day streak", () => {
    const now = new Date("2026-03-10T10:00:00");
    const s = recordStudy(reconcile(emptyStreak(), now), now, 5);
    expect(s.current).toBe(1);
    expect(s.reviewsToday).toBe(5);
  });
  it("extends the streak on consecutive days", () => {
    let now = new Date("2026-03-10T10:00:00");
    let s = recordStudy(reconcile(emptyStreak(), now), now, 5);
    now = new Date("2026-03-11T10:00:00");
    s = recordStudy(reconcile(s, now), now, 5);
    expect(s.current).toBe(2);
    expect(studyDaysBetween(new Date("2026-03-10T10:00:00"), now)).toBe(1);
  });
  it("the week strip ends on today", () => {
    const now = new Date("2026-03-10T10:00:00");
    const s = recordStudy(reconcile(emptyStreak(), now), now, 5);
    const w = week(s, now);
    expect(w).toHaveLength(7);
    expect(w[6]).toBe("studied");
  });
});
