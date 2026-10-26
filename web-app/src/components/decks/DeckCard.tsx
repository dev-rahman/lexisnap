"use client";

import { useRouter } from "next/navigation";

import type { Deck } from "@/lib/data/models";
import { languageByCode } from "@/lib/data/languages";
import { hueFor } from "@/lib/domain/deckHue";
import { HUE_BG, HUE_TINT } from "@/lib/utils/hueClasses";

export function DeckCard({ deck }: { deck: Deck }) {
  const router = useRouter();
  const hue = hueFor(deck.id);
  const source = languageByCode(deck.sourceLanguage);
  const target = languageByCode(deck.targetLanguage);

  return (
    <button
      onClick={() => router.push(`/deck/${deck.id}`)}
      className={`flex w-full items-center gap-3 rounded-lg border border-border p-3.5 text-left transition active:scale-[0.99] ${HUE_TINT[hue]}`}
    >
      <span
        className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-md text-lg font-bold text-white ${HUE_BG[hue]}`}
      >
        {deck.name.slice(0, 1).toUpperCase()}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate font-semibold text-ink">{deck.name}</span>
        <span className="mt-0.5 flex items-center gap-1.5 text-sm text-ink-muted">
          {source && <span>{source.flag}</span>}
          <span>→</span>
          {target && <span>{target.flag}</span>}
          <span className="ml-1">
            {deck.cardCount} {deck.cardCount === 1 ? "card" : "cards"}
          </span>
        </span>
      </span>
    </button>
  );
}
