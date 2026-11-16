"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { Captcha } from "@/components/auth/Captcha";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import * as auth from "@/lib/auth/authService";
import { captchaEnabled } from "@/lib/config";
import { toast } from "@/lib/toast";

export default function LoginPage() {
  const t = useT();
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [token, setToken] = useState<string | null>(null);
  const [emailLoading, setEmailLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim() || !password) return;
    if (captchaEnabled && !token) {
      toast.error(t("captcha_error"));
      return;
    }
    setEmailLoading(true);
    try {
      await auth.signInWithEmail(email, password, token ?? undefined);
      router.replace("/home");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setEmailLoading(false);
    }
  }

  async function google() {
    setGoogleLoading(true);
    try {
      await auth.signInWithGoogle(); // redirects away
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
      setGoogleLoading(false);
    }
  }

  return (
    <div className="flex flex-1 flex-col">
      <h1 className="text-2xl font-bold text-ink">{t("login_welcome_back")}</h1>
      <p className="mb-6 mt-1 text-ink-muted">{t("login_subtitle")}</p>

      <form onSubmit={submit} className="flex flex-col gap-4">
        <TextField
          name="email"
          type="email"
          autoComplete="email"
          label={t("common_email")}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <TextField
          name="password"
          type="password"
          autoComplete="current-password"
          label={t("common_password")}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        <div className="-mt-1 text-right">
          <Link href="/forgot-password" className="text-sm font-medium text-accent">
            {t("login_forgot_password")}
          </Link>
        </div>
        {captchaEnabled && <Captcha onToken={setToken} />}
        <Button type="submit" variant="primary" fullWidth loading={emailLoading}>
          {t("login_button")}
        </Button>
      </form>

      <div className="my-5 flex items-center gap-3 text-xs uppercase text-ink-muted">
        <span className="h-px flex-1 bg-border" />
        {t("common_or")}
        <span className="h-px flex-1 bg-border" />
      </div>

      <Button variant="secondary" fullWidth loading={googleLoading} onClick={google}>
        {t("login_continue_google")}
      </Button>

      <p className="mt-8 text-center text-sm text-ink-muted">
        {t("login_no_account")}{" "}
        <Link href="/signup" className="font-semibold text-accent">
          {t("login_sign_up")}
        </Link>
      </p>
    </div>
  );
}
