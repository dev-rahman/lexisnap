import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Layers, BookOpen, Zap, ScanLine, Sparkles } from "lucide-react";

import { DeckTile, DeckTileSkeleton } from "@/components/decks/DeckTile";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch } from "@/store/hooks";
import { openScanPicker } from "@/store/slices/shellSlice";
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
    <div className="flex items-center gap-3 rounded-2xl border border-border bg-card p-4">
      <span className={cn("grid h-10 w-10 shrink-0 place-items-center rounded-xl", className)}>
        {icon}
      </span>
      <div>
        <div className="font-display text-2xl font-bold leading-none text-ink">{value}</div>
        <div className="mt-0.5 text-xs text-ink-muted">{label}</div>
      </div>
    </div>
  );
}

export function Decks() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const [limit, setLimit] = useState(DECKS_PAGE_SIZE);

  const { data: totals } = useGetDeckTotalsQuery();
  const { data: due } = useGetDueCardsQuery();
  const { data: decks, isLoading, isFetching } = useGetDecksQuery(limit);

  const dueCount = due?.length ?? 0;
  const canLoadMore = decks && decks.length >= limit;

  return (
    <div className="space-y-7">
      <h1 className="font-display text-3xl font-bold text-ink">{t("nav_decks")}</h1>

      {/* Stat row */}
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
        <Stat
          icon={<Layers size={20} />}
          value={totals?.deckCount ?? 0}
          label={t("decks_stat_decks")}
          className="bg-hue-violet/12 text-hue-violet"
        />
        <Stat
          icon={<BookOpen size={20} />}
          value={totals?.cardCount ?? 0}
          label={t("decks_stat_words")}
          className="bg-hue-teal/12 text-hue-teal"
        />
        <Stat
          icon={<Zap size={20} />}
          value={dueCount}
          label={t("decks_stat_due")}
          className="bg-coral/12 text-coral"
        />
      </div>

      {/* Mixed review — calm navy panel */}
      <div className="rounded-2xl bg-panel p-5 text-white shadow-card sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="min-w-0">
            <h2 className="flex items-center gap-2 font-display text-lg font-bold">
              <Sparkles size={18} className="text-coral" /> {t("decks_mixed_title")}
            </h2>
            <p className="mt-1 text-sm text-white/65">
              {dueCount > 0
                ? t("decks_mixed_due", { count: dueCount })
                : t("decks_mixed_practice")}
            </p>
          </div>
          <Button
            className="shrink-0"
            onClick={() =>
              navigate(dueCount > 0 ? "/study?mixed=1" : "/study?mixed=1&practice=1")
            }
          >
            {t("deck_study")}
          </Button>
        </div>
      </div>

      {/* Deck grid */}
      <section>
        <h2 className="mb-4 font-display text-xl font-bold text-ink">{t("decks_all")}</h2>
        {isLoading ? (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
            {Array.from({ length: 10 }).map((_, i) => (
              <DeckTileSkeleton key={i} />
            ))}
          </div>
        ) : decks && decks.length > 0 ? (
          <>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5">
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
