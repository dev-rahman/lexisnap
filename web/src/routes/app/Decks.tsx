import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Layers, BookOpen, Zap, ScanLine, Sparkles } from "lucide-react";

import { DeckTile, DeckTileSkeleton } from "@/components/decks/DeckTile";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { useT } from "@/providers/I18nProvider";
import {
  DECKS_PAGE_SIZE,
  useGetDecksQuery,
  useGetDeckTotalsQuery,
  useGetDueCardsQuery,
} from "@/store/api/decksApi";
import { cn } from "@/lib/utils/cn";

function Stat({
  icon,
  value,
  label,
  className,
}: {
  icon: React.ReactNode;
  value: number | string;
  label: string;
  className?: string;
}) {
  return (
    <div className="flex flex-col items-center gap-1 rounded-2xl bg-card p-4 text-center shadow-card">
      <div className={cn("mb-0.5", className)}>{icon}</div>
      <div className="font-display text-2xl font-extrabold text-ink">{value}</div>
      <div className="text-xs font-semibold text-ink-muted">{label}</div>
    </div>
  );
}

export function Decks() {
  const t = useT();
  const navigate = useNavigate();
  const [limit, setLimit] = useState(DECKS_PAGE_SIZE);

  const { data: totals } = useGetDeckTotalsQuery();
  const { data: due } = useGetDueCardsQuery();
  const { data: decks, isLoading, isFetching } = useGetDecksQuery(limit);

  const dueCount = due?.length ?? 0;
  const canLoadMore = decks && decks.length >= limit;

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <h1 className="font-display text-[2rem] font-extrabold text-ink">
        {t("nav_decks")}
      </h1>

      {/* Stat row */}
      <div className="grid grid-cols-3 gap-3">
        <Stat
          icon={<Layers size={22} />}
          value={totals?.deckCount ?? 0}
          label={t("decks_stat_decks")}
          className="text-hue-violet"
        />
        <Stat
          icon={<BookOpen size={22} />}
          value={totals?.cardCount ?? 0}
          label={t("decks_stat_words")}
          className="text-hue-teal"
        />
        <Stat
          icon={<Zap size={22} />}
          value={dueCount}
          label={t("decks_stat_due")}
          className="text-coral"
        />
      </div>

      {/* Mixed review */}
      <div className="overflow-hidden rounded-3xl bg-gradient-to-br from-hue-violet to-hue-sky p-5 text-white shadow-card-lift sm:p-6">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <h2 className="flex items-center gap-2 font-display text-xl font-extrabold">
              <Sparkles size={20} /> {t("decks_mixed_title")}
            </h2>
            <p className="mt-1 text-sm text-white/85">
              {dueCount > 0
                ? t("decks_mixed_due", { count: dueCount })
                : t("decks_mixed_practice")}
            </p>
          </div>
          <button
            onClick={() =>
              navigate(dueCount > 0 ? "/study?mixed=1" : "/study?mixed=1&practice=1")
            }
            className="btn3d h-12 shrink-0 bg-white px-5 text-hue-violet shadow-[0_4px_0_rgb(0_0_0/0.12)] active:shadow-[0_1px_0_rgb(0_0_0/0.12)]"
          >
            {t("deck_study")}
          </button>
        </div>
      </div>

      {/* Deck grid */}
      <section>
        <h2 className="mb-3 font-display text-xl font-extrabold text-ink">
          {t("decks_all")}
        </h2>
        {isLoading ? (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <DeckTileSkeleton key={i} />
            ))}
          </div>
        ) : decks && decks.length > 0 ? (
          <>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
              {decks.map((deck) => (
                <DeckTile key={deck.id} deck={deck} />
              ))}
            </div>
            {canLoadMore && (
              <div className="mt-6 flex justify-center">
                <Button
                  variant="secondary"
                  loading={isFetching}
                  onClick={() => setLimit((l) => l + DECKS_PAGE_SIZE)}
                >
                  {t("decks_all")}
                </Button>
              </div>
            )}
          </>
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
