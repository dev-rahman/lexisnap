"use client";

import { useRouter } from "next/navigation";
import { Flame, ScanLine } from "lucide-react";

import { DeckCard } from "@/components/decks/DeckCard";
import { TabScaffold } from "@/components/shell/TabScaffold";
import { WeekStrip } from "@/components/streak/WeekStrip";
import { Button } from "@/components/ui/Button";
import { useT } from "@/components/providers/I18nProvider";
import { useStreakView } from "@/lib/hooks/useStreakView";
import { useGetDecksQuery, useGetDueCardsQuery } from "@/store/api/decksApi";
import { useAppSelector } from "@/store/hooks";

export default function HomePage() {
  const t = useT();
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);
  const studyMode = useAppSelector((s) => s.prefs.studyMode);
  const { streak, week, goalProgress } = useStreakView();

  const { data: due = [] } = useGetDueCardsQuery();
  const { data: recentDecks = [] } = useGetDecksQuery(6);

  const firstName = user?.fullName?.trim().split(/\s+/)[0] ?? null;
  const dueCount = due.length;
  const sessionSize = Math.min(dueCount, streak.dailyGoal);
  const minutes = Math.max(1, Math.round((sessionSize * 6) / 60));
  const caughtUp = dueCount === 0;

  const reviewHref =
    studyMode === "listen" ? "/listen?mode=due" : "/study?mode=due";
  const practiceHref =
    studyMode === "listen" ? "/listen?mode=practice" : "/study?mode=practice";

  return (
    <TabScaffold active="home">
      <h1 className="text-2xl font-bold text-ink">
        {firstName
          ? t("home_greeting", { name: firstName })
          : t("home_greeting_generic")}
      </h1>
      <p className="mb-5 mt-0.5 text-ink-muted">{t("home_subtitle")}</p>

      {/* Today — the single navy focal panel. */}
      <section className="panel-surface rounded-xl p-5">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Flame size={20} className="text-accent" />
            <span className="font-semibold">
              {streak.current > 0
                ? t("study_streak_days", { count: streak.current })
                : t("home_streak_start_hint")}
            </span>
          </div>
          <span className="text-sm text-white/60">
            {t("home_streak_best", { count: streak.longest })}
          </span>
        </div>

        <WeekStrip week={week} />

        <div className="mt-5">
          {caughtUp ? (
            <>
              <p className="mb-3 text-sm text-white/70">
                {streak.current > 0
                  ? t("home_caught_up_today")
                  : t("home_all_caught_up")}
              </p>
              <Button
                variant="primary"
                fullWidth
                onClick={() => router.push(practiceHref)}
              >
                {t("home_practice_cta", { count: 10 })}
              </Button>
            </>
          ) : (
            <>
              <div className="mb-3 flex items-center justify-between text-sm text-white/70">
                <span>
                  {t("home_goal_today", {
                    done: streak.reviewsToday,
                    goal: streak.dailyGoal,
                  })}
                </span>
                <span>{t("home_review_estimate", { count: minutes })}</span>
              </div>
              <div className="mb-3 h-1.5 overflow-hidden rounded-full bg-white/15">
                <div
                  className="h-full rounded-full bg-accent"
                  style={{ width: `${Math.round(goalProgress * 100)}%` }}
                />
              </div>
              <Button
                variant="primary"
                fullWidth
                onClick={() => router.push(reviewHref)}
              >
                {sessionSize === 1
                  ? t("home_review_cta_one")
                  : t("home_review_cta", { count: sessionSize })}
              </Button>
            </>
          )}
        </div>
      </section>

      {/* Scan tile */}
      <button
        onClick={() => router.push("/scan")}
        className="mt-4 flex w-full items-center gap-3 rounded-xl border border-border bg-surface p-4 text-left transition active:scale-[0.99]"
      >
        <span className="flex h-11 w-11 items-center justify-center rounded-md bg-accent/15 text-accent">
          <ScanLine size={24} />
        </span>
        <span className="flex-1">
          <span className="block font-semibold text-ink">
            {t("home_scan_cta_title")}
          </span>
          <span className="text-sm text-ink-muted">
            {t("home_scan_cta_subtitle")}
          </span>
        </span>
      </button>

      {/* Recent decks */}
      <div className="mb-3 mt-7 flex items-center justify-between">
        <h2 className="font-bold text-ink">{t("home_your_decks")}</h2>
        {recentDecks.length > 0 && (
          <button
            onClick={() => router.push("/decks")}
            className="text-sm font-medium text-accent"
          >
            {t("home_see_all")}
          </button>
        )}
      </div>
      {recentDecks.length === 0 ? (
        <div className="rounded-xl border border-dashed border-border p-6 text-center">
          <p className="font-semibold text-ink">{t("home_no_decks_title")}</p>
          <p className="mt-1 text-sm text-ink-muted">{t("home_no_decks_body")}</p>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {recentDecks.map((deck) => (
            <DeckCard key={deck.id} deck={deck} />
          ))}
        </div>
      )}
    </TabScaffold>
  );
}
