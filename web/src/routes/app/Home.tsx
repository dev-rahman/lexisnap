import { Link, useNavigate } from "react-router-dom";
import { ArrowRight, ScanLine, ChevronRight } from "lucide-react";

import { DeckTile, DeckTileSkeleton } from "@/components/decks/DeckTile";
import { StreakFlame } from "@/components/streak/StreakFlame";
import { WeekStrip } from "@/components/streak/WeekStrip";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { ProgressRing } from "@/components/ui/ProgressRing";
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
  const { streak, week, goalMet, goalProgress } = useStreakView();

  const { data: due } = useGetDueCardsQuery();
  const { data: decks, isLoading: decksLoading } = useGetDecksQuery(10);

  const dueCount = due?.length ?? 0;
  const firstName = user?.fullName?.split(" ")[0];

  return (
    <div className="space-y-8">
      {/* Greeting */}
      <header>
        <h1 className="font-display text-3xl font-bold leading-tight text-ink">
          {firstName ? t("home_greeting", { name: firstName }) : t("home_greeting_generic")}
        </h1>
        <p className="mt-1 text-ink-muted">{t("home_subtitle")}</p>
      </header>

      {/* Today + Scan — two columns on large screens so wide layouts fill well */}
      <section className="grid gap-5 lg:grid-cols-3">
        {/* Today hero: calm deep-navy panel, coral accent */}
        <div className="rounded-2xl bg-panel p-6 text-white shadow-card lg:col-span-2 lg:p-7">
          <div className="flex flex-col gap-6 sm:flex-row sm:items-center">
            <ProgressRing
              progress={goalProgress}
              size={116}
              stroke={10}
              barClassName="text-coral"
              trackClassName="text-white/15"
            >
              <div className="text-center">
                <div className="font-display text-3xl font-bold leading-none">
                  {streak.reviewsToday}
                  <span className="text-lg font-semibold text-white/55">/{streak.dailyGoal}</span>
                </div>
                <div className="mt-0.5 text-xs font-medium text-white/60">{t("decks_stat_words")}</div>
              </div>
            </ProgressRing>

            <div className="flex-1">
              <div className="flex items-center gap-3">
                <StreakFlame count={streak.current} size={38} />
                <div>
                  <div className="font-display text-3xl font-bold leading-none">{streak.current}</div>
                  <div className="text-sm text-white/55">{t("home_streak_best", { count: streak.longest })}</div>
                </div>
              </div>
              <div className="mt-5">
                <WeekStrip days={week} tone="onColor" />
              </div>
            </div>
          </div>

          <div className="mt-6">
            {dueCount > 0 ? (
              <Button fullWidth size="lg" onClick={() => navigate("/study?mixed=1")} rightIcon={<ArrowRight size={18} />}>
                {dueCount === 1 ? t("home_review_cta_one") : t("home_review_cta", { count: dueCount })}
              </Button>
            ) : goalMet ? (
              <div className="flex items-center justify-center gap-2 rounded-2xl bg-white/10 py-3 font-display text-base font-semibold">
                {t("home_caught_up_today")}
              </div>
            ) : (
              <Button
                fullWidth
                size="lg"
                onClick={() => navigate("/study?mixed=1&practice=1")}
                rightIcon={<ArrowRight size={18} />}
              >
                {t("home_practice_cta")}
              </Button>
            )}
          </div>
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
