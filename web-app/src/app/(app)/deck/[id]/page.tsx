"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";
import {
  Copy,
  Headphones,
  MoreVertical,
  Play,
  Trash2,
  FolderInput,
} from "lucide-react";

import { PageShell } from "@/components/shell/PageShell";

import { CardDetailSheet } from "@/components/decks/CardDetailSheet";
import { CardEditSheet } from "@/components/decks/CardEditSheet";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { ConfirmSheet, Sheet } from "@/components/ui/Sheet";
import { Spinner } from "@/components/ui/Spinner";
import { TextField } from "@/components/ui/TextField";
import { useT } from "@/components/providers/I18nProvider";
import { languageByCode } from "@/lib/data/languages";
import type { Deck, Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { hueFor } from "@/lib/domain/deckHue";
import { toast } from "@/lib/toast";
import { HUE_BG } from "@/lib/utils/hueClasses";
import {
  CARDS_PAGE_SIZE,
  useCopyFlashcardsMutation,
  useDeleteDeckMutation,
  useDeleteFlashcardMutation,
  useDeleteFlashcardsMutation,
  useGetDeckCardsQuery,
  useGetDeckDueCountQuery,
  useGetDeckMetaQuery,
  useMoveFlashcardsMutation,
  useRenameDeckMutation,
} from "@/store/api/decksApi";
import { decksApi } from "@/store/api/decksApi";
import { useAppDispatch, useAppSelector } from "@/store/hooks";

type DestMode = "move" | "copy" | "merge";

export default function DeckDetailPage() {
  const t = useT();
  const router = useRouter();
  const dispatch = useAppDispatch();
  const deckId = String(useParams().id);
  const studyMode = useAppSelector((s) => s.prefs.studyMode);

  const [limit, setLimit] = useState(CARDS_PAGE_SIZE);
  const { data: deck, isLoading: metaLoading } = useGetDeckMetaQuery(deckId);
  const { data: dueCount = 0 } = useGetDeckDueCountQuery(deckId);
  const { data: cards = [], isFetching } = useGetDeckCardsQuery(
    deck
      ? {
          deckId,
          sourceLanguage: deck.sourceLanguage,
          targetLanguage: deck.targetLanguage,
          limit,
        }
      : { deckId, sourceLanguage: null, targetLanguage: "", limit },
    { skip: !deck },
  );

  const [rename] = useRenameDeckMutation();
  const [deleteDeck] = useDeleteDeckMutation();
  const [deleteCard] = useDeleteFlashcardMutation();
  const [deleteCards] = useDeleteFlashcardsMutation();
  const [moveCards] = useMoveFlashcardsMutation();
  const [copyCards] = useCopyFlashcardsMutation();

  // UI state
  const [menuOpen, setMenuOpen] = useState(false);
  const [renaming, setRenaming] = useState(false);
  const [renameValue, setRenameValue] = useState("");
  const [deleting, setDeleting] = useState(false);
  const [detail, setDetail] = useState<Flashcard | null>(null);
  const [editing, setEditing] = useState<Flashcard | null>(null);
  const [deletingCard, setDeletingCard] = useState<Flashcard | null>(null);
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [dest, setDest] = useState<DestMode | null>(null);

  if (metaLoading || !deck) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-paper">
        {metaLoading ? <Spinner className="text-accent" /> : <p className="text-ink-muted">{t("deck_load_error")}</p>}
      </div>
    );
  }

  const hue = hueFor(deck.id);
  const source = languageByCode(deck.sourceLanguage);
  const target = languageByCode(deck.targetLanguage);
  const studyHref = studyMode === "listen" ? `/listen?deck=${deckId}` : `/study?deck=${deckId}`;

  function toggleSel(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }

  async function doRename() {
    if (!renameValue.trim()) return;
    try {
      await rename({ deckId, name: renameValue.trim() }).unwrap();
      setRenaming(false);
    } catch {
      toast.error(t("deck_rename_error"));
    }
  }

  async function doDeleteDeck() {
    try {
      await deleteDeck(deckId).unwrap();
      toast.success(t("deck_deleted_success"));
      router.push("/decks");
    } catch {
      toast.error(t("deck_delete_error"));
    }
  }

  async function doDeleteCard() {
    if (!deletingCard) return;
    try {
      await deleteCard({ flashcardId: deletingCard.id, deckId }).unwrap();
      toast.success(t("card_deleted_success"));
      setDeletingCard(null);
      setDetail(null);
    } catch {
      toast.error(t("card_delete_error"));
    }
  }

  async function bulkDelete() {
    try {
      await deleteCards({ flashcardIds: [...selected], deckId }).unwrap();
      toast.success(t("card_deleted_success"));
      exitSelect();
    } catch {
      toast.error(t("card_delete_error"));
    }
  }

  function exitSelect() {
    setSelectMode(false);
    setSelected(new Set());
  }

  return (
    <PageShell
      title={deck.name}
      actions={
        <>
          <button
            onClick={() => setSelectMode((v) => !v)}
            className="rounded-lg px-2 py-1 text-sm font-medium text-accent"
          >
            {selectMode ? t("common_cancel") : t("scan_select_all")}
          </button>
          <button
            onClick={() => setMenuOpen(true)}
            aria-label="Menu"
            className="rounded-lg p-1.5 text-ink-muted transition hover:bg-card"
          >
            <MoreVertical size={22} />
          </button>
        </>
      }
    >
      <div className="pb-24">
        {/* Hero */}
        <section className="panel-surface mb-6 rounded-3xl p-6">
          <p className="text-sm text-white/70">
            {t("deck_summary", {
              source: source?.name ?? deck.sourceLanguage ?? "—",
              target: target?.name ?? deck.targetLanguage,
              count: deck.cardCount,
            })}
          </p>
          <p className="mt-1 text-sm text-accent">
            {dueCount > 0 ? t("deck_due_now", { count: dueCount }) : t("deck_all_caught_up")}
          </p>
          <div className="mt-4 flex gap-3">
            <Button variant="primary" fullWidth onClick={() => router.push(studyHref)}>
              <Play size={18} /> {dueCount > 0 ? t("deck_study_due", { count: dueCount }) : t("deck_study")}
            </Button>
            <Button
              variant="secondary"
              onClick={() => router.push(`/listen?deck=${deckId}`)}
              className="!bg-white/10 !text-white !border-white/20"
            >
              <Headphones size={18} /> {t("deck_listen")}
            </Button>
          </div>
        </section>

        {/* Cards */}
        <div className="flex flex-col gap-2">
          {cards.map((card) => {
            const isSel = selected.has(card.id);
            return (
              <button
                key={card.id}
                onClick={() => (selectMode ? toggleSel(card.id) : setDetail(card))}
                className={`flex items-center gap-3 rounded-2xl border p-4 text-left transition ${
                  isSel ? "border-accent bg-accent/10" : "border-border bg-card hover:bg-surface"
                }`}
              >
                {selectMode && (
                  <span
                    className={`flex h-5 w-5 items-center justify-center rounded-full border-2 text-[11px] ${
                      isSel ? "border-accent bg-accent text-white" : "border-border"
                    }`}
                  >
                    {isSel ? "✓" : ""}
                  </span>
                )}
                <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-sm font-bold text-white ${HUE_BG[hue]}`}>
                  {card.word.slice(0, 1).toUpperCase()}
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block truncate font-semibold text-ink">{card.word}</span>
                  <span className="block truncate text-sm text-ink-muted">{card.translation}</span>
                </span>
                {card.level && <Chip>{card.level}</Chip>}
              </button>
            );
          })}
          {cards.length >= limit && (
            <div className="mt-2 flex justify-center">
              <Button variant="secondary" size="md" loading={isFetching} onClick={() => setLimit((l) => l + CARDS_PAGE_SIZE)}>
                {t("home_see_all")}
              </Button>
            </div>
          )}
        </div>
      </div>

      {/* Selection action bar */}
      {selectMode && selected.size > 0 && (
        <div className="fixed inset-x-0 bottom-0 mx-auto flex max-w-2xl items-center gap-2 border-t border-border bg-paper/95 p-3 backdrop-blur-lg safe-bottom md:left-64">
          <span className="px-1 text-sm font-medium text-ink">{selected.size}</span>
          <ActionBtn icon={<FolderInput size={18} />} label={t("deck_merge_menu").split(" ")[0]} onClick={() => setDest("move")} />
          <ActionBtn icon={<Copy size={18} />} label="Copy" onClick={() => setDest("copy")} />
          <ActionBtn icon={<Trash2 size={18} />} label={t("card_delete_confirm").split(" ")[0]} danger onClick={bulkDelete} />
        </div>
      )}

      {/* Menu */}
      <Sheet open={menuOpen} onClose={() => setMenuOpen(false)}>
        <div className="flex flex-col">
          <MenuRow
            label={t("deck_rename_title")}
            onClick={() => {
              setMenuOpen(false);
              setRenameValue(deck.name);
              setRenaming(true);
            }}
          />
          <MenuRow
            label={t("deck_merge_menu")}
            onClick={() => {
              setMenuOpen(false);
              setDest("merge");
            }}
          />
          <MenuRow
            label={t("deck_delete_confirm")}
            danger
            onClick={() => {
              setMenuOpen(false);
              setDeleting(true);
            }}
          />
        </div>
      </Sheet>

      {/* Rename */}
      <Sheet open={renaming} onClose={() => setRenaming(false)} title={t("deck_rename_title")}>
        <TextField value={renameValue} onChange={(e) => setRenameValue(e.target.value)} autoFocus />
        <Button variant="primary" fullWidth className="mt-4" onClick={doRename}>
          {t("common_save")}
        </Button>
      </Sheet>

      <ConfirmSheet
        open={deleting}
        onClose={() => setDeleting(false)}
        title={t("deck_delete_title")}
        message={t("deck_delete_body")}
        cancelLabel={t("common_cancel")}
        confirmLabel={t("deck_delete_confirm")}
        danger
        onConfirm={doDeleteDeck}
      />

      <CardDetailSheet
        card={detail}
        open={detail !== null}
        onClose={() => setDetail(null)}
        onEdit={() => {
          setEditing(detail);
          setDetail(null);
        }}
        onDelete={() => setDeletingCard(detail)}
      />
      <CardEditSheet card={editing} deckId={deckId} open={editing !== null} onClose={() => setEditing(null)} />
      <ConfirmSheet
        open={deletingCard !== null}
        onClose={() => setDeletingCard(null)}
        title={t("card_delete_title")}
        message={deletingCard ? t("card_delete_body", { word: deletingCard.word }) : ""}
        cancelLabel={t("common_cancel")}
        confirmLabel={t("card_delete_confirm")}
        danger
        onConfirm={doDeleteCard}
      />

      {dest && (
        <DestinationPicker
          deck={deck}
          mode={dest}
          selectedIds={[...selected]}
          onClose={() => setDest(null)}
          onDone={(backToDecks) => {
            setDest(null);
            exitSelect();
            if (backToDecks) router.push("/decks");
            else dispatch(decksApi.util.invalidateTags([{ type: "DeckCards", id: deckId }]));
          }}
          moveCards={moveCards}
          copyCards={copyCards}
          deleteDeck={deleteDeck}
        />
      )}
    </PageShell>
  );
}

function ActionBtn({
  icon,
  label,
  onClick,
  danger,
}: {
  icon: React.ReactNode;
  label: string;
  onClick: () => void;
  danger?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex flex-1 flex-col items-center gap-0.5 rounded-md py-1.5 text-xs font-medium ${
        danger ? "text-error" : "text-ink"
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

function MenuRow({ label, onClick, danger }: { label: string; onClick: () => void; danger?: boolean }) {
  return (
    <button
      onClick={onClick}
      className={`py-3.5 text-left font-medium ${danger ? "text-error" : "text-ink"}`}
    >
      {label}
    </button>
  );
}

/** Lists decks sharing this deck's language pair as a move/copy/merge target. */
function DestinationPicker({
  deck,
  mode,
  selectedIds,
  onClose,
  onDone,
  moveCards,
  copyCards,
  deleteDeck,
}: {
  deck: Deck;
  mode: DestMode;
  selectedIds: string[];
  onClose: () => void;
  onDone: (backToDecks: boolean) => void;
  moveCards: ReturnType<typeof useMoveFlashcardsMutation>[0];
  copyCards: ReturnType<typeof useCopyFlashcardsMutation>[0];
  deleteDeck: ReturnType<typeof useDeleteDeckMutation>[0];
}) {
  const t = useT();
  const [decks, setDecks] = useState<Deck[] | null>(null);
  const [busy, setBusy] = useState(false);

  // Load compatible decks once on open.
  useEffect(() => {
    let active = true;
    repo
      .listDecksByLanguagePair(deck.sourceLanguage, deck.targetLanguage)
      .then((d) => active && setDecks(d.filter((x) => x.id !== deck.id)))
      .catch(() => active && setDecks([]));
    return () => {
      active = false;
    };
  }, [deck.id, deck.sourceLanguage, deck.targetLanguage]);

  async function pick(target: Deck) {
    if (busy) return;
    setBusy(true);
    try {
      if (mode === "copy") {
        await copyCards({ flashcardIds: selectedIds, toDeckId: target.id }).unwrap();
        toast.success(t("scan_words_added_success", { count: selectedIds.length, name: target.name }));
        onDone(false);
      } else if (mode === "move") {
        await moveCards({ flashcardIds: selectedIds, toDeckId: target.id, fromDeckId: deck.id }).unwrap();
        toast.success(t("scan_words_added_success", { count: selectedIds.length, name: target.name }));
        onDone(false);
      } else {
        // merge: move every card then delete this deck.
        const all = await repo.getDeck(deck.id);
        const existing = await repo.wordsInDeck(target.id);
        const movable = all.flashcards.filter((c) => !existing.has(c.word.toLowerCase())).map((c) => c.id);
        await repo.moveFlashcards(movable, target.id);
        await deleteDeck(deck.id).unwrap();
        toast.success(t("deck_merged_success", { name: target.name }));
        onDone(true);
      }
    } catch {
      toast.error(mode === "merge" ? t("deck_merge_error") : t("deck_delete_error"));
      setBusy(false);
    }
  }

  const title = mode === "merge" ? t("deck_merge_title") : t("scan_destination_title", { count: selectedIds.length });

  return (
    <Sheet open onClose={onClose} title={title}>
      {mode === "merge" && <p className="mb-3 text-sm text-ink-muted">{t("deck_merge_subtitle")}</p>}
      {decks === null ? (
        <div className="flex justify-center py-6"><Spinner /></div>
      ) : decks.length === 0 ? (
        <p className="py-4 text-center text-sm text-ink-muted">{t("home_no_decks_title")}</p>
      ) : (
        <div className="max-h-72 space-y-2 overflow-y-auto">
          {decks.map((d) => (
            <button
              key={d.id}
              disabled={busy}
              onClick={() => pick(d)}
              className="flex w-full items-center justify-between rounded-lg border border-border bg-card p-3 text-left disabled:opacity-50"
            >
              <span className="font-medium text-ink">{d.name}</span>
              <span className="text-sm text-ink-muted">{d.cardCount}</span>
            </button>
          ))}
        </div>
      )}
    </Sheet>
  );
}
