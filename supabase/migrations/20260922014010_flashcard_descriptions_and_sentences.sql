-- word_description: a short definition of the word.
-- notes: reserved for future AI-written context - not populated yet.
-- audio_url: reserved for future recorded audio - pronunciation currently
-- uses on-device text-to-speech instead, so this stays unused for now.
alter table flashcards
  add column word_description text,
  add column notes text,
  add column audio_url text;

-- Reserved for future AI-written or user-written deck-level notes - not
-- populated or shown anywhere yet, same as flashcards.notes.
alter table decks add column notes text;

-- Example sentences move to their own table so a flashcard can carry any
-- number of them over time instead of exactly one.
alter table flashcards drop column example_sentence;

create table example_sentences (
  id uuid primary key default gen_random_uuid(),
  flashcard_id uuid not null references flashcards(id) on delete cascade,
  sentence text not null,
  created_at timestamptz not null default now()
);

alter table example_sentences enable row level security;

create policy "Users manage their own example sentences" on example_sentences
  for all using (
    exists (
      select 1 from flashcards join decks on decks.id = flashcards.deck_id
      where flashcards.id = example_sentences.flashcard_id and decks.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from flashcards join decks on decks.id = flashcards.deck_id
      where flashcards.id = example_sentences.flashcard_id and decks.user_id = auth.uid()
    )
  );
