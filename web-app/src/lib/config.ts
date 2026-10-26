// Centralised access to public env/config. Mirrors lib/app/core/config/env.dart.
// Only NEXT_PUBLIC_* values are client-safe; server-only secrets are read in
// route handlers / edge functions, never here.

function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `Missing required env var "${name}". Copy .env.local.example to .env.local.`,
    );
  }
  return value;
}

export const config = {
  supabaseUrl: required(
    "NEXT_PUBLIC_SUPABASE_URL",
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ),
  supabaseKey: required(
    "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY",
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
  ),
  turnstileSiteKey: process.env.NEXT_PUBLIC_TURNSTILE_SITE_KEY ?? "",
  vapidPublicKey: process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY ?? "",
  supportEmail: process.env.NEXT_PUBLIC_SUPPORT_EMAIL ?? "support@lexisnap.app",
  emailjs: {
    serviceId: process.env.NEXT_PUBLIC_EMAILJS_SERVICE_ID ?? "",
    publicKey: process.env.NEXT_PUBLIC_EMAILJS_PUBLIC_KEY ?? "",
    templateSupport: process.env.NEXT_PUBLIC_EMAILJS_TEMPLATE_SUPPORT ?? "",
    templateReceipt: process.env.NEXT_PUBLIC_EMAILJS_TEMPLATE_RECEIPT ?? "",
  },
};

export const captchaEnabled = config.turnstileSiteKey.trim().length > 0;
export const pushConfigured = config.vapidPublicKey.trim().length > 0;
export const supportConfigured =
  config.emailjs.serviceId.length > 0 &&
  config.emailjs.publicKey.length > 0 &&
  config.emailjs.templateSupport.length > 0;
