-- Per-user daily caps on the billable/rate-limited AI actions (the Groq calls
-- behind extract-vocabulary "scan" and translate-words "translate"). The
-- authenticated-user check in those functions keeps *anonymous* traffic out;
-- this bounds how hard a single signed-in account - a heavy user, or a bot
-- that signed up - can drive those calls.
--
-- The caps themselves live in the Edge Functions (a tier -> limit map), not
-- here, so they're trivial to tune and can become tier-aware once billing
-- exists. This migration only provides the counter and the atomic
-- consume/refund primitives the functions call.

-- One row per user, per UTC day, per action, holding that day's running count.
create table ai_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default (now() at time zone 'utc')::date,
  action text not null,
  count int not null default 0,
  primary key (user_id, usage_date, action)
);

alter table ai_usage enable row level security;

-- Users may read their own usage (e.g. to show "3 / 5 scans left today").
-- All writes go exclusively through the SECURITY DEFINER functions below, so
-- there is deliberately no insert/update/delete policy.
create policy "Users read their own ai usage" on ai_usage
  for select using (auth.uid() = user_id);

-- Atomically charge one unit of quota for the caller's current UTC day.
-- Returns the remaining allowance after this call, or -1 when already at the
-- cap (in which case nothing is consumed). Race-safe: the conditional
-- ON CONFLICT update only increments while still under the limit, so parallel
-- requests can't burst past it.
create or replace function consume_ai_quota(p_action text, p_limit int)
  returns int
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (now() at time zone 'utc')::date;
  v_count int;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  insert into ai_usage (user_id, usage_date, action, count)
    values (v_uid, v_today, p_action, 1)
    on conflict (user_id, usage_date, action)
    do update set count = ai_usage.count + 1
      where ai_usage.count < p_limit
    returning count into v_count;

  if v_count is null then
    return -1;                -- already at the cap; nothing consumed
  end if;
  return p_limit - v_count;   -- remaining after this call
end;
$$;

-- Give one unit back - called by a function when the downstream AI call fails,
-- so an upstream outage doesn't burn the user's daily allowance.
create or replace function refund_ai_quota(p_action text)
  returns void
  language plpgsql
  security definer
  set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (now() at time zone 'utc')::date;
begin
  if v_uid is null then
    return;
  end if;
  update ai_usage set count = greatest(count - 1, 0)
    where user_id = v_uid and usage_date = v_today and action = p_action;
end;
$$;

grant execute on function consume_ai_quota(text, int) to authenticated;
grant execute on function refund_ai_quota(text) to authenticated;
