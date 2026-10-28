import { useRef, useState } from "react";
import {
  Camera,
  Check,
  ChevronRight,
  ImageIcon,
  Layers,
  Plus,
  RotateCcw,
  X,
} from "lucide-react";

import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { EmptyState } from "@/components/ui/EmptyState";
import { IconTile } from "@/components/ui/IconTile";
import { BrandLoader } from "@/components/brand/BrandLoader";
import { TextField } from "@/components/ui/TextField";
import { BrandMark } from "@/components/brand/BrandMark";
import { VOCABULARY_LANGUAGES, languageByCode, type VocabularyLanguage } from "@/lib/data/languages";
import { hueFor } from "@/lib/domain/deckHue";
import { useScanController } from "@/lib/hooks/useScanController";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch, useAppSelector } from "@/store/hooks";
import { useGetDecksQuery } from "@/store/api/decksApi";
import {
  toggleSelectAll,
  toggleSelectAllInLanguage,
  toggleWord,
} from "@/store/slices/scanSlice";
import { cn } from "@/lib/utils/cn";

export function Scan() {
  const t = useT();
  const dispatch = useAppDispatch();
  const ctrl = useScanController();
  const { scan } = ctrl;

  const cameraRef = useRef<HTMLInputElement>(null);
  const galleryRef = useRef<HTMLInputElement>(null);
  const [destination, setDestination] = useState<"none" | "choose" | "new">("none");

  return (
    <div className="app-wash flex min-h-dvh flex-col bg-paper safe-top">
      {/* Top bar */}
      <div className="flex items-center justify-between px-4 py-3">
        <BrandMark size="sm" showWord={false} />
        <button
          onClick={ctrl.requestClose}
          aria-label={t("common_cancel")}
          className="grid h-10 w-10 place-items-center rounded-full border border-border bg-card text-ink-soft hover:bg-ink/5"
        >
          <X size={20} />
        </button>
      </div>

      <div className="mx-auto flex w-full max-w-focus flex-1 flex-col px-4 pb-8">
        {/* pickingImage */}
        {scan.stage === "pickingImage" && (
          <div className="flex flex-1 flex-col justify-center">
            <div className="mb-8 text-center">
              <div className="mx-auto mb-5 grid h-20 w-20 place-items-center rounded-3xl bg-coral-soft text-5xl">
                📸
              </div>
              <h1 className="font-display text-2xl font-bold text-ink">
                {t("scan_source_title")}
              </h1>
              <p className="mt-1 text-ink-muted">{t("scan_source_subtitle")}</p>
            </div>
            <div className="space-y-3">
              <Button
                fullWidth
                size="lg"
                leftIcon={<Camera size={22} />}
                onClick={() => cameraRef.current?.click()}
              >
                {t("scan_take_photo")}
              </Button>
              <Button
                fullWidth
                size="lg"
                variant="secondary"
                leftIcon={<ImageIcon size={22} />}
                onClick={() => galleryRef.current?.click()}
              >
                {t("scan_choose_from_gallery")}
              </Button>
            </div>
            <input
              ref={cameraRef}
              type="file"
              accept="image/*"
              capture="environment"
              className="hidden"
              onChange={(e) => e.target.files?.[0] && ctrl.onImagePicked(e.target.files[0])}
            />
            <input
              ref={galleryRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={(e) => e.target.files?.[0] && ctrl.onImagePicked(e.target.files[0])}
            />
          </div>
        )}

        {/* reviewing */}
        {scan.stage === "reviewing" && scan.imageDataUrl && (
          <div className="flex flex-1 flex-col">
            <div className="flex flex-1 items-center justify-center py-4">
              <img
                src={scan.imageDataUrl}
                alt=""
                className="max-h-[55vh] w-full rounded-3xl border border-border object-contain shadow-card"
              />
            </div>
            <div className="flex gap-3">
              <Button
                variant="secondary"
                fullWidth
                leftIcon={<RotateCcw size={20} />}
                onClick={() => cameraRef.current?.click() ?? galleryRef.current?.click()}
              >
                {t("scan_retake")}
              </Button>
              <Button fullWidth leftIcon={<Check size={20} />} onClick={ctrl.confirmImage}>
                {t("scan_use_photo")}
              </Button>
            </div>
          </div>
        )}

        {/* processing / savingDeck */}
        {(scan.stage === "processing" || scan.stage === "savingDeck") && (
          <div className="flex flex-1 flex-col items-center justify-center gap-5 text-center">
            <BrandLoader size={60} showWord={false} />
            <p className="font-display text-lg font-bold text-ink">
              {scan.processingLabel ?? scan.savingLabel ?? t("scan_reading_text")}
            </p>
          </div>
        )}

        {/* empty */}
        {scan.stage === "empty" && (
          <div className="flex flex-1 flex-col justify-center">
            <EmptyState
              emoji="🔍"
              title={t("scan_no_text_found_title")}
              description={t("scan_no_text_found_body")}
              action={
                <Button onClick={ctrl.requestClose} leftIcon={<RotateCcw size={18} />}>
                  {t("scan_try_again")}
                </Button>
              }
            />
          </div>
        )}

        {/* wordSelection */}
        {scan.stage === "wordSelection" &&
          (destination === "none" ? (
            <WordSelection
              onContinue={() => setDestination("choose")}
            />
          ) : destination === "choose" ? (
            <DestinationChooser
              onNew={() => setDestination("new")}
              onPickedExisting={() => setDestination("none")}
              onBack={() => setDestination("none")}
            />
          ) : (
            <NewDeckForm onDone={() => setDestination("none")} onBack={() => setDestination("choose")} />
          ))}
      </div>
    </div>
  );

  function WordSelection({ onContinue }: { onContinue: () => void }) {
    const groups = groupByLanguage(scan.candidateWords);
    const allSelected =
      scan.candidateWords.length > 0 &&
      scan.selectedKeys.length === scan.candidateWords.length;

    return (
      <div className="flex flex-1 flex-col">
        <div className="mb-4">
          <h1 className="font-display text-2xl font-bold text-ink">
            {t("scan_select_words_title")}
          </h1>
          <p className="text-ink-muted">{t("scan_select_words_subtitle")}</p>
        </div>

        <div className="mb-4 flex items-center justify-between">
          <span className="text-sm font-bold text-coral">
            {t("scan_selected_count", { count: scan.selectedKeys.length })}
          </span>
          <button
            onClick={() => dispatch(toggleSelectAll())}
            className="text-sm font-bold text-ink-soft hover:text-ink"
          >
            {allSelected ? t("scan_deselect_all") : t("scan_select_all")}
          </button>
        </div>

        <div className="flex-1 space-y-5 overflow-y-auto pb-4">
          {groups.map(({ code, words }) => {
            const lang = languageByCode(code);
            const groupKeys = words.map((w) => w.word.toLowerCase());
            const groupAll = groupKeys.every((k) => scan.selectedKeys.includes(k));
            return (
              <div key={code ?? "unknown"}>
                {groups.length > 1 && (
                  <button
                    onClick={() => dispatch(toggleSelectAllInLanguage(code))}
                    className="mb-2 flex items-center gap-2 text-sm font-bold text-ink-soft"
                  >
                    <span className="text-lg">{lang?.flag ?? "🌐"}</span>
                    {lang?.name ?? t("scan_detected_language")}
                    <span className={cn("text-xs", groupAll ? "text-coral" : "text-ink-muted")}>
                      {groupAll ? "✓" : ""}
                    </span>
                  </button>
                )}
                <div className="flex flex-wrap gap-2">
                  {words.map((w) => {
                    const key = w.word.toLowerCase();
                    return (
                      <Chip
                        key={key}
                        selected={scan.selectedKeys.includes(key)}
                        onClick={() => dispatch(toggleWord(key))}
                      >
                        {w.word}
                        {w.translation && (
                          <span className="opacity-70">· {w.translation}</span>
                        )}
                      </Chip>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>

        {ctrl.selectionSpansLanguages && (
          <div className="mb-3 rounded-2xl bg-flame/10 px-4 py-3 text-sm font-medium text-flame-dark">
            {t("scan_mixed_languages_warning")}
          </div>
        )}
        <Button
          fullWidth
          size="lg"
          disabled={scan.selectedKeys.length === 0 || ctrl.selectionSpansLanguages}
          onClick={onContinue}
          rightIcon={<ChevronRight size={20} />}
        >
          {t("scan_continue_button")}
        </Button>
      </div>
    );
  }

  function DestinationChooser({
    onNew,
    onPickedExisting,
    onBack,
  }: {
    onNew: () => void;
    onPickedExisting: () => void;
    onBack: () => void;
  }) {
    const { data: decks } = useGetDecksQuery(200);
    return (
      <div className="flex flex-1 flex-col">
        <div className="mb-4">
          <button onClick={onBack} className="mb-2 text-sm font-bold text-coral">
            ← {t("common_cancel")}
          </button>
          <h1 className="font-display text-2xl font-bold text-ink">
            {t("scan_destination_title")}
          </h1>
          <p className="text-ink-muted">{t("scan_destination_subtitle")}</p>
        </div>

        <button
          onClick={onNew}
          className="mb-4 flex items-center gap-4 rounded-3xl border-2 border-dashed border-coral/40 bg-coral-soft/50 p-4 text-left hover:border-coral"
        >
          <IconTile solid size="md">
            <Plus size={22} />
          </IconTile>
          <div className="flex-1">
            <p className="font-display font-bold text-ink">
              {t("scan_destination_new_deck")}
            </p>
            <p className="text-sm text-ink-muted">{t("scan_destination_new_deck_hint")}</p>
          </div>
          <ChevronRight className="text-coral" />
        </button>

        {decks && decks.length > 0 && (
          <>
            <p className="mb-2 text-sm font-bold text-ink-muted">
              {t("scan_destination_existing_header")}
            </p>
            <div className="flex-1 space-y-2 overflow-y-auto">
              {decks.map((d) => (
                <button
                  key={d.id}
                  onClick={async () => {
                    await ctrl.fileToExistingDeck(d);
                    onPickedExisting();
                  }}
                  className="flex w-full items-center gap-3 rounded-2xl border-2 border-border bg-card px-4 py-3 text-left hover:border-coral/40"
                >
                  <IconTile hue={hueFor(d.id)} solid size="sm">
                    {d.name.charAt(0).toUpperCase()}
                  </IconTile>
                  <span className="flex-1 font-semibold text-ink">{d.name}</span>
                  <span className="text-lg">{languageByCode(d.targetLanguage)?.flag}</span>
                </button>
              ))}
            </div>
          </>
        )}
      </div>
    );
  }

  function NewDeckForm({ onDone, onBack }: { onDone: () => void; onBack: () => void }) {
    const defaultTarget =
      languageByCode(useAppSelector((s) => s.prefs.locale)) ?? VOCABULARY_LANGUAGES[0];
    const [target, setTarget] = useState<VocabularyLanguage>(defaultTarget);
    const [name, setName] = useState(ctrl.suggestedNameFor(target));

    return (
      <div className="flex flex-1 flex-col">
        <div className="mb-4">
          <button onClick={onBack} className="mb-2 text-sm font-bold text-coral">
            ← {t("common_cancel")}
          </button>
          <h1 className="font-display text-2xl font-bold text-ink">
            {t("scan_target_language_title")}
          </h1>
          <p className="text-ink-muted">{t("scan_target_language_body")}</p>
        </div>

        <div className="mb-4 flex flex-wrap gap-2">
          {VOCABULARY_LANGUAGES.slice(0, 12).map((l) => (
            <Chip
              key={l.code}
              selected={target.code === l.code}
              onClick={() => setTarget(l)}
              leading={<span>{l.flag}</span>}
            >
              {l.name}
            </Chip>
          ))}
        </div>

        <Card className="mb-4">
          <TextField
            label={t("scan_destination_new_deck")}
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </Card>

        <div className="mt-auto">
          <Button
            fullWidth
            size="lg"
            leftIcon={<Layers size={20} />}
            disabled={!name.trim()}
            onClick={async () => {
              await ctrl.fileToNewDeck(target, name.trim());
              onDone();
            }}
          >
            {t("scan_add_to_deck_button")}
          </Button>
        </div>
      </div>
    );
  }
}

function groupByLanguage(words: { languageCode: string | null }[]) {
  const map = new Map<string | null, typeof words>();
  for (const w of words) {
    const arr = map.get(w.languageCode) ?? [];
    arr.push(w);
    map.set(w.languageCode, arr);
  }
  return [...map.entries()].map(([code, ws]) => ({ code, words: ws as any[] }));
}
