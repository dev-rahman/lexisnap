-- SM-2 spaced-repetition scheduling state per flashcard.
-- due_at defaults to now() so newly scanned cards are immediately due for
-- their first review. No new RLS policy is needed - the existing
-- "Users manage their own flashcards" policy already covers update.
alter table flashcards
  add column ease_factor double precision not null default 2.5,
  add column interval_days integer not null default 0,
  add column repetitions integer not null default 0,
  add column due_at timestamptz not null default now(),
  add column last_reviewed_at timestamptz;

create index idx_flashcards_due_at on flashcards(due_at);
