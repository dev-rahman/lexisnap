-- Per-user storage quotas, so no single account - a careless user or a
-- scripted bot that signed up - can pile up unbounded rows. Row-level
-- security already confines every row to its owner; these caps bound how
-- much that one owner can store.
--
-- The limits are deliberately generous (a real learner stays far under
-- them) and easy to change: edit the numbers below and add a new migration.
--   - 200 decks per user
--   - 1000 cards per deck
--   - 20000 cards per user in total
--
-- The checks run on every insert, so these indexes keep the COUNTs cheap.
-- (The deck_id one may already exist from the unique-word index; the name
-- differs, so `if not exists` just skips it when the column is covered.)
create index if not exists idx_decks_user_id on decks (user_id);
create index if not exists idx_flashcards_deck_id on flashcards (deck_id);

-- SECURITY DEFINER so the COUNT sees the user's true totals regardless of the
-- caller's row-level security view; search_path is pinned for safety. The
-- filter is always an explicit user_id, so it never counts anyone else.
create or replace function enforce_deck_limit()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  deck_count int;
begin
  select count(*) into deck_count from decks where user_id = new.user_id;
  if deck_count >= 200 then
    raise exception 'Deck limit reached (200 per user)'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

create trigger deck_limit
  before insert on decks
  for each row execute function enforce_deck_limit();

create or replace function enforce_flashcard_limits()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  deck_owner uuid;
  cards_in_deck int;
  total_cards int;
begin
  select user_id into deck_owner from decks where id = new.deck_id;

  select count(*) into cards_in_deck
    from flashcards where deck_id = new.deck_id;
  if cards_in_deck >= 1000 then
    raise exception 'Card limit reached for this deck (1000)'
      using errcode = 'check_violation';
  end if;

  select count(*) into total_cards
    from flashcards f
    join decks d on d.id = f.deck_id
    where d.user_id = deck_owner;
  if total_cards >= 20000 then
    raise exception 'Total card limit reached (20000 per user)'
      using errcode = 'check_violation';
  end if;

  return new;
end;
$$;

create trigger flashcard_limits
  before insert on flashcards
  for each row execute function enforce_flashcard_limits();
