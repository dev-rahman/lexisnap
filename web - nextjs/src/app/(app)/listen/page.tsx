"use client";

import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";

import { ListenSessionView } from "@/components/study/ListenSessionView";
import { Spinner } from "@/components/ui/Spinner";
import type { Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { DUE_QUEUE_LIMIT } from "@/store/api/decksApi";

export default function ListenPage() {
  const params = useSearchParams();
  const mode = params.get("mode");
  const deckId = params.get("deck");
  const [cards, setCards] = useState<Flashcard[] | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        let result: Flashcard[];
        if (deckId) result = (await repo.getDeck(deckId)).flashcards;
        else if (mode === "practice") result = await repo.listUpcomingFlashcards(20);
        else result = await repo.listDueFlashcards(DUE_QUEUE_LIMIT);
        if (active) setCards(result);
      } catch {
        if (active) setCards([]);
      }
    })();
    return () => {
      active = false;
    };
  }, [deckId, mode]);

  if (!cards) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-paper">
        <Spinner className="text-accent" />
      </div>
    );
  }
  if (cards.length === 0) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-paper text-ink-muted">
        No cards to play.
      </div>
    );
  }
  return <ListenSessionView cards={cards} />;
}
