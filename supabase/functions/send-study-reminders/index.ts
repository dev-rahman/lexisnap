// Supabase Edge Function: send-study-reminders
//
// Delivers the daily Web Push study reminder — the web replacement for the
// Flutter app's local notifications. Meant to run on a schedule (every ~15
// min) via Supabase's scheduled triggers / pg_cron, e.g.:
//
//   select cron.schedule(
//     'study-reminders', '*/15 * * * *',
//     $$ select net.http_post(
//          url := 'https://<ref>.functions.supabase.co/send-study-reminders',
//          headers := jsonb_build_object('Authorization', 'Bearer ' || '<CRON_SECRET>')
//        ) $$);
//
// For each user whose reminder is enabled and whose local HH:MM has just
// passed (within the run window) AND who hasn't studied this study-day, it
// sends a push to every one of their stored subscriptions.
//
// Secrets:  supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=... VAPID_SUBJECT=mailto:you@example.com
// Deploy:   supabase functions deploy send-study-reminders --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";
import webpush from "npm:web-push@3.6.7";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const VAPID_PUBLIC_KEY = Deno.env.get("VAPID_PUBLIC_KEY")!;
const VAPID_PRIVATE_KEY = Deno.env.get("VAPID_PRIVATE_KEY")!;
const VAPID_SUBJECT = Deno.env.get("VAPID_SUBJECT") ?? "mailto:support@lexisnap.app";

const STUDY_DAY_ROLLOVER_HOUR = 4; // matches study_day.dart / studyDay.ts
const WINDOW_MINUTES = 20; // reminder fires if its time fell in the last window

webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

/** Local wall-clock parts for a timezone, via Intl. */
function localParts(tz: string, at: Date) {
  const fmt = new Intl.DateTimeFormat("en-US", {
    timeZone: tz,
    hour12: false,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
  const parts = Object.fromEntries(fmt.formatToParts(at).map((p) => [p.type, p.value]));
  return {
    year: Number(parts.year),
    month: Number(parts.month),
    day: Number(parts.day),
    hour: Number(parts.hour === "24" ? "0" : parts.hour),
    minute: Number(parts.minute),
  };
}

/** Minutes since midnight, local. */
function localMinutes(tz: string, at: Date): number {
  const p = localParts(tz, at);
  return p.hour * 60 + p.minute;
}

/** Whether `last` falls in the same study day (4am rollover) as `now` in tz. */
function studiedToday(tz: string, now: Date, last: Date | null): boolean {
  if (!last) return false;
  const studyDayKey = (d: Date) => {
    const p = localParts(tz, d);
    // Before 4am belongs to the previous calendar day's study day.
    let { year, month, day } = p;
    if (p.hour < STUDY_DAY_ROLLOVER_HOUR) {
      const prev = new Date(Date.UTC(year, month - 1, day - 1));
      year = prev.getUTCFullYear();
      month = prev.getUTCMonth() + 1;
      day = prev.getUTCDate();
    }
    return `${year}-${month}-${day}`;
  };
  return studyDayKey(now) === studyDayKey(last);
}

Deno.serve(async () => {
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: reminders, error } = await admin
    .from("user_reminders")
    .select("user_id, enabled, hour, minute, timezone, last_studied_at")
    .eq("enabled", true);
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  const now = new Date();
  let sent = 0;

  for (const r of reminders ?? []) {
    const tz = r.timezone || "UTC";
    const target = r.hour * 60 + r.minute;
    const nowMin = localMinutes(tz, now);
    const diff = nowMin - target;
    // Fire once when the target time just passed within the window.
    if (diff < 0 || diff >= WINDOW_MINUTES) continue;
    if (studiedToday(tz, now, r.last_studied_at ? new Date(r.last_studied_at) : null)) {
      continue;
    }

    const { data: subs } = await admin
      .from("push_subscriptions")
      .select("endpoint, keys")
      .eq("user_id", r.user_id);

    const payload = JSON.stringify({
      title: "Time to study",
      body: "A few cards are waiting. Two minutes is enough.",
      url: "/home",
    });

    for (const sub of subs ?? []) {
      try {
        await webpush.sendNotification(
          { endpoint: sub.endpoint, keys: sub.keys },
          payload,
        );
        sent++;
      } catch (e) {
        // 404/410 → subscription gone; clean it up.
        const status = (e as { statusCode?: number }).statusCode;
        if (status === 404 || status === 410) {
          await admin.from("push_subscriptions").delete().eq("endpoint", sub.endpoint);
        }
      }
    }
  }

  return new Response(JSON.stringify({ sent }), {
    headers: { "Content-Type": "application/json" },
  });
});
