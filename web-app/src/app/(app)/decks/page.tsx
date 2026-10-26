"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Layers, Sparkles } from "lucide-react";

import { DeckCard } from "@/components/decks/DeckCard";
import { TabScaffold } from "@/components/shell/TabScaffold";
import { Button } from "@/components/ui/Button";
import { Spinner } from "@/components/ui/Spinner";
import { useT } from "@/components/providers/I18nProvider";
import {
  DECKS_PAGE_SIZE,
  useGetDecksQuery,
  useGetDeckTotalsQuery,
  useGetDueCardsQuery,
} from "@/store/api/decksApi";
import { useAppSelector } from "@/store/hooks";

export default function DecksPage() {
  const t = useT();
  const router = useRouter();
  const studyMode = useAppSelector((s) => s.prefs.studyMode);
  const [limit, setLimit] = useState(DECKS_PAGE_SIZE);

  const { data: decks = [], isLoading, isFetching } = useGetDecksQuery(limit);
  const { data: totals } = useGetDeckTotalsQuery();
  const { data: due = [] } = useGetDueCardsQuery();

  const dueCount = due.length;
  const hasCards = (totals?.cardCount ?? 0) > 0;
  const canLoadMore = decks.length >= limit;

  const mixedHref =
    studyMode === "listen"
      ? dueCount > 0
        ? "/listen?mode=due"
        : "/listen?mode=practice"
      : dueCount > 0
        ? "/study?mode=due"
        : "/study?mode=practice";

  return (
    <TabScaffold active="decks">
      <h1 className="mb-4 text-2xl font-bold text-ink">{t("decks_all")}</h1>

      {/* Stats row */}
      <div className="mb-4 grid grid-cols-3 gap-2.5">
        <Stat label={t("decks_stat_decks")} value={totals?.deckCount ?? 0} />
        <Stat label={t("decks_stat_words")} value={totals?.cardCount ?? 0} />
        <Stat label={t("decks_stat_due")} value={dueCount} />
      </div>

      {/* Mixed review */}
      {hasCards && (
        <button
          onClick={() => router.push(mixedHref)}
          className="panel-surface mb-5 flex w-full items-center gap-3 rounded-xl p-4 text-left transition active:scale-[0.99]"
        >
          <span className="flex h-11 w-11 items-center justify-center rounded-md bg-accent/20 text-accent">
            <Sparkles size={22} />
          </span>
          <span className="flex-1">
            <span className="block font-semibold">{t("decks_mixed_title")}</span>
            <span className="text-sm text-white/70">
              {dueCount > 0
                ? t("decks_mixed_due", { count: dueCount })
                : t("decks_mixed_practice")}
            </span>
          </span>
        </button>
      )}

      {isLoading ? (
        <div className="flex justify-center py-10 text-ink-muted">
          <Spinner />
        </div>
      ) : decks.length === 0 ? (
        <div className="rounded-xl border border-dashed border-border p-8 text-center">
          <Layers size={32} className="mx-auto mb-2 text-ink-muted" />
          <p className="font-semibold text-ink">{t("home_no_decks_title")}</p>
          <p className="mt-1 text-sm text-ink-muted">{t("home_no_decks_body")}</p>
          <Button
            variant="primary"
            className="mt-4"
            onClick={() => router.push("/scan")}
          >
            {t("scan_source_title")}
          </Button>
        </div>
      ) : (
        <div className="flex flex-col gap-2.5">
          {decks.map((deck) => (
            <DeckCard key={deck.id} deck={deck} />
          ))}
          {canLoadMore && (
            <button
              onClick={() => setLimit((l) => l + DECKS_PAGE_SIZE)}
              className="mt-2 flex h-11 items-center justify-center rounded-md border border-border text-sm font-medium text-ink-muted"
            >
              {isFetching ? <Spinner className="h-4 w-4" /> : t("home_see_all")}
            </button>
          )}
        </div>
      )}
    </TabScaffold>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg border border-border bg-surface p-3 text-center">
      <div className="text-xl font-bold text-ink">{value}</div>
      <div className="text-xs text-ink-muted">{label}</div>
    </div>
  );
}
