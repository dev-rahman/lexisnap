-- Decks and flashcards created from the scan flow. Every row is owned by
-- exactly one user (auth.uid()) and RLS enforces that end to end - nothing
-- here is ever shared between users.

create table decks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  source_language text,          -- ISO code, e.g. 'fr' - null if detection failed/local fallback
  target_language text not null,
  created_at timestamptz not null default now()
);

create table flashcards (
  id uuid primary key default gen_random_uuid(),
  deck_id uuid not null references decks(id) on delete cascade,
  word text not null,
  level text,                    -- CEFR code, nullable (local-fallback words have none)
  example_sentence text,
  translation text not null,
  created_at timestamptz not null default now()
);

alter table decks enable row level security;
alter table flashcards enable row level security;

create policy "Users manage their own decks" on decks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users manage their own flashcards" on flashcards
  for all using (exists (select 1 from decks where decks.id = flashcards.deck_id and decks.user_id = auth.uid()))
  with check (exists (select 1 from decks where decks.id = flashcards.deck_id and decks.user_id = auth.uid()));
