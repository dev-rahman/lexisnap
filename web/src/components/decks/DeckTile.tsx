import { Link } from "react-router-dom";

import type { Deck } from "@/lib/data/models";
import { hueFor } from "@/lib/domain/deckHue";
import { languageByCode } from "@/lib/data/languages";
import { Card } from "@/components/ui/Card";
import { IconTile } from "@/components/ui/IconTile";
import { Skeleton } from "@/components/ui/Skeleton";
import { useT } from "@/providers/I18nProvider";

export function DeckTile({ deck }: { deck: Deck }) {
  const t = useT();
  const hue = hueFor(deck.id);
  const source = languageByCode(deck.sourceLanguage);
  const target = languageByCode(deck.targetLanguage);

  return (
    <Link to={`/deck/${deck.id}`} className="block">
      <Card interactive className="flex h-full flex-col gap-3 p-4">
        <div className="flex items-center justify-between">
          <IconTile hue={hue} solid size="md">
            {deck.name.trim().charAt(0).toUpperCase() || "?"}
          </IconTile>
          <span className="flex items-center gap-1 text-lg">
            {source?.flag ?? "📄"}
            <span className="text-sm text-ink-muted">→</span>
            {target?.flag ?? "🏳️"}
          </span>
        </div>
        <div className="mt-1">
          <h3 className="line-clamp-2 font-display text-base font-bold leading-snug text-ink">
            {deck.name}
          </h3>
          <p className="mt-0.5 text-sm text-ink-muted">
            {t("home_deck_card_count", { count: deck.cardCount })}
          </p>
        </div>
      </Card>
    </Link>
  );
}

export function DeckTileSkeleton() {
  return <Skeleton className="h-[128px]" />;
}
