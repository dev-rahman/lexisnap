import { useState } from "react";
import { Copy, Pencil, Share2, Sparkles, Trash2, Volume2, X } from "lucide-react";

import type { Flashcard } from "@/lib/data/models";
import { languageByCode } from "@/lib/data/languages";
import { speak } from "@/lib/services/tts";
import { generateExampleSentence, QuotaExceededError } from "@/lib/services/vocabulary";
import { Sheet } from "@/components/ui/Sheet";
import { Button } from "@/components/ui/Button";
import { useUpdateFlashcardMutation } from "@/store/api/decksApi";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { cn } from "@/lib/utils/cn";

/** A small round speaker that reads its text aloud. */
function SpeakButton({
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
      type="button"
      aria-label="Listen"
      onClick={() => speak(text, lang)}
      className={cn(
        "grid h-9 w-9 shrink-0 place-items-center rounded-full bg-ink/5 text-ink-muted transition-colors hover:bg-coral/15 hover:text-coral",
        className,
      )}
    >
      <Volume2 size={18} />
    </button>
  );
}

function IconButton({
  label,
  onClick,
  children,
}: {
  label: string;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      title={label}
      onClick={onClick}
      className="grid h-9 w-9 place-items-center rounded-full text-ink-muted transition-colors hover:bg-ink/5 hover:text-ink"
    >
      {children}
    </button>
  );
}

export function CardDetailSheet({
  card,
  deckId,
  open,
  onClose,
  onEdit,
  onDelete,
}: {
  card: Flashcard | null;
  deckId: string;
  open: boolean;
  onClose: () => void;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const t = useT();
  const [update] = useUpdateFlashcardMutation();
  const [examples, setExamples] = useState<string[]>([]);
  const [seenId, setSeenId] = useState<string | null>(null);
  const [generating, setGenerating] = useState(false);

  // Keep a local copy of the examples so a freshly generated one shows at once.
  if (card && card.id !== seenId) {
    setSeenId(card.id);
    setExamples(card.exampleSentences);
  }

  if (!card) return null;

  const canShare = typeof navigator !== "undefined" && typeof navigator.share === "function";

  async function onCopy() {
    if (!card) return;
    const parts = [`${card.word} — ${card.translation}`];
    if (card.wordDescription) parts.push(card.wordDescription);
    try {
      await navigator.clipboard.writeText(parts.join("\n"));
      toast.success(t("card_detail_copied"));
    } catch {
      /* clipboard blocked — ignore */
    }
  }

  async function onShare() {
    if (!card) return;
    try {
      await navigator.share({ title: card.word, text: `${card.word} — ${card.translation}` });
    } catch {
      /* cancelled or unsupported — ignore */
    }
  }

  async function onGenerate() {
    if (!card || generating) return;
    setGenerating(true);
    try {
      const sentence = await generateExampleSentence({
        word: card.word,
        language: languageByCode(card.sourceLanguage)?.name ?? null,
        level: card.level,
      });
      const next = [...examples, sentence];
      await update({
        flashcardId: card.id,
        deckId,
        word: card.word,
        translation: card.translation,
        wordDescription: card.wordDescription,
        exampleSentences: next,
      }).unwrap();
      setExamples(next);
      toast.success(t("card_detail_example_added"));
    } catch (err) {
      if (err instanceof QuotaExceededError) {
        toast.warning(t("card_detail_example_limit"));
      } else {
        toast.error(t("card_detail_example_error"));
      }
    } finally {
      setGenerating(false);
    }
  }

  return (
    <Sheet
      open={open}
      onClose={onClose}
      size="md"
      footer={
        <div className="flex gap-3">
          <Button variant="secondary" fullWidth leftIcon={<Pencil size={18} />} onClick={onEdit}>
            {t("card_detail_edit")}
          </Button>
          <Button
            variant="danger"
            aria-label={t("card_delete_confirm")}
            leftIcon={<Trash2 size={18} />}
            onClick={onDelete}
          />
        </div>
      }
    >
      <div className="space-y-5">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1">
            <IconButton label={t("card_detail_copy")} onClick={onCopy}>
              <Copy size={18} />
            </IconButton>
            {canShare && (
              <IconButton label={t("card_detail_share")} onClick={onShare}>
                <Share2 size={18} />
              </IconButton>
            )}
          </div>
          <IconButton label="Close" onClick={onClose}>
            <X size={20} />
          </IconButton>
        </div>

        {/* Word + translation */}
        <div className="rounded-3xl bg-gradient-to-br from-coral-soft to-surface p-6 text-center">
          {card.level && (
            <span className="mb-2 inline-block rounded-full bg-coral/15 px-3 py-0.5 text-xs font-bold text-coral">
              {card.level}
            </span>
          )}
          <div className="flex items-center justify-center gap-2.5">
            <p className="text-balance font-display text-3xl font-bold text-ink">{card.word}</p>
            <SpeakButton text={card.word} lang={card.sourceLanguage} />
          </div>
          <div className="mt-2 flex items-center justify-center gap-2.5">
            <p className="text-balance text-lg font-semibold text-ink-muted">{card.translation}</p>
            <SpeakButton text={card.translation} lang={card.targetLanguage} />
          </div>
        </div>

        {/* Meaning */}
        {card.wordDescription && (
          <div className="rounded-2xl bg-surface p-4">
            <p className="mb-1 text-xs font-semibold text-ink-muted">{t("card_detail_meaning")}</p>
            <p className="text-[15px] text-ink">{card.wordDescription}</p>
          </div>
        )}

        {/* Examples */}
        <div className="space-y-2">
          {examples.length > 0 && (
            <>
              <p className="text-xs font-semibold text-ink-muted">
                {t("card_detail_examples_title")}
              </p>
              {examples.map((s, i) => (
                <div
                  key={i}
                  className="flex items-center justify-between gap-2 rounded-2xl border border-border p-3"
                >
                  <p className="text-[15px] text-ink">{s}</p>
                  <SpeakButton text={s} lang={card.sourceLanguage} />
                </div>
              ))}
            </>
          )}
          <Button
            variant="secondary"
            fullWidth
            loading={generating}
            leftIcon={<Sparkles size={18} />}
            onClick={onGenerate}
          >
            {t("card_detail_generate_example")}
          </Button>
        </div>
      </div>
    </Sheet>
  );
}
