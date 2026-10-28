import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { KeyRound, Mail } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { TextField } from "@/components/ui/TextField";
import { PageHeader } from "@/components/shell/PageHeader";
import { requestEmailChange, verifyEmailChangeCode } from "@/lib/auth/authService";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppSelector } from "@/store/hooks";

type Step = "enter" | "verifyNew" | "verifyCurrent";

export function ChangeEmail() {
  const t = useT();
  const navigate = useNavigate();
  const currentEmail = useAppSelector((s) => s.auth.user?.email) ?? "";

  const [step, setStep] = useState<Step>("enter");
  const [newEmail, setNewEmail] = useState("");
  const [code, setCode] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function request(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (newEmail.trim().toLowerCase() === currentEmail.toLowerCase()) {
      return setError(t("email_change_same_email"));
    }
    setLoading(true);
    try {
      await requestEmailChange(newEmail);
      setStep("verifyNew");
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  async function verify(e: FormEvent, address: string, next: Step | "done") {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await verifyEmailChangeCode(address, code);
      setCode("");
      if (next === "done") {
        toast.success(t("email_change_updated"));
        navigate("/profile", { replace: true });
      } else {
        setStep(next);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : t("common_something_went_wrong"));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader title={t("email_change_title")} subtitle={t("email_change_subtitle")} />
      <Card className="space-y-4">
        {step === "enter" && (
          <form onSubmit={request} className="space-y-4">
            <div className="rounded-2xl bg-surface px-4 py-3 text-sm">
              <span className="text-ink-muted">{t("email_change_current")}: </span>
              <span className="font-semibold text-ink">{currentEmail}</span>
            </div>
            <TextField
              label={t("email_change_new_label")}
              type="email"
              leftIcon={<Mail size={18} />}
              value={newEmail}
              onChange={(e) => setNewEmail(e.target.value)}
              error={error}
              required
            />
            <Button type="submit" fullWidth loading={loading}>
              {t("common_save")}
            </Button>
          </form>
        )}

        {step === "verifyNew" && (
          <form onSubmit={(e) => verify(e, newEmail, "verifyCurrent")} className="space-y-4">
            <p className="text-sm text-ink-muted">
              {t("email_change_code_new_body", { email: newEmail })}
            </p>
            <TextField
              label={t("email_change_code_new_title")}
              inputMode="numeric"
              leftIcon={<KeyRound size={18} />}
              value={code}
              onChange={(e) => setCode(e.target.value)}
              error={error}
              required
            />
            <Button type="submit" fullWidth loading={loading}>
              {t("forgot_password_verify_button")}
            </Button>
          </form>
        )}

        {step === "verifyCurrent" && (
          <form onSubmit={(e) => verify(e, currentEmail, "done")} className="space-y-4">
            <p className="text-sm text-ink-muted">
              {t("email_change_code_current_body", { email: currentEmail })}
            </p>
            <TextField
              label={t("email_change_code_current_title")}
              inputMode="numeric"
              leftIcon={<KeyRound size={18} />}
              value={code}
              onChange={(e) => setCode(e.target.value)}
              error={error}
              required
            />
            <Button type="submit" fullWidth loading={loading}>
              {t("forgot_password_verify_button")}
            </Button>
          </form>
        )}
      </Card>
    </div>
  );
}
