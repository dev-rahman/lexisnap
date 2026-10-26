"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { ChevronLeft } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import * as auth from "@/lib/auth/authService";
import { toast } from "@/lib/toast";
import { useAppSelector } from "@/store/hooks";

type Step = "newEmail" | "codeNew" | "codeCurrent";

export default function ChangeEmailPage() {
  const t = useT();
  const router = useRouter();
  const user = useAppSelector((s) => s.auth.user);
  const [step, setStep] = useState<Step>("newEmail");
  const [newEmail, setNewEmail] = useState("");
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);

  async function request() {
    if (!/^\S+@\S+\.\S+$/.test(newEmail)) return;
    if (newEmail.trim() === user?.email) {
      toast.error(t("email_change_same_email"));
      return;
    }
    setBusy(true);
    try {
      await auth.requestEmailChange(newEmail.trim());
      setStep("codeNew");
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setBusy(false);
    }
  }

  async function verify(email: string) {
    setBusy(true);
    try {
      const done = await auth.verifyEmailChangeCode(email, code);
      setCode("");
      if (done) {
        toast.success(t("email_change_updated", { email: newEmail }));
        router.back();
      } else {
        // Secure email change: a second code went to the current address.
        setStep("codeCurrent");
      }
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mx-auto min-h-dvh max-w-md bg-paper">
      <header className="flex items-center gap-2 px-4 py-3 safe-top">
        <button onClick={() => router.back()} aria-label="Back" className="text-ink">
          <ChevronLeft size={26} />
        </button>
        <h1 className="text-lg font-bold text-ink">{t("email_change_title")}</h1>
      </header>

      <div className="px-5">
        {step === "newEmail" && (
          <>
            <p className="mb-1 mt-2 text-ink-muted">{t("email_change_subtitle")}</p>
            <p className="mb-5 text-sm text-ink-muted">
              {t("email_change_current", { email: user?.email ?? "" })}
            </p>
            <TextField
              type="email"
              label={t("email_change_new_label")}
              value={newEmail}
              onChange={(e) => setNewEmail(e.target.value)}
            />
            <Button variant="primary" fullWidth className="mt-4" loading={busy} onClick={request}>
              {t("forgot_password_button")}
            </Button>
          </>
        )}

        {(step === "codeNew" || step === "codeCurrent") && (
          <>
            <h2 className="mt-2 text-xl font-bold text-ink">
              {step === "codeNew" ? t("email_change_code_new_title") : t("email_change_code_current_title")}
            </h2>
            <p className="mb-5 mt-1 text-ink-muted">
              {step === "codeNew"
                ? t("email_change_code_new_body", { email: newEmail })
                : t("email_change_code_current_body", { email: user?.email ?? "" })}
            </p>
            <TextField
              inputMode="numeric"
              label={t("forgot_password_verify_button")}
              value={code}
              onChange={(e) => setCode(e.target.value)}
            />
            <Button
              variant="primary"
              fullWidth
              className="mt-4"
              loading={busy}
              onClick={() => verify(step === "codeNew" ? newEmail : user?.email ?? "")}
            >
              {t("forgot_password_verify_button")}
            </Button>
          </>
        )}
      </div>
    </div>
  );
}
