-- Block duplicate words within a single deck (case-insensitive). The same
-- word may still live in different decks - only in-deck duplicates are
-- disallowed. This backs up the app's move/copy/merge/scan flows, which now
-- skip a word a deck already has, and also stops duplicates from any direct
-- API or scripted insert.

-- Existing in-deck duplicates have to go before the unique index can be
-- created, or the index would fail. Keep the earliest card of each
-- (deck, lowercased word); the rows removed here take their example
-- sentences with them via the example_sentences -> flashcards cascade.
delete from flashcards f
using flashcards keep
where f.deck_id = keep.deck_id
  and lower(f.word) = lower(keep.word)
  and (
    keep.created_at < f.created_at
    or (keep.created_at = f.created_at and keep.id < f.id)
  );

create unique index flashcards_unique_word_per_deck
  on flashcards (deck_id, lower(word));
