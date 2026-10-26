"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { AlertTriangle, ChevronLeft } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import * as auth from "@/lib/auth/authService";
import { toast } from "@/lib/toast";
import { resetStreak } from "@/store/slices/streakSlice";
import { useAppDispatch, useAppSelector } from "@/store/hooks";

const CONFIRM_WORD = "DELETE";

export default function DeleteAccountPage() {
  const t = useT();
  const router = useRouter();
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.auth.user);
  const [step, setStep] = useState<"warning" | "confirm">("warning");
  const [understood, setUnderstood] = useState(false);
  const [typed, setTyped] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);

  const canDelete =
    understood &&
    typed.trim().toUpperCase() === CONFIRM_WORD &&
    (!user?.hasPassword || password.length > 0);

  async function doDelete() {
    setBusy(true);
    try {
      if (user?.hasPassword) {
        try {
          await auth.reauthenticate(password);
        } catch {
          toast.error(t("password_wrong_current"));
          return;
        }
      }
      await auth.deleteAccount();
      dispatch(resetStreak());
      toast.success(t("delete_done"));
      router.replace("/login");
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
        <h1 className="text-lg font-bold text-error">{t("edit_profile_delete_account")}</h1>
      </header>

      <div className="px-5 pb-10">
        <div className="mb-5 flex items-center gap-3 rounded-xl bg-error/10 p-4 text-error">
          <AlertTriangle size={24} />
          <span className="font-semibold">
            {step === "warning" ? t("delete_title") : t("delete_confirm_title")}
          </span>
        </div>

        {step === "warning" ? (
          <>
            <p className="text-ink">{t("delete_intro")}</p>
            <ul className="mt-3 space-y-2 text-ink-muted">
              <li>• {t("delete_item_decks")}</li>
              <li>• {t("delete_item_progress")}</li>
              <li>• {t("delete_item_profile")}</li>
            </ul>
            <p className="mt-4 text-sm text-ink-muted">{t("delete_permanent_note")}</p>
            <div className="mt-6 flex flex-col gap-3">
              <Button variant="danger" fullWidth onClick={() => setStep("confirm")}>
                {t("delete_continue")}
              </Button>
              <Button variant="secondary" fullWidth onClick={() => router.back()}>
                {t("delete_keep_account")}
              </Button>
            </div>
          </>
        ) : (
          <>
            <label className="flex items-start gap-3 py-2">
              <input
                type="checkbox"
                checked={understood}
                onChange={(e) => setUnderstood(e.target.checked)}
                className="mt-1 h-5 w-5 accent-[rgb(var(--error))]"
              />
              <span className="text-sm text-ink">{t("delete_confirm_understand")}</span>
            </label>
            <div className="mt-4">
              <TextField
                label={t("delete_confirm_type_label", { word: CONFIRM_WORD })}
                value={typed}
                onChange={(e) => setTyped(e.target.value)}
              />
            </div>
            {user?.hasPassword && (
              <div className="mt-3">
                <TextField
                  type="password"
                  label={t("password_current")}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
            )}
            <Button
              variant="danger"
              fullWidth
              className="mt-6"
              disabled={!canDelete}
              loading={busy}
              onClick={doDelete}
            >
              {t("delete_confirm_button")}
            </Button>
          </>
        )}
      </div>
    </div>
  );
}
