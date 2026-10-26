"use client";

import { useEffect, useState } from "react";
import { Plus, Trash2 } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Sheet } from "@/components/ui/Sheet";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import type { Flashcard } from "@/lib/data/models";
import { toast } from "@/lib/toast";
import { useUpdateFlashcardMutation } from "@/store/api/decksApi";

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

  useEffect(() => {
    if (card) {
      setWord(card.word);
      setTranslation(card.translation);
      setDescription(card.wordDescription ?? "");
      setExamples(card.exampleSentences.length ? card.exampleSentences : [""]);
    }
  }, [card]);

  if (!card) return null;

  async function save() {
    if (!word.trim() || !translation.trim()) return;
    try {
      await update({
        flashcardId: card!.id,
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
    <Sheet open={open} onClose={onClose} title={t("card_edit_title")}>
      <div className="max-h-[70vh] space-y-4 overflow-y-auto pb-2">
        <TextField label={t("card_edit_word")} value={word} onChange={(e) => setWord(e.target.value)} />
        <TextField
          label={t("card_edit_translation")}
          value={translation}
          onChange={(e) => setTranslation(e.target.value)}
        />
        <TextField
          label={t("card_edit_description")}
          placeholder={t("card_edit_description_hint")}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
        <div>
          <div className="mb-1.5 text-sm font-medium text-ink-muted">{t("card_edit_examples")}</div>
          <div className="space-y-2">
            {examples.map((ex, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  value={ex}
                  placeholder={t("card_edit_example_hint")}
                  onChange={(e) =>
                    setExamples((prev) => prev.map((v, j) => (j === i ? e.target.value : v)))
                  }
                  className="h-11 flex-1 rounded-md border border-border bg-surface px-3 text-ink outline-none focus:border-accent"
                />
                <button
                  onClick={() => setExamples((prev) => prev.filter((_, j) => j !== i))}
                  className="text-ink-muted"
                  aria-label="Remove"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            ))}
          </div>
          <button
            onClick={() => setExamples((prev) => [...prev, ""])}
            className="mt-2 flex items-center gap-1.5 text-sm font-medium text-accent"
          >
            <Plus size={16} /> {t("card_edit_add_example")}
          </button>
        </div>
      </div>
      <Button variant="primary" fullWidth loading={isLoading} onClick={save} className="mt-4">
        {t("common_save")}
      </Button>
    </Sheet>
  );
}
