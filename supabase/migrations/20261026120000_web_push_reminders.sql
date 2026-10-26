-- Web Push study reminders (web app). The browser subscribes via the service
-- worker and stores its PushSubscription here; the user's reminder schedule
-- lives in user_reminders. The scheduled send-study-reminders edge function
-- reads both to deliver the daily nudge, reproducing the Flutter app's
-- "skip if already studied today" gate from last_studied_at.
--
-- Both tables are RLS-scoped to their owner, exactly like decks/flashcards.

create table push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  endpoint text not null unique,
  keys jsonb not null,          -- { p256dh, auth }
  created_at timestamptz not null default now()
);

create index idx_push_subscriptions_user_id on push_subscriptions (user_id);

alter table push_subscriptions enable row level security;

create policy "Users manage their own push subscriptions" on push_subscriptions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table user_reminders (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  enabled boolean not null default false,
  hour int not null default 19,
  minute int not null default 30,
  timezone text not null default 'UTC',
  -- The last moment the user finished a review, so the reminder can be
  -- skipped on a study day they've already studied in (see study_day logic).
  last_studied_at timestamptz,
  updated_at timestamptz not null default now()
);

alter table user_reminders enable row level security;

create policy "Users manage their own reminder settings" on user_reminders
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
