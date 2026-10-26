"use client";

import { useEffect, useRef, useState } from "react";
import { Camera, ImageIcon, X } from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Sheet } from "@/components/ui/Sheet";
import { Spinner } from "@/components/ui/Spinner";
import { TextField } from "@/components/ui/TextField";
import { VOCABULARY_LANGUAGES, languageByCode, type VocabularyLanguage } from "@/lib/data/languages";
import type { Deck, VocabularyWord } from "@/lib/data/models";
import { useScanController } from "@/lib/hooks/useScanController";
import { toast } from "@/lib/toast";
import { useGetDecksQuery } from "@/store/api/decksApi";
import { useAppDispatch } from "@/store/hooks";
import { resetScan, setImage, toggleSelectAll, toggleWord } from "@/store/slices/scanSlice";

export default function ScanPage() {
  const ctrl = useScanController();
  const dispatch = useAppDispatch();
  const { scan, t } = ctrl;

  // Reset the flow when leaving the page.
  useEffect(() => () => void dispatch(resetScan()), [dispatch]);

  const cameraInput = useRef<HTMLInputElement>(null);
  const galleryInput = useRef<HTMLInputElement>(null);

  function onFile(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) ctrl.onImagePicked(file);
    e.target.value = "";
  }

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col bg-paper">
      <header className="flex items-center justify-between px-5 py-4 safe-top">
        <h1 className="text-lg font-bold text-ink">{t("scan_source_title")}</h1>
        <button onClick={ctrl.requestClose} aria-label="Close" className="text-ink-muted">
          <X size={24} />
        </button>
      </header>

      <input ref={cameraInput} type="file" accept="image/*" capture="environment" hidden onChange={onFile} />
      <input ref={galleryInput} type="file" accept="image/*" hidden onChange={onFile} />

      <main className="flex flex-1 flex-col px-5 pb-6">
        {scan.stage === "pickingImage" && (
          <div className="flex flex-1 flex-col justify-center gap-3">
            <p className="mb-2 text-center text-ink-muted">{t("scan_source_subtitle")}</p>
            <Button variant="primary" size="lg" fullWidth onClick={() => cameraInput.current?.click()}>
              <Camera size={20} /> {t("scan_take_photo")}
            </Button>
            <Button variant="secondary" size="lg" fullWidth onClick={() => galleryInput.current?.click()}>
              <ImageIcon size={20} /> {t("scan_choose_from_gallery")}
            </Button>
          </div>
        )}

        {scan.stage === "reviewing" && scan.imageDataUrl && (
          <div className="flex flex-1 flex-col">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={scan.imageDataUrl} alt="Scan" className="min-h-0 flex-1 rounded-xl object-contain" />
            <div className="mt-4 flex gap-3">
              <Button variant="secondary" fullWidth onClick={() => dispatch(setImage(null))}>
                {t("scan_retake")}
              </Button>
              <Button variant="primary" fullWidth onClick={ctrl.confirmImage}>
                {t("scan_use_photo")}
              </Button>
            </div>
          </div>
        )}

        {(scan.stage === "processing" || scan.stage === "savingDeck") && (
          <div className="flex flex-1 flex-col items-center justify-center gap-4 text-ink-muted">
            <Spinner className="h-8 w-8 text-accent" />
            <p>{scan.stage === "processing" ? scan.processingLabel : scan.savingLabel}</p>
          </div>
        )}

        {scan.stage === "empty" && (
          <div className="flex flex-1 flex-col items-center justify-center gap-3 text-center">
            <p className="text-lg font-semibold text-ink">{t("scan_no_text_found_title")}</p>
            <p className="text-ink-muted">{t("scan_no_text_found_body")}</p>
            <Button variant="primary" className="mt-2" onClick={() => dispatch(setImage(null))}>
              {t("scan_try_again")}
            </Button>
          </div>
        )}

        {scan.stage === "wordSelection" && <WordSelection ctrl={ctrl} />}
      </main>
    </div>
  );
}

function WordSelection({ ctrl }: { ctrl: ReturnType<typeof useScanController> }) {
  const dispatch = useAppDispatch();
  const { scan, t, selectedWords, selectionSpansLanguages } = ctrl;
  const [destOpen, setDestOpen] = useState(false);

  // Group candidates by language (dominant first).
  const groups = groupByLanguage(scan.candidateWords, scan.sourceLanguageCode);
  const allSelected =
    scan.candidateWords.length > 0 &&
    scan.selectedKeys.length === scan.candidateWords.length;

  function openDestination() {
    if (selectionSpansLanguages) {
      toast.warning(t("scan_mixed_languages_warning"));
      return;
    }
    setDestOpen(true);
  }

  return (
    <div className="flex flex-1 flex-col">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="font-bold text-ink">{t("scan_select_words_title")}</h2>
          <p className="text-sm text-ink-muted">{t("scan_select_words_subtitle")}</p>
        </div>
        <button onClick={() => dispatch(toggleSelectAll())} className="whitespace-nowrap text-sm font-medium text-accent">
          {allSelected ? t("scan_deselect_all") : t("scan_select_all")}
        </button>
      </div>

      {scan.filedWordCount > 0 && (
        <p className="mt-2 text-sm text-confirm">{t("scan_filed_progress", { count: scan.filedWordCount })}</p>
      )}

      <div className="mt-4 flex-1 space-y-5 overflow-y-auto pb-28">
        {groups.map((group) => (
          <div key={group.code ?? "unknown"}>
            {groups.length > 1 && (
              <div className="mb-2 text-xs font-semibold uppercase tracking-wide text-ink-muted">
                {group.name ?? "—"}
              </div>
            )}
            <div className="flex flex-wrap gap-2">
              {group.words.map((w) => {
                const selected = scan.selectedKeys.includes(w.word.toLowerCase());
                return (
                  <button
                    key={w.word}
                    onClick={() => dispatch(toggleWord(w.word.toLowerCase()))}
                    className={`rounded-full border px-3.5 py-2 text-left transition ${
                      selected
                        ? "border-accent bg-accent/15 text-ink"
                        : "border-border bg-surface text-ink-muted"
                    }`}
                  >
                    <span className="font-medium text-ink">{w.word}</span>
                    {w.translation && <span className="ml-1.5 text-sm text-ink-muted">· {w.translation}</span>}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {/* Sticky action bar */}
      <div className="fixed inset-x-0 bottom-0 mx-auto max-w-md border-t border-border bg-paper/95 p-4 backdrop-blur safe-bottom">
        <div className="flex gap-3">
          <Button variant="secondary" onClick={ctrl.requestClose}>
            {t("scan_finish_button")}
          </Button>
          <Button variant="primary" fullWidth disabled={selectedWords.length === 0} onClick={openDestination}>
            {t("scan_selected_count", { count: selectedWords.length })}
          </Button>
        </div>
      </div>

      <DestinationSheet open={destOpen} onClose={() => setDestOpen(false)} ctrl={ctrl} />
    </div>
  );
}

function DestinationSheet({
  open,
  onClose,
  ctrl,
}: {
  open: boolean;
  onClose: () => void;
  ctrl: ReturnType<typeof useScanController>;
}) {
  const { t, selectedWords } = ctrl;
  const { data: decks = [] } = useGetDecksQuery(100);
  const [newDeck, setNewDeck] = useState(false);
  const [lang, setLang] = useState<VocabularyLanguage | null>(null);
  const [name, setName] = useState("");

  function chooseLang(l: VocabularyLanguage) {
    setLang(l);
    setName(ctrl.suggestedNameFor(l));
  }

  function create() {
    if (!lang || !name.trim()) return;
    onClose();
    setNewDeck(false);
    setLang(null);
    ctrl.fileToNewDeck(lang, name.trim());
  }

  function addExisting(deck: Deck) {
    onClose();
    ctrl.fileToExistingDeck(deck);
  }

  return (
    <Sheet open={open} onClose={onClose} title={t("scan_destination_title", { count: selectedWords.length })}>
      {!newDeck ? (
        <>
          <button
            onClick={() => setNewDeck(true)}
            className="mb-3 flex w-full items-center gap-3 rounded-lg border border-accent bg-accent/10 p-3.5 text-left"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-md bg-accent text-white">+</span>
            <span>
              <span className="block font-semibold text-ink">{t("scan_destination_new_deck")}</span>
              <span className="text-sm text-ink-muted">{t("scan_destination_new_deck_hint")}</span>
            </span>
          </button>
          {decks.length > 0 && (
            <>
              <div className="mb-2 text-xs font-semibold uppercase text-ink-muted">
                {t("scan_destination_existing_header")}
              </div>
              <div className="max-h-64 space-y-2 overflow-y-auto">
                {decks.map((deck) => (
                  <button
                    key={deck.id}
                    onClick={() => addExisting(deck)}
                    className="flex w-full items-center justify-between rounded-lg border border-border bg-surface p-3 text-left"
                  >
                    <span className="font-medium text-ink">{deck.name}</span>
                    <span className="text-sm text-ink-muted">
                      {languageByCode(deck.targetLanguage)?.flag} {deck.cardCount}
                    </span>
                  </button>
                ))}
              </div>
            </>
          )}
        </>
      ) : !lang ? (
        <>
          <p className="mb-3 text-sm text-ink-muted">{t("scan_target_language_body")}</p>
          <div className="max-h-72 space-y-1 overflow-y-auto">
            {VOCABULARY_LANGUAGES.map((l) => (
              <button
                key={l.code}
                onClick={() => chooseLang(l)}
                className="flex w-full items-center gap-3 rounded-lg p-2.5 text-left hover:bg-surface"
              >
                <span className="text-xl">{l.flag}</span>
                <span className="font-medium text-ink">{l.name}</span>
              </button>
            ))}
          </div>
        </>
      ) : (
        <div className="flex flex-col gap-4">
          <TextField label={t("deck_rename_title")} value={name} onChange={(e) => setName(e.target.value)} autoFocus />
          <Button variant="primary" fullWidth onClick={create}>
            {t("scan_destination_new_deck")}
          </Button>
        </div>
      )}
    </Sheet>
  );
}

function groupByLanguage(words: VocabularyWord[], dominant: string | null) {
  const byCode = new Map<string | null, VocabularyWord[]>();
  for (const w of words) {
    const arr = byCode.get(w.languageCode) ?? [];
    arr.push(w);
    byCode.set(w.languageCode, arr);
  }
  const codes = [...byCode.keys()].sort((a, b) => {
    if (a === b) return 0;
    if (a === dominant) return -1;
    if (b === dominant) return 1;
    if (a === null) return 1;
    if (b === null) return -1;
    return (languageByCode(a)?.name ?? a).localeCompare(languageByCode(b)?.name ?? b);
  });
  return codes.map((code) => ({
    code,
    name: code === null ? null : (languageByCode(code)?.name ?? code),
    words: byCode.get(code)!,
  }));
}
