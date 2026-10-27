// Fixture decks/cards for demo mode. Shaped exactly like the domain models so
// the real UI renders against them unchanged.

import type { AppUser, Deck, Flashcard } from "./models";

export const demoUser: AppUser = {
  id: "demo-user",
  email: "sam@lexisnap.app",
  fullName: "Sam Rivera",
  avatarUrl: null,
  hasOwnPhoto: false,
  hasPassword: true,
  emailConfirmed: true,
};

const now = Date.now();
const day = 86_400_000;
const iso = (ms: number) => new Date(ms).toISOString();

function card(
  id: string,
  word: string,
  translation: string,
  src: string,
  tgt: string,
  opts: Partial<Flashcard> = {},
): Flashcard {
  return {
    id,
    word,
    level: opts.level ?? "A2",
    wordDescription: opts.wordDescription ?? null,
    translation,
    exampleSentences: opts.exampleSentences ?? [],
    notes: null,
    audioUrl: null,
    sourceLanguage: src,
    targetLanguage: tgt,
    easeFactor: 2.5,
    intervalDays: opts.intervalDays ?? 0,
    repetitions: opts.repetitions ?? 0,
    dueAt: opts.dueAt ?? iso(now - day), // due by default
    lastReviewedAt: opts.lastReviewedAt ?? null,
  };
}

interface DemoDeck extends Deck {
  cards: Flashcard[];
}

export const demoDecks: DemoDeck[] = [
  {
    id: "deck-es",
    name: "Café & Markets",
    sourceLanguage: "es",
    targetLanguage: "en",
    createdAt: iso(now - 4 * day),
    notes: null,
    cardCount: 8,
    cards: [
      card("es1", "mercado", "market", "es", "en", {
        level: "A1",
        wordDescription: "A place where goods are bought and sold.",
        exampleSentences: ["Vamos al mercado los sábados."],
      }),
      card("es2", "panadería", "bakery", "es", "en", { level: "A2" }),
      card("es3", "sabroso", "tasty", "es", "en", { level: "B1" }),
      card("es4", "cuenta", "bill", "es", "en", { level: "A2" }),
      card("es5", "propina", "tip", "es", "en", { level: "B1" }),
      card("es6", "fresco", "fresh", "es", "en", { level: "A1", dueAt: iso(now + 3 * day), repetitions: 2, intervalDays: 6 }),
      card("es7", "barato", "cheap", "es", "en", { level: "A2", dueAt: iso(now + day) }),
      card("es8", "degustar", "to taste", "es", "en", { level: "B2" }),
    ],
  },
  {
    id: "deck-fr",
    name: "Voyage à Paris",
    sourceLanguage: "fr",
    targetLanguage: "en",
    createdAt: iso(now - 9 * day),
    notes: null,
    cardCount: 6,
    cards: [
      card("fr1", "gare", "station", "fr", "en", { level: "A1" }),
      card("fr2", "billet", "ticket", "fr", "en", { level: "A1" }),
      card("fr3", "quartier", "neighborhood", "fr", "en", { level: "A2" }),
      card("fr4", "flâner", "to stroll", "fr", "en", { level: "B2", wordDescription: "To wander with no particular goal." }),
      card("fr5", "ravissant", "delightful", "fr", "en", { level: "B1", dueAt: iso(now + 2 * day) }),
      card("fr6", "coucher du soleil", "sunset", "fr", "en", { level: "A2" }),
    ],
  },
  {
    id: "deck-de",
    name: "Alltag Deutsch",
    sourceLanguage: "de",
    targetLanguage: "en",
    createdAt: iso(now - 15 * day),
    notes: null,
    cardCount: 5,
    cards: [
      card("de1", "Feierabend", "end of the workday", "de", "en", { level: "B1" }),
      card("de2", "gemütlich", "cozy", "de", "en", { level: "B1" }),
      card("de3", "Vorfreude", "anticipation", "de", "en", { level: "B2" }),
      card("de4", "Termin", "appointment", "de", "en", { level: "A2", dueAt: iso(now + 5 * day) }),
      card("de5", "üben", "to practice", "de", "en", { level: "A1", dueAt: iso(now + day) }),
    ],
  },
  {
    id: "deck-ja",
    name: "はじめての日本語",
    sourceLanguage: "ja",
    targetLanguage: "en",
    createdAt: iso(now - 2 * day),
    notes: null,
    cardCount: 4,
    cards: [
      card("ja1", "ありがとう", "thank you", "ja", "en", { level: "A1" }),
      card("ja2", "美味しい", "delicious", "ja", "en", { level: "A2" }),
      card("ja3", "電車", "train", "ja", "en", { level: "A1" }),
      card("ja4", "頑張る", "to do one's best", "ja", "en", { level: "B1", dueAt: iso(now + 4 * day) }),
    ],
  },
];

export function demoDeckById(id: string): DemoDeck | undefined {
  return demoDecks.find((d) => d.id === id);
}

export function demoAllCards(): Flashcard[] {
  return demoDecks.flatMap((d) => d.cards);
}
