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

export default function SignupPage() {
  const t = useT();
  const router = useRouter();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  function validate(): boolean {
    const e: Record<string, string> = {};
    if (!fullName.trim()) e.fullName = t("signup_name_required");
    if (!/^\S+@\S+\.\S+$/.test(email)) e.email = t("common_something_went_wrong");
    if (password.length < 8) e.password = t("forgot_password_new_subtitle");
    if (confirm !== password) e.confirm = t("signup_confirm_password");
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  async function submit(ev: React.FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    if (captchaEnabled && !token) {
      toast.error(t("captcha_error"));
      return;
    }
    setLoading(true);
    try {
      const { hasSession } = await auth.signUpWithEmail(
        email,
        password,
        fullName,
        token ?? undefined,
      );
      if (hasSession) {
        router.replace("/home");
      } else {
        toast.success(t("signup_check_inbox_body"));
        router.replace("/login");
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex flex-1 flex-col">
      <h1 className="text-2xl font-bold text-ink">{t("signup_title")}</h1>
      <p className="mb-6 mt-1 text-ink-muted">{t("signup_subtitle")}</p>

      <form onSubmit={submit} className="flex flex-col gap-4">
        <TextField
          name="name"
          label={t("common_full_name")}
          autoComplete="name"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          error={errors.fullName}
        />
        <TextField
          name="email"
          type="email"
          autoComplete="email"
          label={t("common_email")}
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={errors.email}
        />
        <TextField
          name="password"
          type="password"
          autoComplete="new-password"
          label={t("common_password")}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={errors.password}
        />
        <TextField
          name="confirm"
          type="password"
          autoComplete="new-password"
          label={t("signup_confirm_password")}
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          error={errors.confirm}
        />
        {captchaEnabled && <Captcha onToken={setToken} />}
        <Button type="submit" variant="primary" fullWidth loading={loading}>
          {t("signup_button")}
        </Button>
      </form>

      <p className="mt-8 text-center text-sm text-ink-muted">
        {t("login_no_account")}{" "}
        <Link href="/login" className="font-semibold text-accent">
          {t("login_button")}
        </Link>
      </p>
    </div>
  );
}
