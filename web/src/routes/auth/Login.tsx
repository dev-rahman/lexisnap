import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { Mail, Lock } from "lucide-react";

import { AuthScaffold } from "@/components/auth/AuthScaffold";
import { Captcha } from "@/components/auth/Captcha";
import { GoogleButton } from "@/components/auth/GoogleButton";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { captchaEnabled } from "@/lib/config";
import { signInWithEmail } from "@/lib/auth/authService";
import { useT } from "@/providers/I18nProvider";

export function Login() {
  const t = useT();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [captchaToken, setCaptchaToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await signInWithEmail(email, password, captchaToken ?? undefined);
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
      setLoading(false);
    }
  }

  return (
    <AuthScaffold title={t("login_welcome_back")} subtitle={t("login_subtitle")}>
      <form onSubmit={onSubmit} className="space-y-4">
        <TextField
          label={t("common_email")}
          type="email"
          autoComplete="email"
          leftIcon={<Mail size={18} />}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
        <TextField
          label={t("common_password")}
          type="password"
          autoComplete="current-password"
          leftIcon={<Lock size={18} />}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={error}
          required
        />
        <div className="flex justify-end">
          <Link
            to="/forgot-password"
            className="text-sm font-semibold text-coral hover:underline"
          >
            {t("login_forgot_password")}
          </Link>
        </div>
        {captchaEnabled && <Captcha onToken={setCaptchaToken} />}
        <Button type="submit" fullWidth size="lg" loading={loading}>
          {t("login_button")}
        </Button>
      </form>

      <div className="my-6 flex items-center gap-4">
        <span className="h-px flex-1 bg-border" />
        <span className="text-sm font-medium text-ink-muted">{t("common_or")}</span>
        <span className="h-px flex-1 bg-border" />
      </div>

      <GoogleButton label={t("login_continue_google")} />

      <p className="mt-8 text-center text-[15px] text-ink-muted">
        {t("login_no_account")}{" "}
        <Link to="/signup" className="font-bold text-coral hover:underline">
          {t("login_sign_up")}
        </Link>
      </p>
    </AuthScaffold>
  );
}
