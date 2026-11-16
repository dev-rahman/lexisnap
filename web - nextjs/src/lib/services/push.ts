// Web Push study reminders — the web replacement for flutter_local_notifications.
// The browser subscribes via the service worker + VAPID; the subscription and
// the user's reminder time/timezone are stored in Supabase so the scheduled
// `send-study-reminders` edge function can deliver the daily nudge. The
// "already studied today?" gate is reproduced server-side from last_studied_at.

import { config, pushConfigured } from "@/lib/config";
import { getSupabaseBrowserClient } from "@/lib/supabase/client";

export function pushSupported(): boolean {
  return (
    typeof window !== "undefined" &&
    "serviceWorker" in navigator &&
    "PushManager" in window &&
    "Notification" in window &&
    pushConfigured
  );
}

function urlBase64ToUint8Array(base64: string): Uint8Array {
  const padding = "=".repeat((4 - (base64.length % 4)) % 4);
  const b64 = (base64 + padding).replace(/-/g, "+").replace(/_/g, "/");
  const raw = atob(b64);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}

async function registration(): Promise<ServiceWorkerRegistration> {
  return navigator.serviceWorker.register("/sw.js");
}

/** Asks permission, subscribes, and stores the subscription. */
export async function subscribeToPush(): Promise<boolean> {
  if (!pushSupported()) return false;
  const permission = await Notification.requestPermission();
  if (permission !== "granted") return false;

  const reg = await registration();
  const sub = await reg.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(config.vapidPublicKey),
  });

  const supabase = getSupabaseBrowserClient();
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) return false;

  const json = sub.toJSON();
  const { error } = await supabase.from("push_subscriptions").upsert(
    {
      user_id: userId,
      endpoint: json.endpoint,
      keys: json.keys,
    },
    { onConflict: "endpoint" },
  );
  return !error;
}

export async function unsubscribeFromPush(): Promise<void> {
  if (!("serviceWorker" in navigator)) return;
  const reg = await navigator.serviceWorker.getRegistration();
  const sub = await reg?.pushManager.getSubscription();
  if (sub) {
    const endpoint = sub.endpoint;
    await sub.unsubscribe();
    await getSupabaseBrowserClient()
      .from("push_subscriptions")
      .delete()
      .eq("endpoint", endpoint);
  }
}

/** Persists the reminder schedule so the scheduled function knows when/whether to fire. */
export async function saveReminderSettings(args: {
  enabled: boolean;
  hour: number;
  minute: number;
}): Promise<void> {
  const supabase = getSupabaseBrowserClient();
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) return;

  await supabase.from("user_reminders").upsert(
    {
      user_id: userId,
      enabled: args.enabled,
      hour: args.hour,
      minute: args.minute,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    },
    { onConflict: "user_id" },
  );
}

/** Records that the user studied today, so the reminder is skipped. */
export async function markStudiedForReminder(): Promise<void> {
  const supabase = getSupabaseBrowserClient();
  const { data: userData } = await supabase.auth.getUser();
  const userId = userData.user?.id;
  if (!userId) return;
  await supabase
    .from("user_reminders")
    .update({ last_studied_at: new Date().toISOString() })
    .eq("user_id", userId);
}
