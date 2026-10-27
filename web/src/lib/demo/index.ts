// Demo mode: renders the full authed app with local fixture data and a fake
// user — no Supabase round-trips. Enabled by VITE_DEMO=1 at build time, or at
// runtime via ?demo=1 (persisted to localStorage) / ?demo=0 to clear. Used for
// Playwright screenshot verification and as an offline preview.

const KEY = "lexisnap_demo";

export function initDemoFromUrl(): void {
  try {
    const q = new URLSearchParams(window.location.search).get("demo");
    if (q === "1") localStorage.setItem(KEY, "1");
    else if (q === "0") localStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}

export function isDemo(): boolean {
  try {
    if (import.meta.env.VITE_DEMO === "1") return true;
    if (new URLSearchParams(window.location.search).get("demo") === "1") return true;
    return localStorage.getItem(KEY) === "1";
  } catch {
    return false;
  }
}
