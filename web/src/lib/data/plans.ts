import type { MessageKey } from "@/lib/i18n";

/** The three subscription tiers. Mirrors the server-side caps in the Groq edge
 *  functions (extract-vocabulary / translate-words). */
export type Tier = "free" | "plus" | "pro";

/**
 * The user's active tier. Billing isn't wired up yet, so everyone is "free" —
 * this deliberately mirrors `tierFor()` in the edge functions. When real
 * subscriptions land (RevenueCat / Stripe), resolve this from the user's
 * entitlements instead of hardcoding it here.
 */
export const CURRENT_TIER: Tier = "free";

export type Accent = "sky" | "coral" | "violet";

export interface PlanFeature {
  key: MessageKey;
  /** Interpolated into the feature copy (e.g. "{count} scans a day"). */
  count?: number;
}

export interface Plan {
  id: Tier;
  /** Monthly price in EUR (0 = free). */
  priceEur: number;
  accent: Accent;
  /** The headline tier, drawn with extra emphasis. */
  highlight?: boolean;
  scansPerDay: number;
  translationsPerDay: number;
  nameKey: MessageKey;
  taglineKey: MessageKey;
  features: PlanFeature[];
}

export const PLANS: Plan[] = [
  {
    id: "free",
    priceEur: 0,
    accent: "sky",
    scansPerDay: 5,
    translationsPerDay: 20,
    nameKey: "plan_free_name",
    taglineKey: "plan_free_tagline",
    features: [
      { key: "plan_feature_scans", count: 5 },
      { key: "plan_feature_translations", count: 20 },
      { key: "plan_feature_decks" },
      { key: "plan_feature_study" },
      { key: "plan_feature_local" },
    ],
  },
  {
    id: "plus",
    priceEur: 2,
    accent: "coral",
    scansPerDay: 40,
    translationsPerDay: 200,
    nameKey: "plan_plus_name",
    taglineKey: "plan_plus_tagline",
    features: [
      { key: "plan_feature_scans", count: 40 },
      { key: "plan_feature_translations", count: 200 },
      { key: "plan_feature_decks" },
      { key: "plan_feature_study" },
      { key: "plan_feature_listen" },
    ],
  },
  {
    id: "pro",
    priceEur: 4,
    accent: "violet",
    highlight: true,
    scansPerDay: 150,
    translationsPerDay: 800,
    nameKey: "plan_pro_name",
    taglineKey: "plan_pro_tagline",
    features: [
      { key: "plan_feature_scans", count: 150 },
      { key: "plan_feature_translations", count: 800 },
      { key: "plan_feature_decks" },
      { key: "plan_feature_study" },
      { key: "plan_feature_listen" },
      { key: "plan_feature_support" },
      { key: "plan_feature_early" },
    ],
  },
];

export const planById = (id: Tier): Plan =>
  PLANS.find((p) => p.id === id) ?? PLANS[0];
