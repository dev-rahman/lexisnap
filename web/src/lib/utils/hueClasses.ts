// Tailwind class maps for the deck hue palette. Literal strings so Tailwind's
// content scanner keeps them. Pair with hueFor(deckId) from domain/deckHue.

import type { DeckHue } from "@/lib/domain/deckHue";

export const HUE_BG: Record<DeckHue, string> = {
  teal: "bg-hue-teal",
  violet: "bg-hue-violet",
  amber: "bg-hue-amber",
  rose: "bg-hue-rose",
  sky: "bg-hue-sky",
  moss: "bg-hue-moss",
};

export const HUE_TEXT: Record<DeckHue, string> = {
  teal: "text-hue-teal",
  violet: "text-hue-violet",
  amber: "text-hue-amber",
  rose: "text-hue-rose",
  sky: "text-hue-sky",
  moss: "text-hue-moss",
};

/** A soft background tint of the hue (identity without shouting). */
export const HUE_TINT: Record<DeckHue, string> = {
  teal: "bg-hue-teal/15",
  violet: "bg-hue-violet/15",
  amber: "bg-hue-amber/15",
  rose: "bg-hue-rose/15",
  sky: "bg-hue-sky/15",
  moss: "bg-hue-moss/15",
};
