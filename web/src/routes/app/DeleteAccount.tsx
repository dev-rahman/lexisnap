import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { AlertTriangle, Lock } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { TextField } from "@/components/ui/TextField";
import { PageHeader } from "@/components/shell/PageHeader";
import { deleteAccount, reauthenticate } from "@/lib/auth/authService";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { resetStreak } from "@/store/slices/streakSlice";

type Step = "intro" | "confirm" | "final";

export function DeleteAccount() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const hasPassword = useAppSelector((s) => s.auth.user?.hasPassword);

  const [step, setStep] = useState<Step>("intro");
  const [typed, setTyped] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function onDelete() {
    setLoading(true);
    try {
      if (hasPassword) await reauthenticate(password);
      await deleteAccount();
      dispatch(resetStreak());
      toast.success(t("delete_done"));
      navigate("/login", { replace: true });
    } catch (err) {
      toast.error(err instanceof Error ? err.message : t("common_something_went_wrong"));
      setLoading(false);
    }
  }

  return (
    <div className="mx-auto max-w-md">
      <PageHeader title={t("delete_title")} />

      <Card className="space-y-5">
        <div className="flex flex-col items-center text-center">
          <div className="grid h-16 w-16 place-items-center rounded-3xl bg-error/15 text-error">
            <AlertTriangle size={32} />
          </div>
        </div>

        {step === "intro" && (
          <>
            <p className="text-center text-ink-muted">{t("delete_intro")}</p>
            <ul className="space-y-2">
              {[t("delete_item_decks"), t("delete_item_progress"), t("delete_item_profile")].map(
                (item) => (
                  <li
                    key={item}
                    className="flex items-center gap-2 rounded-2xl bg-error/5 px-4 py-3 text-sm font-medium text-ink"
                  >
                    <span className="h-1.5 w-1.5 rounded-full bg-error" /> {item}
                  </li>
                ),
              )}
            </ul>
            <p className="text-center text-sm font-semibold text-error">
              {t("delete_permanent_note")}
            </p>
            <div className="flex flex-col gap-2">
              <Button variant="danger" fullWidth onClick={() => setStep("confirm")}>
                {t("delete_continue")}
              </Button>
              <Button variant="ghost" fullWidth onClick={() => navigate(-1)}>
                {t("delete_keep_account")}
              </Button>
            </div>
          </>
        )}

        {step === "confirm" && (
          <>
            <h2 className="text-center font-display text-lg font-bold text-ink">
              {t("delete_confirm_title")}
            </h2>
            <label className="flex items-start gap-3 rounded-2xl bg-surface px-4 py-3 text-sm text-ink">
              <span>{t("delete_confirm_understand")}</span>
            </label>
            <div>
              <p className="mb-1.5 text-sm font-semibold text-ink-soft">
                {t("delete_confirm_type_label")}
              </p>
              <TextField
                value={typed}
                onChange={(e) => setTyped(e.target.value)}
                placeholder="DELETE"
              />
            </div>
            <Button
              variant="danger"
              fullWidth
              disabled={typed.trim().toUpperCase() !== "DELETE"}
              onClick={() => setStep("final")}
            >
              {t("delete_confirm_button")}
            </Button>
          </>
        )}

        {step === "final" && (
          <>
            <h2 className="text-center font-display text-lg font-bold text-ink">
              {t("delete_final_title")}
            </h2>
            <p className="text-center text-sm text-ink-muted">{t("delete_final_body")}</p>
            {hasPassword && (
              <TextField
                label={t("common_password")}
                type="password"
                leftIcon={<Lock size={18} />}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            )}
            <Button
              variant="danger"
              fullWidth
              loading={loading}
              disabled={hasPassword && !password}
              onClick={onDelete}
            >
              {t("delete_final_button")}
            </Button>
          </>
        )}
      </Card>
    </div>
  );
}
