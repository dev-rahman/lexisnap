import { useState } from "react";
import { Check, Crown, Sparkles, Zap } from "lucide-react";

import { PageHeader } from "@/components/shell/PageHeader";
import { Button } from "@/components/ui/Button";
import { Sheet } from "@/components/ui/Sheet";
import { CURRENT_TIER, PLANS, type Accent, type Plan } from "@/lib/data/plans";
import { useT } from "@/providers/I18nProvider";
import { cn } from "@/lib/utils/cn";

/** Per-accent class strings. Kept as literals so Tailwind's JIT keeps them. */
const ACCENT: Record<Accent, { text: string; soft: string; ring: string; icon: React.ReactNode }> = {
  sky: {
    text: "text-hue-sky",
    soft: "bg-hue-sky/12",
    ring: "ring-hue-sky/60",
    icon: <Zap size={20} />,
  },
  coral: {
    text: "text-coral",
    soft: "bg-coral-soft",
    ring: "ring-coral/60",
    icon: <Sparkles size={20} />,
  },
  violet: {
    text: "text-hue-violet",
    soft: "bg-hue-violet/12",
    ring: "ring-hue-violet/60",
    icon: <Crown size={20} />,
  },
};

function PlanCard({
  plan,
  current,
  onChoose,
}: {
  plan: Plan;
  current: boolean;
  onChoose: () => void;
}) {
  const t = useT();
  const a = ACCENT[plan.accent];

  return (
    <div
      className={cn(
        "relative flex flex-col rounded-3xl border bg-card p-6 shadow-soft",
        plan.highlight
          ? cn("border-transparent ring-2", a.ring)
          : "border-border",
        current && "ring-2 ring-success/60",
      )}
    >
      {plan.highlight && !current && (
        <span
          className={cn(
            "absolute -top-3 left-6 rounded-full px-3 py-1 text-xs font-bold text-white shadow-soft",
            "bg-hue-violet",
          )}
        >
          {t("plan_badge_popular")}
        </span>
      )}
      {current && (
        <span className="absolute -top-3 left-6 rounded-full bg-success px-3 py-1 text-xs font-bold text-white shadow-soft">
          {t("subscription_current_label")}
        </span>
      )}

      <div className="flex items-center gap-3">
        <span className={cn("grid h-11 w-11 place-items-center rounded-2xl", a.soft, a.text)}>
          {a.icon}
        </span>
        <div>
          <h2 className="font-display text-xl font-bold text-ink">{t(plan.nameKey)}</h2>
          <p className="text-sm text-ink-muted">{t(plan.taglineKey)}</p>
        </div>
      </div>

      <div className="mt-5 flex items-end gap-1">
        {plan.priceEur === 0 ? (
          <span className="font-display text-4xl font-bold text-ink">{t("plan_price_free")}</span>
        ) : (
          <>
            <span className="font-display text-4xl font-bold text-ink">€{plan.priceEur}</span>
            <span className="mb-1 text-sm font-semibold text-ink-muted">{t("plan_per_month")}</span>
          </>
        )}
      </div>

      <ul className="mt-5 flex-1 space-y-3">
        {plan.features.map((f) => (
          <li key={f.key} className="flex items-start gap-2.5">
            <span className={cn("mt-0.5 shrink-0", a.text)}>
              <Check size={18} strokeWidth={2.5} />
            </span>
            <span className="text-[15px] text-ink-soft">
              {t(f.key, f.count != null ? { count: f.count } : undefined)}
            </span>
          </li>
        ))}
      </ul>

      <div className="mt-6">
        {current ? (
          <Button variant="secondary" fullWidth disabled>
            {t("plan_current")}
          </Button>
        ) : (
          <Button
            variant={plan.highlight ? "primary" : "secondary"}
            fullWidth
            onClick={onChoose}
          >
            {t("plan_upgrade_to", { name: t(plan.nameKey) })}
          </Button>
        )}
      </div>
    </div>
  );
}

export function Subscription() {
  const t = useT();
  const [chosen, setChosen] = useState<Plan | null>(null);

  return (
    <div className="mx-auto max-w-4xl">
      <PageHeader title={t("subscription_title")} subtitle={t("subscription_subtitle")} />

      <div className="grid gap-5 md:grid-cols-3 md:items-start">
        {PLANS.map((plan) => (
          <PlanCard
            key={plan.id}
            plan={plan}
            current={plan.id === CURRENT_TIER}
            onChoose={() => setChosen(plan)}
          />
        ))}
      </div>

      <p className="mx-auto mt-6 max-w-md text-center text-xs text-ink-muted">
        {t("subscription_footnote")}
      </p>

      <Sheet
        open={chosen != null}
        onClose={() => setChosen(null)}
        title={t("plan_coming_soon_title")}
        footer={
          <Button fullWidth onClick={() => setChosen(null)}>
            {t("plan_coming_soon_ok")}
          </Button>
        }
      >
        <p className="text-ink-muted">
          {t("plan_coming_soon_body", { name: chosen ? t(chosen.nameKey) : "" })}
        </p>
      </Sheet>
    </div>
  );
}
