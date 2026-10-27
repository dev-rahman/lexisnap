// Port of AppColors.hueFor / deckHues from lib/app/core/theme/app_colors.dart.
//
// A deck's colour is a stable function of its id via an FNV-1a fold — NOT a
// language-runtime string hash, so the same id always lands on the same hue
// across sessions and platforms (a deck that changes colour is worse than
// no colour at all).

export type DeckHue = "teal" | "amber" | "violet" | "moss" | "rose" | "sky";

/** The rotation decks are coloured from — ordered so neighbours differ. */
export const DECK_HUES: DeckHue[] = [
  "teal",
  "amber",
  "violet",
  "moss",
  "rose",
  "sky",
];

/** Tailwind token name for a hue, e.g. "hue-teal". */
export function hueToken(hue: DeckHue): string {
  return `hue-${hue}`;
}

/** A stable hue for a seed (normally a deck id). */
export function hueFor(seed: string): DeckHue {
  let hash = 0x811c9dc5;
  for (let i = 0; i < seed.length; i++) {
    hash = (hash ^ seed.charCodeAt(i)) >>> 0;
    // 32-bit FNV prime multiply, kept in uint32 range.
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return DECK_HUES[hash % DECK_HUES.length];
}
