"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import {
  Bell,
  ChevronRight,
  Globe,
  GraduationCap,
  HelpCircle,
  Info,
  LogOut,
  Moon,
  Target,
} from "lucide-react";

import { PageShell } from "@/components/shell/PageShell";

import { Avatar } from "@/components/ui/Avatar";
import { Button } from "@/components/ui/Button";
import { ConfirmSheet, Sheet } from "@/components/ui/Sheet";
import { useT } from "@/components/providers/I18nProvider";
import type { StudyMode } from "@/lib/data/models";
import { APP_LOCALES, type AppLocale, type MessageKey } from "@/lib/i18n";
import * as auth from "@/lib/auth/authService";
import { saveReminderSettings, subscribeToPush, unsubscribeFromPush } from "@/lib/services/push";
import { pushConfigured } from "@/lib/config";
import { toast } from "@/lib/toast";
import {
  setLocale,
  setReminder,
  setStudyMode,
  setTheme,
  type ThemeChoice,
} from "@/store/slices/prefsSlice";
import { setDailyGoal } from "@/store/slices/streakSlice";
import { useAppDispatch, useAppSelector } from "@/store/hooks";

type SheetName = "reminder" | "mode" | "goal" | "theme" | "language" | null;

export default function ProfilePage() {
  const t = useT();
  const router = useRouter();
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.auth.user);
  const prefs = useAppSelector((s) => s.prefs);
  const dailyGoal = useAppSelector((s) => s.streak.dailyGoal);
  const [sheet, setSheet] = useState<SheetName>(null);
  const [signingOut, setSigningOut] = useState(false);

  const time = `${String(prefs.reminderHour).padStart(2, "0")}:${String(prefs.reminderMinute).padStart(2, "0")}`;

  async function doSignOut() {
    try {
      await auth.signOut();
      router.replace("/login");
    } catch {
      toast.error(t("common_something_went_wrong"));
    }
  }

  return (
    <PageShell title={t("profile_your_account")}>
        {/* Account card */}
        <button
          onClick={() => router.push("/edit-profile")}
          className="card mb-6 flex w-full items-center gap-3 rounded-2xl p-4 text-left"
        >
          <Avatar src={user?.avatarUrl} name={user?.fullName} email={user?.email} size={52} />
          <span className="min-w-0 flex-1">
            <span className="block truncate font-semibold text-ink">
              {user?.fullName ?? t("edit_profile_not_set")}
            </span>
            <span className="block truncate text-sm text-ink-muted">{user?.email}</span>
          </span>
          <ChevronRight size={20} className="text-ink-muted" />
        </button>

        <div className="card overflow-hidden rounded-2xl">
          <Row icon={<Bell size={20} />} label={t("reminder_settings_title")} value={prefs.reminderEnabled ? t("reminder_every_day_at", { time }) : t("reminder_off")} onClick={() => setSheet("reminder")} />
          <Row icon={<GraduationCap size={20} />} label={t("study_mode_title")} value={t(modeLabelKey(prefs.studyMode))} onClick={() => setSheet("mode")} />
          <Row icon={<Target size={20} />} label={t("goal_settings_title")} value={t("goal_cards_per_day", { count: dailyGoal })} onClick={() => setSheet("goal")} />
          <Row icon={<Moon size={20} />} label={t("profile_appearance")} value={themeLabel(prefs.theme)} onClick={() => setSheet("theme")} />
          <Row icon={<Globe size={20} />} label={t("profile_language")} value={APP_LOCALES.find((l) => l.code === prefs.locale)?.nativeName ?? ""} onClick={() => setSheet("language")} />
          <Row icon={<HelpCircle size={20} />} label={t("profile_help_support")} onClick={() => router.push("/help")} />
          <Row icon={<Info size={20} />} label={t("profile_about")} onClick={() => toast.info(t("profile_about_coming_soon"))} last />
        </div>

        <button
          onClick={() => setSigningOut(true)}
          className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl border border-border py-3.5 font-semibold text-error"
        >
          <LogOut size={18} /> {t("profile_sign_out")}
        </button>

      {/* Sheets */}
      <ReminderSheet open={sheet === "reminder"} onClose={() => setSheet(null)} />
      <ModeSheet open={sheet === "mode"} onClose={() => setSheet(null)} current={prefs.studyMode} onPick={(m) => dispatch(setStudyMode(m))} />
      <GoalSheet open={sheet === "goal"} onClose={() => setSheet(null)} current={dailyGoal} onPick={(g) => dispatch(setDailyGoal(g))} />
      <ThemeSheet open={sheet === "theme"} onClose={() => setSheet(null)} current={prefs.theme} onPick={(th) => dispatch(setTheme(th))} />
      <LanguageSheet open={sheet === "language"} onClose={() => setSheet(null)} current={prefs.locale} onPick={(l) => dispatch(setLocale(l))} />

      <ConfirmSheet
        open={signingOut}
        onClose={() => setSigningOut(false)}
        title={t("sign_out_confirm_title")}
        message={t("sign_out_confirm_body")}
        cancelLabel={t("common_cancel")}
        confirmLabel={t("profile_sign_out")}
        danger
        onConfirm={doSignOut}
      />
    </PageShell>
  );
}

function modeLabelKey(m: StudyMode): MessageKey {
  return m === "quiz" ? "study_mode_quiz" : m === "flip" ? "study_mode_flip" : m === "listen" ? "deck_listen" : "study_mode_smart";
}
function themeLabel(th: ThemeChoice): string {
  return th === "light" ? "Light" : th === "dark" ? "Dark" : "System";
}

function Row({
  icon,
  label,
  value,
  onClick,
  last,
}: {
  icon: React.ReactNode;
  label: string;
  value?: string;
  onClick: () => void;
  last?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex w-full items-center gap-3 bg-card px-4 py-3.5 text-left ${last ? "" : "border-b border-border"}`}
    >
      <span className="text-ink-muted">{icon}</span>
      <span className="flex-1 font-medium text-ink">{label}</span>
      {value && <span className="text-sm text-ink-muted">{value}</span>}
      <ChevronRight size={18} className="text-ink-muted" />
    </button>
  );
}

function ReminderSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const t = useT();
  const dispatch = useAppDispatch();
  const prefs = useAppSelector((s) => s.prefs);
  const [busy, setBusy] = useState(false);

  async function toggle(enabled: boolean) {
    setBusy(true);
    try {
      if (enabled) {
        if (!pushConfigured) {
          toast.info(t("common_coming_soon"));
          return;
        }
        const ok = await subscribeToPush();
        if (!ok) {
          toast.error(t("reminder_permission_denied"));
          return;
        }
      } else {
        await unsubscribeFromPush();
      }
      dispatch(setReminder({ enabled, hour: prefs.reminderHour, minute: prefs.reminderMinute }));
      await saveReminderSettings({ enabled, hour: prefs.reminderHour, minute: prefs.reminderMinute });
    } finally {
      setBusy(false);
    }
  }

  function setTime(value: string) {
    const [h, m] = value.split(":").map(Number);
    dispatch(setReminder({ enabled: prefs.reminderEnabled, hour: h, minute: m }));
    if (prefs.reminderEnabled) void saveReminderSettings({ enabled: true, hour: h, minute: m });
  }

  const time = `${String(prefs.reminderHour).padStart(2, "0")}:${String(prefs.reminderMinute).padStart(2, "0")}`;

  return (
    <Sheet open={open} onClose={onClose} title={t("reminder_settings_title")}>
      <label className="flex items-center justify-between py-2">
        <span className="font-medium text-ink">{t("reminder_settings_title")}</span>
        <input type="checkbox" checked={prefs.reminderEnabled} disabled={busy} onChange={(e) => toggle(e.target.checked)} className="h-6 w-6 accent-[rgb(var(--accent))]" />
      </label>
      {prefs.reminderEnabled && (
        <div className="mt-3 flex items-center justify-between">
          <span className="text-ink-muted">{t("reminder_every_day_at", { time: "" }).replace("{time}", "")}</span>
          <input type="time" value={time} onChange={(e) => setTime(e.target.value)} className="rounded-md border border-border bg-surface px-3 py-2 text-ink" />
        </div>
      )}
      {!pushConfigured && <p className="mt-3 text-sm text-ink-muted">{t("common_coming_soon")}</p>}
    </Sheet>
  );
}

function ModeSheet({ open, onClose, current, onPick }: { open: boolean; onClose: () => void; current: StudyMode; onPick: (m: StudyMode) => void }) {
  const t = useT();
  const opts: { mode: StudyMode; label: MessageKey; hint: MessageKey }[] = [
    { mode: "smart", label: "study_mode_smart", hint: "study_mode_smart_hint" },
    { mode: "quiz", label: "study_mode_quiz", hint: "study_mode_quiz_hint" },
    { mode: "flip", label: "study_mode_flip", hint: "study_mode_flip_hint" },
    { mode: "listen", label: "deck_listen", hint: "study_mode_listen_hint" },
  ];
  return (
    <Sheet open={open} onClose={onClose} title={t("study_mode_title")}>
      <div className="space-y-2">
        {opts.map((o) => (
          <button
            key={o.mode}
            onClick={() => {
              onPick(o.mode);
              onClose();
            }}
            className={`flex w-full flex-col rounded-lg border p-3 text-left ${current === o.mode ? "border-accent bg-accent/10" : "border-border bg-surface"}`}
          >
            <span className="font-semibold text-ink">{t(o.label)}</span>
            <span className="text-sm text-ink-muted">{t(o.hint)}</span>
          </button>
        ))}
      </div>
    </Sheet>
  );
}

function GoalSheet({ open, onClose, current, onPick }: { open: boolean; onClose: () => void; current: number; onPick: (g: number) => void }) {
  const t = useT();
  return (
    <Sheet open={open} onClose={onClose} title={t("goal_settings_title")}>
      <div className="grid grid-cols-2 gap-2">
        {[10, 20, 30, 50].map((g) => (
          <button
            key={g}
            onClick={() => {
              onPick(g);
              onClose();
            }}
            className={`rounded-lg border py-3 font-semibold ${current === g ? "border-accent bg-accent/10 text-ink" : "border-border bg-surface text-ink"}`}
          >
            {t("goal_cards_per_day", { count: g })}
          </button>
        ))}
      </div>
    </Sheet>
  );
}

function ThemeSheet({ open, onClose, current, onPick }: { open: boolean; onClose: () => void; current: ThemeChoice; onPick: (t: ThemeChoice) => void }) {
  const t = useT();
  const opts: { v: ThemeChoice; label: string }[] = [
    { v: "system", label: "System" },
    { v: "light", label: "Light" },
    { v: "dark", label: "Dark" },
  ];
  return (
    <Sheet open={open} onClose={onClose} title={t("profile_appearance")}>
      <div className="space-y-2">
        {opts.map((o) => (
          <button
            key={o.v}
            onClick={() => {
              onPick(o.v);
              onClose();
            }}
            className={`flex w-full items-center justify-between rounded-lg border p-3 font-medium ${current === o.v ? "border-accent bg-accent/10 text-ink" : "border-border bg-surface text-ink"}`}
          >
            {o.label}
            {current === o.v && <span className="text-accent">✓</span>}
          </button>
        ))}
      </div>
    </Sheet>
  );
}

function LanguageSheet({ open, onClose, current, onPick }: { open: boolean; onClose: () => void; current: AppLocale; onPick: (l: AppLocale) => void }) {
  const t = useT();
  return (
    <Sheet open={open} onClose={onClose} title={t("profile_language")}>
      <div className="space-y-1">
        {APP_LOCALES.map((l) => (
          <button
            key={l.code}
            onClick={() => {
              onPick(l.code);
              onClose();
            }}
            className={`flex w-full items-center gap-3 rounded-lg p-3 text-left ${current === l.code ? "bg-accent/10" : "hover:bg-surface"}`}
          >
            <span className="text-xl">{l.flag}</span>
            <span className="flex-1 font-medium text-ink">{l.nativeName}</span>
            {current === l.code && <span className="text-accent">✓</span>}
          </button>
        ))}
      </div>
    </Sheet>
  );
}
