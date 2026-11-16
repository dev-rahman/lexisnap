import { Link, useNavigate } from "react-router-dom";
import { ArrowRight, Check, ChevronRight, Flame, ScanLine } from "lucide-react";

import { DeckTile, DeckTileSkeleton } from "@/components/decks/DeckTile";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { Skeleton } from "@/components/ui/Skeleton";
import { useStreakView } from "@/lib/hooks/useStreakView";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { openScanPicker } from "@/store/slices/shellSlice";
import { useGetDecksQuery, useGetDueCardsQuery } from "@/store/api/decksApi";

export function Home() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.auth.user);
  const { streak, goalMet } = useStreakView();

  const { data: due, isLoading: dueLoading } = useGetDueCardsQuery();
  const { data: decks, isLoading: decksLoading } = useGetDecksQuery(10);

  const dueCount = due?.length ?? 0;
  const firstName = user?.fullName?.split(" ")[0];
  const practiceLeft = Math.max(1, streak.dailyGoal - streak.reviewsToday);

  // Shared streak + progress line, shown inside the coloured action card.
  const streakLine = (
    <div className="mt-3 flex items-center gap-2 text-sm font-medium text-white/85">
      <Flame size={15} className="shrink-0" />
      <span>{t("home_streak_days", { count: streak.current })}</span>
      <span className="text-white/40">·</span>
      <span>{t("home_today_count", { done: streak.reviewsToday, goal: streak.dailyGoal })}</span>
    </div>
  );

  return (
    <div className="space-y-8">
      {/* Greeting */}
      <header>
        <h1 className="font-display text-3xl font-bold leading-tight text-ink">
          {firstName ? t("home_greeting", { name: firstName }) : t("home_greeting_generic")}
        </h1>
        <p className="mt-1 text-ink-muted">{t("home_subtitle")}</p>
      </header>

      {/* Today's action + Scan — the one thing to do, up top */}
      <section className="grid gap-5 lg:grid-cols-3">
        <div className="lg:col-span-2">
          {dueLoading ? (
            <Skeleton className="h-full min-h-[132px] w-full rounded-2xl" />
          ) : dueCount > 0 ? (
            // Primary: tap the whole card to start reviewing.
            <button
              onClick={() => navigate("/study?mixed=1")}
              className="group flex h-full w-full items-center justify-between gap-4 rounded-2xl bg-gradient-to-br from-coral to-coral-dark p-6 text-left text-white shadow-pop transition-transform active:scale-[0.99] sm:p-7"
            >
              <div>
                <div className="flex items-baseline gap-2.5">
                  <span className="font-display text-5xl font-bold leading-none">{dueCount}</span>
                  <span className="text-lg font-semibold text-white/90">
                    {dueCount === 1 ? t("home_due_today_one") : t("home_due_today")}
                  </span>
                </div>
                {streakLine}
              </div>
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-white text-coral shadow-sm transition-transform group-hover:translate-x-0.5">
                <ArrowRight size={22} />
              </span>
            </button>
          ) : goalMet ? (
            // Caught up: nothing due, goal met.
            <div className="flex h-full items-center justify-between gap-4 rounded-2xl bg-gradient-to-br from-success to-success-dark p-6 text-white shadow-card sm:p-7">
              <div>
                <div className="font-display text-2xl font-bold">{t("home_caught_up_today")}</div>
                {streakLine}
              </div>
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-white/20 text-white">
                <Check size={24} />
              </span>
            </div>
          ) : (
            // Nothing due but goal not met — offer optional extra practice.
            <button
              onClick={() => navigate("/study?mixed=1&practice=1")}
              className="group flex h-full w-full items-center justify-between gap-4 rounded-2xl bg-gradient-to-br from-coral to-coral-dark p-6 text-left text-white shadow-pop transition-transform active:scale-[0.99] sm:p-7"
            >
              <div>
                <div className="font-display text-2xl font-bold">
                  {t("home_practice_cta", { count: practiceLeft })}
                </div>
                {streakLine}
              </div>
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-full bg-white text-coral shadow-sm transition-transform group-hover:translate-x-0.5">
                <ArrowRight size={22} />
              </span>
            </button>
          )}
        </div>

        {/* Scan card */}
        <button onClick={() => dispatch(openScanPicker())} className="block h-full text-left">
          <div className="hover-lift group flex h-full flex-col justify-between gap-6 rounded-2xl border border-border bg-card p-6">
            <div className="flex items-center justify-between">
              <span className="grid h-12 w-12 place-items-center rounded-2xl bg-coral-soft text-coral">
                <ScanLine size={24} />
              </span>
              <ChevronRight className="text-ink-muted transition-transform group-hover:translate-x-1" />
            </div>
            <div>
              <h3 className="font-display text-lg font-bold text-ink">{t("home_scan_cta_title")}</h3>
              <p className="mt-1 text-sm text-ink-muted">{t("home_scan_cta_subtitle")}</p>
            </div>
          </div>
        </button>
      </section>

      {/* Recent decks */}
      <section>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="font-display text-xl font-bold text-ink">{t("home_your_decks")}</h2>
          <Link to="/decks" className="flex items-center gap-1 text-sm font-semibold text-coral hover:underline">
            {t("home_see_all")} <ChevronRight size={16} />
          </Link>
        </div>

        {decksLoading ? (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
            {Array.from({ length: 5 }).map((_, i) => (
              <DeckTileSkeleton key={i} />
            ))}
          </div>
        ) : decks && decks.length > 0 ? (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
            {decks.map((deck) => (
              <DeckTile key={deck.id} deck={deck} />
            ))}
          </div>
        ) : (
          <EmptyState
            emoji="📚"
            title={t("home_no_decks_title")}
            description={t("home_no_decks_body")}
            action={
              <Button onClick={() => dispatch(openScanPicker())} leftIcon={<ScanLine size={18} />}>
                {t("nav_scan")}
              </Button>
            }
          />
        )}
      </section>
    </div>
  );
}
