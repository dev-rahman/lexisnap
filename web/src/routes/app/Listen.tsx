import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

import { ListenSessionView } from "@/components/study/ListenSessionView";
import { Button } from "@/components/ui/Button";
import { EmptyState } from "@/components/ui/EmptyState";
import { FullPageSpinner } from "@/components/ui/Spinner";
import type { Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repo";
import { useT } from "@/providers/I18nProvider";

export function Listen() {
  const t = useT();
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const deckId = params.get("deck");
  const [cards, setCards] = useState<Flashcard[] | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const list = deckId
          ? (await repo.getDeck(deckId)).flashcards
          : await repo.listDueFlashcards(200);
        if (!cancelled) setCards(list);
      } catch {
        if (!cancelled) setCards([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [deckId]);

  if (cards === null) return <FullPageSpinner />;
  if (cards.length === 0) {
    return (
      <div className="flex min-h-dvh flex-col items-center justify-center bg-paper px-6">
        <EmptyState
          emoji="🎧"
          title={t("study_nothing_due_title")}
          action={<Button onClick={() => navigate(-1)}>{t("study_done")}</Button>}
        />
      </div>
    );
  }

  return <ListenSessionView cards={cards} />;
}
