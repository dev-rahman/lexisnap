import { useCallback } from "react";
import { useNavigate } from "react-router-dom";

import { languageByCode, type VocabularyLanguage } from "@/lib/data/languages";
import type { Deck, DeckWord, VocabularyWord } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { extractVocabulary as regexExtract } from "@/lib/domain/vocabularyExtractor";
import { recognizeText } from "@/lib/services/ocr";
import {
  extractVocabulary,
  QuotaExceededError,
  translateWords,
} from "@/lib/services/vocabulary";
import { toast } from "@/lib/toast";
import { translate, type MessageKey } from "@/lib/i18n";
import { decksApi } from "@/store/api/decksApi";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import {
  patchCandidates,
  recordBatch,
  resetScan,
  setCandidates,
  setImage,
  setProcessingLabel,
  setSavingLabel,
  setStage,
} from "@/store/slices/scanSlice";

/**
 * Orchestrates the scan pipeline — the web port of ScanController. All the
 * side effects (file read, OCR, edge-function calls, saving) live here; the
 * scan page stays presentational and reads scanSlice state.
 */
export function useScanController() {
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const scan = useAppSelector((s) => s.scan);
  const locale = useAppSelector((s) => s.prefs.locale);

  const t = useCallback(
    (key: MessageKey, params?: Record<string, string | number>) =>
      translate(locale, key, params),
    [locale],
  );

  const uiLanguage = languageByCode(locale)?.name ?? "English";

  const selectedWords = scan.candidateWords.filter((w) =>
    scan.selectedKeys.includes(w.word.toLowerCase()),
  );
  const selectedSourceCode = (() => {
    const codes = new Set(selectedWords.map((w) => w.languageCode));
    return codes.size === 1 ? [...codes][0] : null;
  })();
  const selectionSpansLanguages =
    new Set(selectedWords.map((w) => w.languageCode)).size > 1;

  /** Reads a picked file to a data URL and moves to the review stage. */
  const onImagePicked = useCallback(
    (file: File) => {
      const reader = new FileReader();
      reader.onload = () => dispatch(setImage(reader.result as string));
      reader.readAsDataURL(file);
    },
    [dispatch],
  );

  const confirmImage = useCallback(async () => {
    const image = scan.imageDataUrl;
    if (!image) return;
    dispatch(setStage("processing"));
    dispatch(setProcessingLabel(t("scan_reading_text")));
    try {
      const text = await recognizeText(image);
      if (!text.trim()) {
        dispatch(setStage("empty"));
        return;
      }

      let words: VocabularyWord[] = [];
      let code: string | null = null;
      let name: string | null = null;
      let suggested: string | null = null;
      try {
        const result = await extractVocabulary(text, uiLanguage);
        words = result.words;
        code = result.sourceLanguageCode;
        name = result.sourceLanguageName;
        suggested = result.suggestedDeckName;
      } catch (err) {
        // Daily AI scan cap hit — tell the user, then still give them the
        // local regex extraction so the scan isn't a dead end. Any other
        // error (offline / API) degrades the same way, silently.
        if (err instanceof QuotaExceededError) {
          toast.warning(t("scan_limit_reached"));
        }
        words = regexExtract(text).map((w) => ({
          word: w,
          level: null,
          wordDescription: null,
          exampleSentence: null,
          translation: null,
          languageCode: null,
        }));
      }

      if (words.length === 0) {
        dispatch(setStage("empty"));
        return;
      }

      dispatch(
        setCandidates({
          words,
          sourceLanguageCode: code,
          sourceLanguageName: name,
          suggestedDeckName: suggested,
        }),
      );

      // Fill any missing glosses before showing the list, so it looks complete.
      if (words.some((w) => !(w.translation ?? "").trim())) {
        dispatch(setProcessingLabel(t("scan_translating_text")));
        try {
          const missing = words.filter((w) => !(w.translation ?? "").trim());
          const map = await translateWords({
            words: missing.map((w) => w.word),
            sourceLanguage: code,
            targetLanguage: uiLanguage,
          });
          dispatch(
            patchCandidates(
              words.map((w) =>
                !(w.translation ?? "").trim() && map[w.word]
                  ? { ...w, translation: map[w.word] }
                  : w,
              ),
            ),
          );
        } catch (err) {
          // Daily translate cap hit — let the user know; otherwise leave the
          // words untranslated (the chip just shows the word alone).
          if (err instanceof QuotaExceededError) {
            toast.warning(t("translate_limit_reached"));
          }
        }
      }

      dispatch(setStage("wordSelection"));
    } catch {
      toast.error(t("scan_processing_error"));
      dispatch(setStage("reviewing"));
    }
  }, [scan.imageDataUrl, uiLanguage, dispatch, t]);

  async function translateSelection(
    selected: VocabularyWord[],
    targetLanguageName: string,
  ): Promise<DeckWord[]> {
    const sourceCode = selected[0]?.languageCode ?? null;
    const map = await translateWords({
      words: selected.map((w) => w.word),
      sourceLanguage: sourceCode,
      targetLanguage: targetLanguageName,
    });
    const deckWords: DeckWord[] = selected
      .map((w) => ({
        word: w.word,
        level: w.level,
        wordDescription: w.wordDescription,
        exampleSentence: w.exampleSentence,
        translation: map[w.word] ?? "",
      }))
      .filter((w) => w.translation.length > 0);
    if (deckWords.length === 0) throw new Error("No translations returned");
    return deckWords;
  }

  function invalidate() {
    dispatch(
      decksApi.util.invalidateTags([
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
      ]),
    );
  }

  function finishIfDone(remainingAfter: number) {
    if (remainingAfter === 0) {
      invalidate();
      summarize();
      dispatch(resetScan());
      navigate("/decks");
    } else {
      dispatch(setStage("wordSelection"));
    }
  }

  function summarize() {
    const filed = scan.filed;
    const total = scan.filedWordCount;
    if (filed.length === 0 && total === 0) return;
    toast.success(
      t("scan_words_saved_summary", {
        count: total,
        decks: new Set(filed.map((f) => f.name)).size || 1,
      }),
    );
  }

  const fileToNewDeck = useCallback(
    async (target: VocabularyLanguage, name: string) => {
      const selected = selectedWords;
      if (selected.length === 0) return;
      dispatch(setSavingLabel(t("scan_saving_deck")));
      dispatch(setStage("savingDeck"));
      try {
        const sourceCode = selected[0].languageCode;
        const deckWords = await translateSelection(selected, target.name);
        await repo.createDeck({
          name,
          sourceLanguage: sourceCode,
          targetLanguage: target.code,
          words: deckWords,
        });
        const filedKeys = selected.map((w) => w.word.toLowerCase());
        dispatch(
          recordBatch({
            batch: { name, count: deckWords.length, isNew: true },
            filedKeys,
          }),
        );
        finishIfDone(scan.candidateWords.length - selected.length);
      } catch (err) {
        toast.error(
          err instanceof QuotaExceededError
            ? t("translate_limit_reached")
            : t("scan_deck_save_error"),
        );
        dispatch(setStage("wordSelection"));
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [selectedWords, dispatch, t],
  );

  const fileToExistingDeck = useCallback(
    async (deck: Deck) => {
      const selected = selectedWords;
      if (selected.length === 0) return;
      dispatch(setSavingLabel(t("scan_saving_words")));
      dispatch(setStage("savingDeck"));
      try {
        const existing = await repo.wordsInDeck(deck.id);
        const fresh = selected.filter((w) => !existing.has(w.word.toLowerCase()));
        if (fresh.length === 0) {
          toast.warning(t("cards_all_present", { name: deck.name }));
          dispatch(setStage("wordSelection"));
          return;
        }
        const targetName = languageByCode(deck.targetLanguage)?.name ?? deck.targetLanguage;
        const deckWords = await translateSelection(fresh, targetName);
        await repo.addWordsToDeck({ deckId: deck.id, words: deckWords });
        const filedKeys = fresh.map((w) => w.word.toLowerCase());
        dispatch(
          recordBatch({
            batch: { name: deck.name, count: deckWords.length, isNew: false },
            filedKeys,
          }),
        );
        finishIfDone(scan.candidateWords.length - fresh.length);
      } catch (err) {
        toast.error(
          err instanceof QuotaExceededError
            ? t("translate_limit_reached")
            : t("scan_deck_save_error"),
        );
        dispatch(setStage("wordSelection"));
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [selectedWords, dispatch, t],
  );

  function suggestedNameFor(target: VocabularyLanguage): string {
    if (scan.suggestedDeckName) return scan.suggestedDeckName;
    const sourceName =
      languageByCode(selectedSourceCode)?.name ??
      scan.sourceLanguageName ??
      "Scan";
    return `${sourceName} → ${target.name}`;
  }

  function requestClose() {
    if (scan.filedWordCount > 0) {
      invalidate();
      summarize();
      dispatch(resetScan());
      navigate("/decks");
    } else {
      dispatch(resetScan());
      navigate(-1);
    }
  }

  return {
    scan,
    t,
    selectedWords,
    selectedSourceCode,
    selectionSpansLanguages,
    onImagePicked,
    confirmImage,
    fileToNewDeck,
    fileToExistingDeck,
    suggestedNameFor,
    requestClose,
  };
}
