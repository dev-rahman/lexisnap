import { Turnstile } from "@marsidev/react-turnstile";

import { captchaEnabled, config } from "@/lib/config";

/** Cloudflare Turnstile, rendered only when a site key is configured. Calls
 *  onToken with the solved token (or null on expire/error). */
export function Captcha({ onToken }: { onToken: (token: string | null) => void }) {
  if (!captchaEnabled) return null;
  return (
    <div className="flex justify-center">
      <Turnstile
        siteKey={config.turnstileSiteKey}
        onSuccess={(t) => onToken(t)}
        onExpire={() => onToken(null)}
        onError={() => onToken(null)}
        options={{ theme: "auto", size: "flexible" }}
      />
    </div>
  );
}
