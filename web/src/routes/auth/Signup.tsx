import { useState, type FormEvent } from "react";
import { Link } from "react-router-dom";
import { Mail, Lock, User, MailCheck } from "lucide-react";

import { AuthScaffold } from "@/components/auth/AuthScaffold";
import { Captcha } from "@/components/auth/Captcha";
import { GoogleButton } from "@/components/auth/GoogleButton";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { captchaEnabled } from "@/lib/config";
import { signUpWithEmail } from "@/lib/auth/authService";
import { useT } from "@/providers/I18nProvider";

export function Signup() {
  const t = useT();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [captchaToken, setCaptchaToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [checkInbox, setCheckInbox] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!name.trim()) return setError(t("signup_name_required"));
    if (password !== confirm) return setError(t("common_something_went_wrong"));
    setLoading(true);
    try {
      const { hasSession } = await signUpWithEmail(
        email,
        password,
        name.trim(),
        captchaToken ?? undefined,
      );
      if (!hasSession) setCheckInbox(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  if (checkInbox) {
    return (
      <AuthScaffold title={t("signup_check_inbox_title")}>
        <div className="flex flex-col items-center text-center">
          <div className="grid h-20 w-20 place-items-center rounded-3xl bg-success/15 text-success">
            <MailCheck size={40} />
          </div>
          <p className="mt-5 text-ink-muted">{t("signup_check_inbox_body")}</p>
          <Link to="/login" className="mt-7 w-full">
            <Button fullWidth variant="secondary">
              {t("login_button")}
            </Button>
          </Link>
        </div>
      </AuthScaffold>
    );
  }

  return (
    <AuthScaffold title={t("signup_title")} subtitle={t("signup_subtitle")}>
      <form onSubmit={onSubmit} className="space-y-4">
        <TextField
          label={t("common_full_name")}
          leftIcon={<User size={18} />}
          autoComplete="name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
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
          autoComplete="new-password"
          leftIcon={<Lock size={18} />}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <TextField
          label={t("signup_confirm_password")}
          type="password"
          autoComplete="new-password"
          leftIcon={<Lock size={18} />}
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          error={error}
          required
        />
        {captchaEnabled && <Captcha onToken={setCaptchaToken} />}
        <Button type="submit" fullWidth size="lg" loading={loading}>
          {t("signup_button")}
        </Button>
      </form>

      <div className="my-6 flex items-center gap-4">
        <span className="h-px flex-1 bg-border" />
        <span className="text-sm font-medium text-ink-muted">{t("common_or")}</span>
        <span className="h-px flex-1 bg-border" />
      </div>
      <GoogleButton label={t("login_continue_google")} />

      <p className="mt-8 text-center text-[15px] text-ink-muted">
        <Link to="/login" className="font-bold text-coral hover:underline">
          {t("login_button")}
        </Link>
      </p>
    </AuthScaffold>
  );
}
