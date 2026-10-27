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
import { useAppSelector } from "@/store/hooks";
import { useGetDecksQuery, useGetDueCardsQuery } from "@/store/api/decksApi";

export function Home() {
  const t = useT();
  const navigate = useNavigate();
  const user = useAppSelector((s) => s.auth.user);
  const { streak, week, goalMet, goalProgress } = useStreakView();

  const { data: due } = useGetDueCardsQuery();
  const { data: decks, isLoading: decksLoading } = useGetDecksQuery(6);

  const dueCount = due?.length ?? 0;
  const firstName = user?.fullName?.split(" ")[0];

  return (
    <div className="mx-auto max-w-3xl space-y-7">
      {/* Greeting */}
      <header className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-[2rem] font-extrabold leading-tight text-ink">
            {firstName
              ? t("home_greeting", { name: firstName })
              : t("home_greeting_generic")}
          </h1>
          <p className="mt-0.5 text-ink-muted">{t("home_subtitle")}</p>
        </div>
      </header>

      {/* Today hero */}
      <section className="relative overflow-hidden rounded-[2rem] bg-gradient-to-br from-coral via-coral to-flame p-6 text-white shadow-card-lift sm:p-7">
        <div
          className="pointer-events-none absolute -right-10 -top-12 h-48 w-48 rounded-full bg-white/10"
          aria-hidden
        />
        <div className="relative flex flex-col gap-6 sm:flex-row sm:items-center">
          <ProgressRing
            progress={goalProgress}
            size={128}
            stroke={13}
            barClassName="text-white"
            trackClassName="text-white/25"
          >
            <div className="px-2 text-center">
              <div className="font-display text-4xl font-extrabold leading-none">
                {streak.reviewsToday}
                <span className="text-xl font-bold text-white/70">/{streak.dailyGoal}</span>
              </div>
              <div className="mt-1 text-[11px] font-bold uppercase leading-tight tracking-wide text-white/75">
                {t("decks_stat_words")}
              </div>
            </div>
          </ProgressRing>

          <div className="flex-1">
            <div className="flex items-center gap-3">
              <StreakFlame count={streak.current} size={44} />
              <div>
                <div className="font-display text-4xl font-extrabold leading-none">
                  {streak.current}
                </div>
                <div className="text-sm font-semibold text-white/80">
                  {t("home_streak_best", { count: streak.longest })}
                </div>
              </div>
            </div>
            <div className="mt-5 rounded-2xl bg-white/12 p-3 backdrop-blur-sm">
              <WeekStrip days={week} tone="onColor" />
            </div>
          </div>
        </div>

        <div className="relative mt-6">
          {dueCount > 0 ? (
            <button
              onClick={() => navigate("/study?mixed=1")}
              className="btn3d h-14 w-full bg-white text-coral shadow-[0_4px_0_rgb(0_0_0/0.12)] active:shadow-[0_1px_0_rgb(0_0_0/0.12)]"
            >
              {dueCount === 1
                ? t("home_review_cta_one")
                : t("home_review_cta", { count: dueCount })}
              <ArrowRight size={20} />
            </button>
          ) : goalMet ? (
            <div className="flex items-center justify-center gap-2 rounded-2xl bg-white/15 py-3.5 font-display text-lg font-bold">
              🎉 {t("home_caught_up_today")}
            </div>
          ) : (
            <button
              onClick={() => navigate("/study?mixed=1&practice=1")}
              className="btn3d h-14 w-full bg-white text-coral shadow-[0_4px_0_rgb(0_0_0/0.12)] active:shadow-[0_1px_0_rgb(0_0_0/0.12)]"
            >
              {t("home_practice_cta")}
              <ArrowRight size={20} />
            </button>
          )}
        </div>
      </section>

      {/* Scan card */}
      <Link to="/scan" className="block">
        <div className="hover-lift group flex items-center gap-4 overflow-hidden rounded-3xl border-2 border-hue-violet/25 bg-hue-violet/10 p-5">
          <div className="grid h-14 w-14 shrink-0 place-items-center rounded-2xl bg-hue-violet text-white shadow-[0_4px_0_rgb(var(--hue-violet))] brightness-95">
            <ScanLine size={26} />
          </div>
          <div className="min-w-0 flex-1">
            <h3 className="font-display text-lg font-extrabold text-ink">
              {t("home_scan_cta_title")}
            </h3>
            <p className="text-sm text-ink-muted">{t("home_scan_cta_subtitle")}</p>
          </div>
          <ChevronRight className="text-hue-violet transition-transform group-hover:translate-x-1" />
        </div>
      </Link>

      {/* Recent decks */}
      <section>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-display text-xl font-extrabold text-ink">
            {t("home_your_decks")}
          </h2>
          <Link
            to="/decks"
            className="flex items-center gap-1 text-sm font-bold text-coral hover:underline"
          >
            {t("home_see_all")} <ChevronRight size={16} />
          </Link>
        </div>

        {decksLoading ? (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <DeckTileSkeleton key={i} />
            ))}
          </div>
        ) : decks && decks.length > 0 ? (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
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
              <Button onClick={() => navigate("/scan")} leftIcon={<ScanLine size={18} />}>
                {t("nav_scan")}
              </Button>
            }
          />
        )}
      </section>
    </div>
  );
}
