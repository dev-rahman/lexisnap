import { useState } from "react";
import { Plus, X } from "lucide-react";

import type { Flashcard } from "@/lib/data/models";
import { Sheet } from "@/components/ui/Sheet";
import { Button } from "@/components/ui/Button";
import { TextField } from "@/components/ui/TextField";
import { useUpdateFlashcardMutation } from "@/store/api/decksApi";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";

export function CardEditSheet({
  card,
  deckId,
  open,
  onClose,
}: {
  card: Flashcard | null;
  deckId: string;
  open: boolean;
  onClose: () => void;
}) {
  const t = useT();
  const [update, { isLoading }] = useUpdateFlashcardMutation();

  const [word, setWord] = useState("");
  const [translation, setTranslation] = useState("");
  const [description, setDescription] = useState("");
  const [examples, setExamples] = useState<string[]>([]);
  const [hydratedId, setHydratedId] = useState<string | null>(null);

  // Hydrate fields when a new card opens.
  if (card && card.id !== hydratedId) {
    setHydratedId(card.id);
    setWord(card.word);
    setTranslation(card.translation);
    setDescription(card.wordDescription ?? "");
    setExamples(card.exampleSentences.length ? card.exampleSentences : [""]);
  }

  if (!card) return null;

  async function onSave() {
    if (!card) return;
    try {
      await update({
        flashcardId: card.id,
        deckId,
        word: word.trim(),
        translation: translation.trim(),
        wordDescription: description.trim() || null,
        exampleSentences: examples.map((e) => e.trim()).filter(Boolean),
      }).unwrap();
      toast.success(t("card_edit_saved_success"));
      onClose();
    } catch {
      toast.error(t("card_edit_save_error"));
    }
  }

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title={t("card_edit_title")}
      size="md"
      footer={
        <Button
          fullWidth
          onClick={onSave}
          loading={isLoading}
          disabled={!word.trim() || !translation.trim()}
        >
          {t("common_save")}
        </Button>
      }
    >
      <div className="space-y-4">
        <TextField
          label={t("card_edit_word")}
          value={word}
          onChange={(e) => setWord(e.target.value)}
        />
        <TextField
          label={t("card_edit_translation")}
          value={translation}
          onChange={(e) => setTranslation(e.target.value)}
        />
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-ink-soft">
            {t("card_edit_description")}
          </label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder={t("card_edit_description_hint")}
            rows={2}
            className="w-full resize-none rounded-2xl border-2 border-border bg-card px-4 py-3 text-[15px] text-ink placeholder:text-ink-muted/70 focus:border-coral focus:outline-none focus:ring-4 focus:ring-coral/15"
          />
        </div>
        <div>
          <label className="mb-1.5 block text-sm font-semibold text-ink-soft">
            {t("card_edit_examples")}
          </label>
          <div className="space-y-2">
            {examples.map((ex, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  value={ex}
                  onChange={(e) =>
                    setExamples((prev) => prev.map((p, j) => (j === i ? e.target.value : p)))
                  }
                  placeholder={t("card_edit_example_hint")}
                  className="h-11 flex-1 rounded-xl border-2 border-border bg-card px-3 text-[15px] text-ink focus:border-coral focus:outline-none"
                />
                <button
                  onClick={() => setExamples((prev) => prev.filter((_, j) => j !== i))}
                  className="grid h-9 w-9 shrink-0 place-items-center rounded-lg text-ink-muted hover:bg-error/10 hover:text-error"
                >
                  <X size={18} />
                </button>
              </div>
            ))}
          </div>
          <button
            onClick={() => setExamples((prev) => [...prev, ""])}
            className="mt-2 flex items-center gap-1.5 text-sm font-bold text-coral"
          >
            <Plus size={16} /> {t("card_edit_add_example")}
          </button>
        </div>
      </div>
    </Sheet>
  );
}
