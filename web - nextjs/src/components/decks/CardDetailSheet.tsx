"use client";

import { Pencil, Trash2, Volume2 } from "lucide-react";

import { Sheet } from "@/components/ui/Sheet";
import { useT } from "@/components/providers/I18nProvider";
import type { Flashcard } from "@/lib/data/models";
import { studyDaysBetween } from "@/lib/domain/studyDay";
import { speak } from "@/lib/services/tts";

export function CardDetailSheet({
  card,
  open,
  onClose,
  onEdit,
  onDelete,
}: {
  card: Flashcard | null;
  open: boolean;
  onClose: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const t = useT();
  if (!card) return null;

  const due = new Date(card.dueAt);
  const now = new Date();
  const days = studyDaysBetween(now, due);
  const nextReview =
    due.getTime() <= now.getTime() || days <= 0
      ? t("card_detail_next_review_today")
      : t("card_detail_next_review_in_days", { count: days });
  const reviewedLabel =
    card.lastReviewedAt == null
      ? t("card_detail_not_reviewed_yet")
      : card.repetitions === 1
        ? t("card_detail_reviewed_once")
        : t("card_detail_reviewed_times", { count: card.repetitions });

  return (
    <Sheet open={open} onClose={onClose}>
      <div className="flex items-start justify-between">
        <button
          onClick={() => speak(card.word, card.sourceLanguage)}
          className="flex items-center gap-2 text-2xl font-bold text-ink"
        >
          {card.word}
          <Volume2 size={20} className="text-ink-muted" />
        </button>
        {card.level && (
          <span className="rounded-full bg-surface px-2 py-0.5 text-xs font-semibold text-ink-muted">
            {card.level}
          </span>
        )}
      </div>

      <button
        onClick={() => speak(card.translation, card.targetLanguage)}
        className="mt-1 flex items-center gap-2 text-lg text-accent"
      >
        {card.translation}
        <Volume2 size={16} />
      </button>

      {card.wordDescription && (
        <div className="mt-4">
          <div className="mb-1 text-xs font-semibold uppercase text-ink-muted">
            {t("card_detail_meaning")}
          </div>
          <p className="text-ink">{card.wordDescription}</p>
        </div>
      )}

      {card.exampleSentences.length > 0 && (
        <div className="mt-4 space-y-2">
          {card.exampleSentences.map((s, i) => (
            <button
              key={i}
              onClick={() => speak(s, card.sourceLanguage)}
              className="flex w-full items-start gap-2 rounded-md bg-surface p-3 text-left text-sm text-ink"
            >
              <Volume2 size={16} className="mt-0.5 shrink-0 text-ink-muted" />
              {s}
            </button>
          ))}
        </div>
      )}

      <div className="mt-4 flex items-center justify-between rounded-md bg-surface px-3 py-2 text-sm text-ink-muted">
        <span>{reviewedLabel}</span>
        <span>{nextReview}</span>
      </div>

      <div className="mt-5 flex gap-3">
        <button
          onClick={onDelete}
          className="flex h-12 flex-1 items-center justify-center gap-2 rounded-md border border-border font-semibold text-error"
        >
          <Trash2 size={18} /> {t("card_delete_confirm")}
        </button>
        <button
          onClick={onEdit}
          className="flex h-12 flex-1 items-center justify-center gap-2 rounded-md bg-accent font-semibold text-white"
        >
          <Pencil size={18} /> {t("card_detail_edit")}
        </button>
      </div>
    </Sheet>
  );
}
