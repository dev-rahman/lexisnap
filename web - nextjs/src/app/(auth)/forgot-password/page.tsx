"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState } from "react";

import { Captcha } from "@/components/auth/Captcha";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import * as auth from "@/lib/auth/authService";
import { captchaEnabled } from "@/lib/config";
import { toast } from "@/lib/toast";

type Step = "email" | "code" | "newPassword";
const RESEND_COOLDOWN = 60;

export default function ForgotPasswordPage() {
  const t = useT();
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const timer = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => () => void (timer.current && clearInterval(timer.current)), []);

  function startCooldown() {
    setCooldown(RESEND_COOLDOWN);
    timer.current && clearInterval(timer.current);
    timer.current = setInterval(() => {
      setCooldown((c) => {
        if (c <= 1 && timer.current) clearInterval(timer.current);
        return c - 1;
      });
    }, 1000);
  }

  async function sendCode() {
    if (!/^\S+@\S+\.\S+$/.test(email)) return;
    if (captchaEnabled && !token) {
      toast.error(t("captcha_error"));
      return;
    }
    setLoading(true);
    try {
      await auth.sendPasswordResetEmail(email, token ?? undefined);
      setStep("code");
      startCooldown();
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  async function verify() {
    setLoading(true);
    try {
      await auth.verifyPasswordResetCode(email, code);
      setStep("newPassword");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  async function save() {
    if (password.length < 8) return;
    setLoading(true);
    try {
      await auth.updatePassword(password);
      toast.success(t("forgot_password_updated"));
      router.replace("/home");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-1 flex-col">
      {step === "email" && (
        <>
          <h1 className="text-2xl font-bold text-ink">{t("forgot_password_title")}</h1>
          <p className="mb-6 mt-1 text-ink-muted">{t("forgot_password_subtitle")}</p>
          <div className="flex flex-col gap-4">
            <TextField
              name="email"
              type="email"
              label={t("common_email")}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
            {captchaEnabled && <Captcha onToken={setToken} />}
            <Button variant="primary" fullWidth loading={loading} onClick={sendCode}>
              {t("forgot_password_button")}
            </Button>
          </div>
        </>
      )}

      {step === "code" && (
        <>
          <h1 className="text-2xl font-bold text-ink">
            {t("forgot_password_check_email_title")}
          </h1>
          <p className="mb-6 mt-1 text-ink-muted">
            {t("forgot_password_check_email_body", { email })}
          </p>
          <div className="flex flex-col gap-4">
            <TextField
              name="code"
              inputMode="numeric"
              label={t("forgot_password_verify_button")}
              value={code}
              onChange={(e) => setCode(e.target.value)}
            />
            <Button variant="primary" fullWidth loading={loading} onClick={verify}>
              {t("forgot_password_verify_button")}
            </Button>
            <button
              disabled={cooldown > 0}
              onClick={sendCode}
              className="text-sm font-medium text-accent disabled:text-ink-muted"
            >
              {cooldown > 0
                ? t("forgot_password_resend_in", { seconds: cooldown })
                : t("forgot_password_resend")}
            </button>
          </div>
        </>
      )}

      {step === "newPassword" && (
        <>
          <h1 className="text-2xl font-bold text-ink">
            {t("forgot_password_new_title")}
          </h1>
          <p className="mb-6 mt-1 text-ink-muted">
            {t("forgot_password_new_subtitle")}
          </p>
          <div className="flex flex-col gap-4">
            <TextField
              name="newPassword"
              type="password"
              label={t("forgot_password_new_password")}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
            <Button variant="primary" fullWidth loading={loading} onClick={save}>
              {t("forgot_password_save_button")}
            </Button>
          </div>
        </>
      )}

      <p className="mt-8 text-center text-sm text-ink-muted">
        <Link href="/login" className="font-semibold text-accent">
          {t("login_button")}
        </Link>
      </p>
    </div>
  );
}
