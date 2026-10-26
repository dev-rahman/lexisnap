"use client";

import { useRouter } from "next/navigation";

import { Card } from "@/components/ui/Card";
import type { Deck } from "@/lib/data/models";
import { languageByCode } from "@/lib/data/languages";
import { hueFor } from "@/lib/domain/deckHue";
import { HUE_BG } from "@/lib/utils/hueClasses";

export function DeckCard({ deck }: { deck: Deck }) {
  const router = useRouter();
  const hue = hueFor(deck.id);
  const source = languageByCode(deck.sourceLanguage);
  const target = languageByCode(deck.targetLanguage);

  return (
    <Card
      interactive
      onClick={() => router.push(`/deck/${deck.id}`)}
      className="flex flex-col gap-3 p-4"
    >
      <div className="flex items-center justify-between">
        <span
          className={`flex h-11 w-11 items-center justify-center rounded-2xl text-lg font-bold text-white ${HUE_BG[hue]}`}
        >
          {deck.name.slice(0, 1).toUpperCase()}
        </span>
        <span className="flex items-center gap-1 text-sm">
          {source && <span>{source.flag}</span>}
          <span className="text-ink-muted">→</span>
          {target && <span>{target.flag}</span>}
        </span>
      </div>
      <div className="min-w-0">
        <div className="truncate font-semibold text-ink">{deck.name}</div>
        <div className="mt-0.5 text-sm text-ink-muted">
          {deck.cardCount} {deck.cardCount === 1 ? "card" : "cards"}
        </div>
      </div>
    </Card>
  );
}
