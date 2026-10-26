"use client";

import { useRouter } from "next/navigation";
import { ArrowRight, Flame, ScanLine } from "lucide-react";

import { DeckCard } from "@/components/decks/DeckCard";
import { TabScaffold } from "@/components/shell/TabScaffold";
import { WeekStrip } from "@/components/streak/WeekStrip";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { IconTile } from "@/components/ui/IconTile";
import { ProgressRing } from "@/components/ui/ProgressRing";
import { Skeleton } from "@/components/ui/Skeleton";
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

  const { data: due = [], isLoading: dueLoading } = useGetDueCardsQuery();
  const { data: recentDecks = [], isLoading: decksLoading } = useGetDecksQuery(6);

  const firstName = user?.fullName?.trim().split(/\s+/)[0] ?? null;
  const dueCount = due.length;
  const sessionSize = Math.min(dueCount, streak.dailyGoal);
  const minutes = Math.max(1, Math.round((sessionSize * 6) / 60));
  const caughtUp = dueCount === 0;

  const reviewHref = studyMode === "listen" ? "/listen?mode=due" : "/study?mode=due";
  const practiceHref = studyMode === "listen" ? "/listen?mode=practice" : "/study?mode=practice";

  return (
    <TabScaffold active="home">
      <div className="mb-6">
        <h1 className="text-[28px] font-bold text-ink md:text-3xl">
          {firstName ? t("home_greeting", { name: firstName }) : t("home_greeting_generic")}
        </h1>
        <p className="mt-1 text-ink-muted">{t("home_subtitle")}</p>
      </div>

      <div className="grid gap-5 lg:grid-cols-5">
        {/* Today — the single focal navy panel */}
        <section className="panel-surface rounded-3xl p-6 lg:col-span-3">
          <div className="mb-5 flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <span className="flex h-10 w-10 items-center justify-center rounded-full bg-white/10">
                <Flame size={20} className="text-accent" />
              </span>
              <div className="leading-tight">
                <div className="font-bold">
                  {streak.current > 0
                    ? t("study_streak_days", { count: streak.current })
                    : t("home_streak_start_hint")}
                </div>
                <div className="text-xs text-white/55">{t("home_streak_best", { count: streak.longest })}</div>
              </div>
            </div>
            <ProgressRing value={goalProgress} size={56} stroke={6}>
              <span className="text-xs font-bold">{Math.round(goalProgress * 100)}%</span>
            </ProgressRing>
          </div>

          <WeekStrip week={week} />

          <div className="mt-6 border-t border-white/10 pt-5">
            {dueLoading ? (
              <Skeleton className="h-[52px] w-full rounded-full bg-white/10" />
            ) : caughtUp ? (
              <>
                <p className="mb-3 text-sm text-white/70">
                  {streak.current > 0 ? t("home_caught_up_today") : t("home_all_caught_up")}
                </p>
                <Button variant="primary" fullWidth onClick={() => router.push(practiceHref)}>
                  {t("home_practice_cta", { count: 10 })}
                </Button>
              </>
            ) : (
              <>
                <div className="mb-3 flex items-center justify-between text-sm text-white/70">
                  <span>{t("home_goal_today", { done: streak.reviewsToday, goal: streak.dailyGoal })}</span>
                  <span>{t("home_review_estimate", { count: minutes })}</span>
                </div>
                <Button variant="primary" fullWidth onClick={() => router.push(reviewHref)}>
                  {sessionSize === 1 ? t("home_review_cta_one") : t("home_review_cta", { count: sessionSize })}
                  <ArrowRight size={18} />
                </Button>
              </>
            )}
          </div>
        </section>

        {/* Scan CTA */}
        <Card
          interactive
          onClick={() => router.push("/scan")}
          className="flex flex-col justify-between p-6 lg:col-span-2"
        >
          <IconTile size="lg" className="bg-accent/12 text-accent">
            <ScanLine size={24} />
          </IconTile>
          <div className="mt-6">
            <div className="text-lg font-bold text-ink">{t("home_scan_cta_title")}</div>
            <p className="mt-1 text-sm text-ink-muted">{t("home_scan_cta_subtitle")}</p>
          </div>
          <div className="mt-4 flex items-center gap-1.5 text-sm font-semibold text-accent">
            {t("scan_source_title")} <ArrowRight size={16} />
          </div>
        </Card>
      </div>

      {/* Recent decks */}
      <div className="mb-4 mt-9 flex items-center justify-between">
        <h2 className="text-lg font-bold text-ink">{t("home_your_decks")}</h2>
        {recentDecks.length > 0 && (
          <button onClick={() => router.push("/decks")} className="text-sm font-semibold text-accent">
            {t("home_see_all")}
          </button>
        )}
      </div>

      {decksLoading ? (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-2xl" />
          ))}
        </div>
      ) : recentDecks.length === 0 ? (
        <Card className="flex flex-col items-center px-8 py-10 text-center">
          <p className="font-bold text-ink">{t("home_no_decks_title")}</p>
          <p className="mt-1 text-sm text-ink-muted">{t("home_no_decks_body")}</p>
        </Card>
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {recentDecks.map((deck) => (
            <DeckCard key={deck.id} deck={deck} />
          ))}
        </div>
      )}
    </TabScaffold>
  );
}
