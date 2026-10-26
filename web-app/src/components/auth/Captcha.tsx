"use client";

import { Turnstile } from "@marsidev/react-turnstile";

import { captchaEnabled, config } from "@/lib/config";

/**
 * Cloudflare Turnstile — rendered inline only when a site key is configured
 * (matches the Flutter app, which skips the captcha when TURNSTILE_SITE_KEY
 * is empty). Replaces the webview-hosted widget with the native React one.
 */
export function Captcha({
  onToken,
}: {
  onToken: (token: string | null) => void;
}) {
  if (!captchaEnabled) return null;
  return (
    <div className="flex justify-center">
      <Turnstile
        siteKey={config.turnstileSiteKey}
        onSuccess={(t) => onToken(t)}
        onExpire={() => onToken(null)}
        onError={() => onToken(null)}
        options={{ theme: "auto" }}
      />
    </div>
  );
}
