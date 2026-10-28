import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  Bell,
  ChevronRight,
  Globe,
  GraduationCap,
  HelpCircle,
  Info,
  LogOut,
  Palette,
  Target,
} from "lucide-react";

import { Avatar } from "@/components/ui/Avatar";
import { Card } from "@/components/ui/Card";
import { SegmentedControl } from "@/components/ui/SegmentedControl";
import { Sheet } from "@/components/ui/Sheet";
import { Toggle } from "@/components/ui/Toggle";
import { APP_LOCALES, type AppLocale } from "@/lib/i18n";
import { signOut } from "@/lib/auth/authService";
import { saveReminderSettings, subscribeToPush, unsubscribeFromPush } from "@/lib/services/push";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import {
  setLocale,
  setReminder,
  setStudyMode,
  setTheme,
  type ThemeChoice,
} from "@/store/slices/prefsSlice";
import { setDailyGoal } from "@/store/slices/streakSlice";
import type { StudyMode } from "@/lib/data/models";
import { cn } from "@/lib/utils/cn";

function Row({
  icon,
  label,
  value,
  onClick,
  trailing,
  tint,
}: {
  icon: React.ReactNode;
  label: string;
  value?: string;
  onClick?: () => void;
  trailing?: React.ReactNode;
  tint: string;
}) {
  const Comp = onClick ? "button" : "div";
  return (
    <Comp
      onClick={onClick}
      className={cn(
        "flex w-full items-center gap-3 px-4 py-3.5 text-left transition-colors",
        onClick && "hover:bg-ink/[0.03]",
      )}
    >
      <span className={cn("grid h-9 w-9 shrink-0 place-items-center rounded-xl", tint)}>
        {icon}
      </span>
      <span className="flex-1 font-semibold text-ink">{label}</span>
      {value && <span className="text-sm font-medium text-ink-muted">{value}</span>}
      {trailing ?? (onClick && <ChevronRight size={18} className="text-ink-muted" />)}
    </Comp>
  );
}

const STUDY_MODES: { value: StudyMode; label: string }[] = [
  { value: "smart", label: "study_mode_smart" },
  { value: "quiz", label: "study_mode_quiz" },
  { value: "flip", label: "study_mode_flip" },
  { value: "listen", label: "deck_listen" },
];

const GOALS = [10, 20, 30, 50];

export function Profile() {
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const user = useAppSelector((s) => s.auth.user);
  const prefs = useAppSelector((s) => s.prefs);
  const dailyGoal = useAppSelector((s) => s.streak.dailyGoal);

  const [sheet, setSheet] = useState<null | "mode" | "goal" | "language">(null);

  async function toggleReminder(enabled: boolean) {
    if (enabled) {
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
  }

  function setTime(value: string) {
    const [h, m] = value.split(":").map(Number);
    dispatch(setReminder({ enabled: prefs.reminderEnabled, hour: h, minute: m }));
    void saveReminderSettings({ enabled: prefs.reminderEnabled, hour: h, minute: m });
  }

  const modeLabel = t(
    (STUDY_MODES.find((m) => m.value === prefs.studyMode)?.label ?? "study_mode_smart") as "study_mode_smart",
  );
  const localeLabel = APP_LOCALES.find((l) => l.code === prefs.locale)?.nativeName ?? "English";

  return (
    <div className="mx-auto max-w-2xl space-y-5">
      <h1 className="font-display text-[2rem] font-bold text-ink">
        {t("profile_your_account")}
      </h1>

      {/* Identity card */}
      <Link to="/edit-profile" className="block">
        <Card interactive className="flex items-center gap-4">
          <Avatar name={user?.fullName} email={user?.email} src={user?.avatarUrl} size={60} />
          <div className="min-w-0 flex-1">
            <h2 className="truncate font-display text-xl font-bold text-ink">
              {user?.fullName ?? t("common_full_name")}
            </h2>
            <p className="truncate text-sm text-ink-muted">{user?.email}</p>
          </div>
          <ChevronRight className="text-ink-muted" />
        </Card>
      </Link>

      {/* Reminder */}
      <Card padded={false} className="overflow-hidden">
        <Row
          icon={<Bell size={18} className="text-flame" />}
          label={t("reminder_settings_title")}
          tint="bg-flame/15"
          trailing={<Toggle checked={prefs.reminderEnabled} onChange={toggleReminder} />}
        />
        {prefs.reminderEnabled && (
          <div className="flex items-center justify-between border-t border-border px-4 py-3.5">
            <span className="font-semibold text-ink">{t("reminder_every_day_at")}</span>
            <input
              type="time"
              value={`${String(prefs.reminderHour).padStart(2, "0")}:${String(prefs.reminderMinute).padStart(2, "0")}`}
              onChange={(e) => setTime(e.target.value)}
              className="rounded-xl border-2 border-border bg-card px-3 py-1.5 font-semibold text-ink focus:border-coral focus:outline-none"
            />
          </div>
        )}
      </Card>

      {/* Appearance */}
      <Card className="space-y-3">
        <div className="flex items-center gap-3">
          <span className="grid h-9 w-9 place-items-center rounded-xl bg-hue-violet/15 text-hue-violet">
            <Palette size={18} />
          </span>
          <span className="font-semibold text-ink">{t("profile_appearance")}</span>
        </div>
        <SegmentedControl<ThemeChoice>
          className="w-full"
          value={prefs.theme}
          onChange={(v) => dispatch(setTheme(v))}
          options={[
            { value: "system", label: "Auto" },
            { value: "light", label: "Light" },
            { value: "dark", label: "Dark" },
          ]}
        />
      </Card>

      {/* Settings list */}
      <Card padded={false} className="divide-y divide-border overflow-hidden">
        <Row
          icon={<GraduationCap size={18} className="text-hue-teal" />}
          label={t("study_mode_title")}
          value={modeLabel}
          tint="bg-hue-teal/15"
          onClick={() => setSheet("mode")}
        />
        <Row
          icon={<Target size={18} className="text-coral" />}
          label={t("goal_settings_title")}
          value={t("goal_cards_per_day", { count: dailyGoal })}
          tint="bg-coral/15"
          onClick={() => setSheet("goal")}
        />
        <Row
          icon={<Globe size={18} className="text-hue-sky" />}
          label={t("profile_language")}
          value={localeLabel}
          tint="bg-hue-sky/15"
          onClick={() => setSheet("language")}
        />
      </Card>

      <Card padded={false} className="divide-y divide-border overflow-hidden">
        <Row
          icon={<HelpCircle size={18} className="text-hue-moss" />}
          label={t("profile_help_support")}
          tint="bg-hue-moss/15"
          onClick={() => navigate("/help")}
        />
        <Row
          icon={<Info size={18} className="text-ink-muted" />}
          label={t("profile_about")}
          tint="bg-ink/10"
          onClick={() => toast.info(t("profile_about_coming_soon"))}
        />
      </Card>

      <button
        onClick={() => signOut()}
        className="flex w-full items-center justify-center gap-2 rounded-2xl border-2 border-error/30 bg-error/5 py-3.5 font-display font-bold text-error transition-colors hover:bg-error/10"
      >
        <LogOut size={18} /> {t("profile_sign_out")}
      </button>

      {/* Study-mode sheet */}
      <Sheet open={sheet === "mode"} onClose={() => setSheet(null)} title={t("study_mode_title")}>
        <div className="space-y-2">
          {STUDY_MODES.map((m) => (
            <button
              key={m.value}
              onClick={() => {
                dispatch(setStudyMode(m.value));
                setSheet(null);
              }}
              className={cn(
                "flex w-full items-center justify-between rounded-2xl border-2 px-4 py-3 text-left font-semibold transition-colors",
                prefs.studyMode === m.value
                  ? "border-coral bg-coral-soft text-coral"
                  : "border-border text-ink hover:border-coral/40",
              )}
            >
              {t(m.label as "study_mode_smart")}
              {prefs.studyMode === m.value && <span>✓</span>}
            </button>
          ))}
        </div>
      </Sheet>

      {/* Goal sheet */}
      <Sheet open={sheet === "goal"} onClose={() => setSheet(null)} title={t("goal_settings_title")}>
        <div className="grid grid-cols-2 gap-3">
          {GOALS.map((g) => (
            <button
              key={g}
              onClick={() => {
                dispatch(setDailyGoal(g));
                setSheet(null);
              }}
              className={cn(
                "rounded-2xl border-2 py-5 text-center transition-colors",
                dailyGoal === g
                  ? "border-coral bg-coral-soft"
                  : "border-border hover:border-coral/40",
              )}
            >
              <div className="font-display text-3xl font-bold text-ink">{g}</div>
              <div className="text-xs font-semibold text-ink-muted">
                {t("goal_cards_per_day", { count: g })}
              </div>
            </button>
          ))}
        </div>
      </Sheet>

      {/* Language sheet */}
      <Sheet open={sheet === "language"} onClose={() => setSheet(null)} title={t("profile_language")}>
        <div className="space-y-2">
          {APP_LOCALES.map((l) => (
            <button
              key={l.code}
              onClick={() => {
                dispatch(setLocale(l.code as AppLocale));
                setSheet(null);
              }}
              className={cn(
                "flex w-full items-center gap-3 rounded-2xl border-2 px-4 py-3 text-left font-semibold transition-colors",
                prefs.locale === l.code
                  ? "border-coral bg-coral-soft text-coral"
                  : "border-border text-ink hover:border-coral/40",
              )}
            >
              <span className="text-2xl">{l.flag}</span>
              {l.nativeName}
              {prefs.locale === l.code && <span className="ml-auto">✓</span>}
            </button>
          ))}
        </div>
      </Sheet>
    </div>
  );
}
