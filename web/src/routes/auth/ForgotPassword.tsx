import { useEffect, useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Mail, Lock, KeyRound, ArrowLeft } from "lucide-react";

import { AuthScaffold } from "@/components/auth/AuthScaffold";
import { Captcha } from "@/components/auth/Captcha";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { captchaEnabled } from "@/lib/config";
import {
  sendPasswordResetEmail,
  updatePassword,
  verifyPasswordResetCode,
} from "@/lib/auth/authService";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";

type Step = "email" | "code" | "password";
const RESEND_SECONDS = 60;

export function ForgotPassword() {
  const t = useT();
  const navigate = useNavigate();
  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const [captchaToken, setCaptchaToken] = useState<string | null>(null);
  // Bumped after every send so the single-use Turnstile widget remounts and
  // issues a fresh token for the next send / resend.
  const [captchaKey, setCaptchaKey] = useState(0);

  useEffect(() => {
    if (cooldown <= 0) return;
    const id = setInterval(() => setCooldown((c) => c - 1), 1000);
    return () => clearInterval(id);
  }, [cooldown]);

  async function sendCode(e?: FormEvent) {
    e?.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await sendPasswordResetEmail(email, captchaToken ?? undefined);
      setStep("code");
      setCooldown(RESEND_SECONDS);
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
      // Each Turnstile token is single-use — drop it and remount for the next send.
      if (captchaEnabled) {
        setCaptchaToken(null);
        setCaptchaKey((k) => k + 1);
      }
    }
  }

  async function verifyCode(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await verifyPasswordResetCode(email, code);
      setStep("password");
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  async function savePassword(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await updatePassword(password);
      toast.success(t("forgot_password_updated"));
      navigate("/home", { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
      setLoading(false);
    }
  }

  async function resend() {
    if (cooldown > 0) return;
    await sendCode();
    toast.success(t("forgot_password_code_resent"));
  }

  return (
    <AuthScaffold
      title={
        step === "email"
          ? t("forgot_password_title")
          : step === "code"
            ? t("forgot_password_check_email_title")
            : t("forgot_password_new_title")
      }
      subtitle={
        step === "email"
          ? t("forgot_password_subtitle")
          : step === "code"
            ? t("forgot_password_check_email_body", { email })
            : t("forgot_password_new_subtitle")
      }
    >
      {step === "email" && (
        <form onSubmit={sendCode} className="space-y-4">
          <TextField
            label={t("common_email")}
            type="email"
            autoComplete="email"
            leftIcon={<Mail size={18} />}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={error}
            required
          />
          {captchaEnabled && <Captcha key={captchaKey} onToken={setCaptchaToken} />}
          <Button type="submit" fullWidth size="lg" loading={loading}>
            {t("forgot_password_button")}
          </Button>
        </form>
      )}

      {step === "code" && (
        <form onSubmit={verifyCode} className="space-y-4">
          <TextField
            label={t("forgot_password_verify_button")}
            inputMode="numeric"
            leftIcon={<KeyRound size={18} />}
            value={code}
            onChange={(e) => setCode(e.target.value)}
            error={error}
            className="tracking-[0.3em]"
            required
          />
          <Button type="submit" fullWidth size="lg" loading={loading}>
            {t("forgot_password_verify_button")}
          </Button>
          {captchaEnabled && cooldown <= 0 && (
            <Captcha key={captchaKey} onToken={setCaptchaToken} />
          )}
          <button
            type="button"
            onClick={resend}
            disabled={cooldown > 0}
            className="w-full text-center text-sm font-semibold text-coral disabled:text-ink-muted"
          >
            {cooldown > 0
              ? t("forgot_password_resend_in", { seconds: cooldown })
              : t("forgot_password_resend")}
          </button>
        </form>
      )}

      {step === "password" && (
        <form onSubmit={savePassword} className="space-y-4">
          <TextField
            label={t("forgot_password_new_password")}
            type="password"
            autoComplete="new-password"
            leftIcon={<Lock size={18} />}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={error}
            required
          />
          <Button type="submit" fullWidth size="lg" loading={loading}>
            {t("forgot_password_save_button")}
          </Button>
        </form>
      )}

      <Link
        to="/login"
        className="mt-8 flex items-center justify-center gap-1.5 text-sm font-semibold text-ink-muted hover:text-ink"
      >
        <ArrowLeft size={16} /> {t("login_button")}
      </Link>
    </AuthScaffold>
  );
}
