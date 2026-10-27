import { Pencil, Trash2, Volume2 } from "lucide-react";

import type { Flashcard } from "@/lib/data/models";
import { speak } from "@/lib/services/tts";
import { studyDaysBetween } from "@/lib/domain/studyDay";
import { Sheet } from "@/components/ui/Sheet";
import { Button } from "@/components/ui/Button";
import { useT } from "@/providers/I18nProvider";

function SpeakLine({
  text,
  lang,
  className,
}: {
  text: string;
  lang: string | null;
  className?: string;
}) {
  return (
    <button
      onClick={() => speak(text, lang)}
      className={`group inline-flex items-center gap-2 text-left ${className ?? ""}`}
    >
      <span>{text}</span>
      <Volume2 size={18} className="shrink-0 text-ink-muted transition-colors group-hover:text-coral" />
    </button>
  );
}

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

  const reviews = card.repetitions;
  const reviewedLabel =
    card.lastReviewedAt == null
      ? t("card_detail_not_reviewed_yet")
      : reviews === 1
        ? t("card_detail_reviewed_once")
        : t("card_detail_reviewed_times", { count: reviews });

  const daysToDue = studyDaysBetween(new Date(), new Date(card.dueAt));
  const nextLabel =
    daysToDue <= 0
      ? t("card_detail_next_review_today")
      : t("card_detail_next_review_in_days", { count: daysToDue });

  return (
    <Sheet open={open} onClose={onClose} size="md">
      <div className="space-y-5">
        <div className="text-center">
          <SpeakLine
            text={card.word}
            lang={card.sourceLanguage}
            className="justify-center font-display text-3xl font-extrabold text-ink"
          />
          {card.level && (
            <span className="mt-2 inline-block rounded-full bg-coral-soft px-3 py-0.5 text-xs font-bold text-coral">
              {card.level}
            </span>
          )}
          <SpeakLine
            text={card.translation}
            lang={card.targetLanguage}
            className="mt-2 justify-center text-lg font-semibold text-ink-muted"
          />
        </div>

        {card.wordDescription && (
          <div className="rounded-2xl bg-surface p-4">
            <p className="mb-1 text-xs font-bold uppercase tracking-wide text-ink-muted">
              {t("card_detail_meaning")}
            </p>
            <p className="text-[15px] text-ink">{card.wordDescription}</p>
          </div>
        )}

        {card.exampleSentences.length > 0 && (
          <div className="space-y-2">
            {card.exampleSentences.map((s, i) => (
              <div key={i} className="rounded-2xl border border-border p-3">
                <SpeakLine text={s} lang={card.sourceLanguage} className="text-[15px] text-ink" />
              </div>
            ))}
          </div>
        )}

        <div className="flex items-center justify-between rounded-2xl bg-surface px-4 py-3 text-sm">
          <span className="font-medium text-ink-muted">{reviewedLabel}</span>
          <span className="font-semibold text-ink">{nextLabel}</span>
        </div>

        <div className="flex gap-3">
          <Button variant="secondary" fullWidth leftIcon={<Pencil size={18} />} onClick={onEdit}>
            {t("card_detail_edit")}
          </Button>
          <Button variant="danger" leftIcon={<Trash2 size={18} />} onClick={onDelete}>
            {t("card_delete_confirm")}
          </Button>
        </div>
      </div>
    </Sheet>
  );
}
