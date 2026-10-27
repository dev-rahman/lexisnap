// Centralised access to public env/config. In a Vite SPA only `VITE_*` vars
// are exposed to the client bundle (via import.meta.env); every real secret
// (Groq key, VAPID private key, service role) lives in Supabase edge functions.

function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `Missing required env var "${name}". Copy .env.local.example to .env.local.`,
    );
  }
  return value;
}

const env = import.meta.env;

export const config = {
  supabaseUrl: required("VITE_SUPABASE_URL", env.VITE_SUPABASE_URL),
  supabaseKey: required(
    "VITE_SUPABASE_PUBLISHABLE_KEY",
    env.VITE_SUPABASE_PUBLISHABLE_KEY,
  ),
  turnstileSiteKey: env.VITE_TURNSTILE_SITE_KEY ?? "",
  vapidPublicKey: env.VITE_VAPID_PUBLIC_KEY ?? "",
  supportEmail: env.VITE_SUPPORT_EMAIL ?? "support@lexisnap.app",
  emailjs: {
    serviceId: env.VITE_EMAILJS_SERVICE_ID ?? "",
    publicKey: env.VITE_EMAILJS_PUBLIC_KEY ?? "",
    templateSupport: env.VITE_EMAILJS_TEMPLATE_SUPPORT ?? "",
  },
};

export const captchaEnabled = config.turnstileSiteKey.trim().length > 0;
export const pushConfigured = config.vapidPublicKey.trim().length > 0;
export const supportConfigured =
  config.emailjs.serviceId.length > 0 &&
  config.emailjs.publicKey.length > 0 &&
  config.emailjs.templateSupport.length > 0;
