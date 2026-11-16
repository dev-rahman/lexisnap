"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Layers, Sparkles } from "lucide-react";

import { DeckCard } from "@/components/decks/DeckCard";
import { TabScaffold } from "@/components/shell/TabScaffold";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { IconTile } from "@/components/ui/IconTile";
import { Skeleton } from "@/components/ui/Skeleton";
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
      ? dueCount > 0 ? "/listen?mode=due" : "/listen?mode=practice"
      : dueCount > 0 ? "/study?mode=due" : "/study?mode=practice";

  return (
    <TabScaffold active="decks" title={t("decks_all")}>
      <h1 className="mb-5 text-[28px] font-bold text-ink md:hidden">{t("decks_all")}</h1>

      <div className="mb-5 grid grid-cols-3 gap-3">
        <Stat label={t("decks_stat_decks")} value={totals?.deckCount ?? 0} />
        <Stat label={t("decks_stat_words")} value={totals?.cardCount ?? 0} />
        <Stat label={t("decks_stat_due")} value={dueCount} accent={dueCount > 0} />
      </div>

      {hasCards && (
        <button
          onClick={() => router.push(mixedHref)}
          className="panel-surface mb-6 flex w-full items-center gap-4 rounded-3xl p-5 text-left transition hover:brightness-110 active:scale-[0.99]"
        >
          <IconTile size="lg" className="bg-accent/20 text-accent">
            <Sparkles size={22} />
          </IconTile>
          <span className="flex-1">
            <span className="block font-bold">{t("decks_mixed_title")}</span>
            <span className="text-sm text-white/65">
              {dueCount > 0 ? t("decks_mixed_due", { count: dueCount }) : t("decks_mixed_practice")}
            </span>
          </span>
        </button>
      )}

      {isLoading ? (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-28 rounded-2xl" />
          ))}
        </div>
      ) : decks.length === 0 ? (
        <EmptyState
          icon={<Layers size={24} />}
          title={t("home_no_decks_title")}
          body={t("home_no_decks_body")}
          action={
            <Button variant="primary" onClick={() => router.push("/scan")}>
              {t("scan_source_title")}
            </Button>
          }
        />
      ) : (
        <>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
            {decks.map((deck) => (
              <DeckCard key={deck.id} deck={deck} />
            ))}
          </div>
          {canLoadMore && (
            <div className="mt-5 flex justify-center">
              <Button variant="secondary" size="md" loading={isFetching} onClick={() => setLimit((l) => l + DECKS_PAGE_SIZE)}>
                {t("home_see_all")}
              </Button>
            </div>
          )}
        </>
      )}
    </TabScaffold>
  );
}

function Stat({ label, value, accent }: { label: string; value: number; accent?: boolean }) {
  return (
    <Card className="p-4 text-center">
      <div className={`text-2xl font-bold ${accent ? "text-accent" : "text-ink"}`}>{value}</div>
      <div className="mt-0.5 text-xs text-ink-muted">{label}</div>
    </Card>
  );
}
