import { useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
  CheckSquare,
  Copy,
  FolderInput,
  Headphones,
  MoreVertical,
  Move,
  Pencil,
  Play,
  Square,
  Trash2,
} from "lucide-react";

import { CardDetailSheet } from "@/components/decks/CardDetailSheet";
import { CardEditSheet } from "@/components/decks/CardEditSheet";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { IconTile } from "@/components/ui/IconTile";
import { Sheet } from "@/components/ui/Sheet";
import { Skeleton } from "@/components/ui/Skeleton";
import { TextField } from "@/components/ui/TextField";
import { PageHeader } from "@/components/shell/PageHeader";
import type { Deck, Flashcard } from "@/lib/data/models";
import * as repo from "@/lib/data/repository";
import { hueFor } from "@/lib/domain/deckHue";
import { isDue } from "@/lib/data/models";
import { languageByCode } from "@/lib/data/languages";
import { toast } from "@/lib/toast";
import { useT } from "@/providers/I18nProvider";
import { useAppDispatch } from "@/store/hooks";
import {
  CARDS_PAGE_SIZE,
  decksApi,
  useDeleteDeckMutation,
  useDeleteFlashcardMutation,
  useDeleteFlashcardsMutation,
  useGetDeckCardsQuery,
  useGetDeckDueCountQuery,
  useGetDeckMetaQuery,
  useGetDecksQuery,
  useRenameDeckMutation,
} from "@/store/api/decksApi";
import { cn } from "@/lib/utils/cn";

type DeckSheet = null | "menu" | "rename" | "delete" | "move" | "copy" | "merge";

export function DeckDetail() {
  const { id = "" } = useParams();
  const t = useT();
  const navigate = useNavigate();
  const dispatch = useAppDispatch();

  const { data: deck, isLoading: metaLoading } = useGetDeckMetaQuery(id);
  const { data: dueCount } = useGetDeckDueCountQuery(id);
  const [limit, setLimit] = useState(CARDS_PAGE_SIZE);
  const { data: cards, isLoading: cardsLoading } = useGetDeckCardsQuery(
    {
      deckId: id,
      sourceLanguage: deck?.sourceLanguage ?? null,
      targetLanguage: deck?.targetLanguage ?? "en",
      limit,
    },
    { skip: !deck },
  );
  const { data: allDecks } = useGetDecksQuery(200);

  const [rename] = useRenameDeckMutation();
  const [deleteDeck] = useDeleteDeckMutation();
  const [deleteCard] = useDeleteFlashcardMutation();
  const [deleteCards] = useDeleteFlashcardsMutation();

  const [sheet, setSheet] = useState<DeckSheet>(null);
  const [newName, setNewName] = useState("");
  const [detailCard, setDetailCard] = useState<Flashcard | null>(null);
  const [editCard, setEditCard] = useState<Flashcard | null>(null);
  const [selectMode, setSelectMode] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [busy, setBusy] = useState(false);

  const source = languageByCode(deck?.sourceLanguage);
  const target = languageByCode(deck?.targetLanguage);
  const hue = deck ? hueFor(deck.id) : "teal";
  const otherDecks = useMemo(
    () => (allDecks ?? []).filter((d) => d.id !== id),
    [allDecks, id],
  );

  function invalidate() {
    dispatch(
      decksApi.util.invalidateTags([
        { type: "DeckCards", id },
        { type: "Deck", id },
        { type: "Decks", id: "LIST" },
        { type: "Totals", id: "ALL" },
        { type: "Due", id: "LIST" },
      ]),
    );
  }

  function toggle(cardId: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(cardId) ? next.delete(cardId) : next.add(cardId);
      return next;
    });
  }

  function exitSelect() {
    setSelectMode(false);
    setSelected(new Set());
  }

  async function onRename() {
    try {
      await rename({ deckId: id, name: newName.trim() }).unwrap();
      setSheet(null);
    } catch {
      toast.error(t("deck_rename_error"));
    }
  }

  async function onDeleteDeck() {
    try {
      await deleteDeck(id).unwrap();
      toast.success(t("deck_deleted_success"));
      navigate("/decks", { replace: true });
    } catch {
      toast.error(t("deck_delete_error"));
    }
  }

  async function onDeleteSelected() {
    try {
      const count = selected.size;
      await deleteCards({ flashcardIds: [...selected], deckId: id }).unwrap();
      toast.success(t("cards_deleted_success", { count }));
      exitSelect();
    } catch {
      toast.error(t("cards_delete_error"));
    }
  }

  // Dedupe-aware move/copy into a target deck (unique index guards duplicates).
  async function fileInto(target: Deck, mode: "move" | "copy") {
    setBusy(true);
    try {
      const existing = await repo.wordsInDeck(target.id);
      const ids = [...selected];
      const picked = (cards ?? []).filter((c) => ids.includes(c.id));
      const fresh = picked.filter((c) => !existing.has(c.word.toLowerCase()));
      const dupIds = picked.filter((c) => existing.has(c.word.toLowerCase())).map((c) => c.id);

      if (fresh.length === 0) {
        toast.warning(t("cards_all_present", { name: target.name }));
        setBusy(false);
        return;
      }
      const freshIds = fresh.map((c) => c.id);
      if (mode === "move") {
        await repo.moveFlashcards(freshIds, target.id);
        if (dupIds.length) await repo.deleteFlashcards(dupIds);
      } else {
        await repo.copyFlashcards(freshIds, target.id);
      }
      invalidate();
      toast.success(
        mode === "move"
          ? t("cards_moved_success", { count: fresh.length, name: target.name })
          : t("scan_words_added_success", { count: fresh.length, name: target.name }),
      );
      setSheet(null);
      exitSelect();
    } catch {
      toast.error(t("common_something_went_wrong"));
    } finally {
      setBusy(false);
    }
  }

  // Merge this whole deck into another, then delete the emptied deck.
  async function onMerge(target: Deck) {
    setBusy(true);
    try {
      const { flashcards } = await repo.getDeck(id);
      const existing = await repo.wordsInDeck(target.id);
      const fresh = flashcards.filter((c) => !existing.has(c.word.toLowerCase()));
      if (fresh.length) await repo.moveFlashcards(fresh.map((c) => c.id), target.id);
      await repo.deleteDeck(id);
      invalidate();
      toast.success(
        t("deck_merged_success", { name: target.name, count: fresh.length }),
      );
      navigate(`/deck/${target.id}`, { replace: true });
    } catch {
      toast.error(t("deck_merge_error"));
    } finally {
      setBusy(false);
    }
  }

  if (metaLoading || !deck) {
    return (
      <div className="mx-auto max-w-2xl">
        <PageHeader title="…" />
        <Skeleton className="h-28 w-full" />
      </div>
    );
  }

  const due = dueCount ?? 0;

  return (
    <div className="mx-auto max-w-2xl">
      <PageHeader
        title={deck.name}
        back
        action={
          <button
            onClick={() => {
              setNewName(deck.name);
              setSheet("menu");
            }}
            className="grid h-10 w-10 place-items-center rounded-full border border-border bg-card text-ink-soft hover:bg-ink/5"
            aria-label="Deck options"
          >
            <MoreVertical size={20} />
          </button>
        }
      />

      {/* Deck hero */}
      <Card className="mb-5 flex items-center gap-4">
        <IconTile hue={hue} solid size="lg">
          {deck.name.trim().charAt(0).toUpperCase() || "?"}
        </IconTile>
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2 text-2xl">
            {source?.flag ?? "📄"} <span className="text-ink-muted text-base">→</span>{" "}
            {target?.flag ?? "🏳️"}
          </div>
          <p className="mt-1 text-sm font-semibold text-ink-muted">
            {t("home_deck_card_count", { count: deck.cardCount })}
            {due > 0 && (
              <span className="ml-2 rounded-full bg-coral-soft px-2 py-0.5 text-coral">
                {t("deck_due_now", { count: due })}
              </span>
            )}
          </p>
        </div>
      </Card>

      {/* Actions */}
      <div className="mb-5 grid grid-cols-2 gap-3">
        <Button
          size="lg"
          leftIcon={<Play size={20} />}
          onClick={() => navigate(`/study?deck=${id}`)}
        >
          {due > 0 ? t("deck_study_due", { count: due }) : t("deck_study")}
        </Button>
        <Button
          size="lg"
          variant="secondary"
          leftIcon={<Headphones size={20} />}
          onClick={() => navigate(`/listen?deck=${id}`)}
        >
          {t("deck_listen")}
        </Button>
      </div>

      {/* Select toggle */}
      {deck.cardCount > 0 && (
        <div className="mb-3 flex items-center justify-between">
          <h2 className="font-display text-lg font-bold text-ink">
            {t("decks_stat_words")}
          </h2>
          <button
            onClick={() => (selectMode ? exitSelect() : setSelectMode(true))}
            className="text-sm font-bold text-coral"
          >
            {selectMode ? t("common_cancel") : t("cards_select")}
          </button>
        </div>
      )}

      {/* Card list */}
      {cardsLoading ? (
        <div className="space-y-2">
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full" />
          ))}
        </div>
      ) : cards && cards.length > 0 ? (
        <>
          <div className="space-y-2">
            {cards.map((card) => {
              const checked = selected.has(card.id);
              return (
                <button
                  key={card.id}
                  onClick={() => (selectMode ? toggle(card.id) : setDetailCard(card))}
                  className={cn(
                    "flex w-full items-center gap-3 rounded-2xl border-2 bg-card px-4 py-3 text-left transition-colors",
                    checked ? "border-coral bg-coral-soft" : "border-border hover:border-coral/30",
                  )}
                >
                  {selectMode &&
                    (checked ? (
                      <CheckSquare size={22} className="shrink-0 text-coral" />
                    ) : (
                      <Square size={22} className="shrink-0 text-ink-muted" />
                    ))}
                  <div className="min-w-0 flex-1">
                    <p className="truncate font-display font-bold text-ink">{card.word}</p>
                    <p className="truncate text-sm text-ink-muted">{card.translation}</p>
                  </div>
                  {!selectMode && isDue(card) && (
                    <span className="h-2.5 w-2.5 shrink-0 rounded-full bg-coral" />
                  )}
                </button>
              );
            })}
          </div>
          {cards.length >= limit && (
            <div className="mt-4 flex justify-center">
              <Button variant="secondary" onClick={() => setLimit((l) => l + CARDS_PAGE_SIZE)}>
                {t("decks_all")}
              </Button>
            </div>
          )}
        </>
      ) : (
        <EmptyState emoji="🗂️" title={t("home_no_decks_title")} />
      )}

      {/* Selection action bar */}
      {selectMode && selected.size > 0 && (
        <div className="fixed inset-x-0 bottom-0 z-40 flex justify-center pb-safe">
          <div className="mx-4 mb-4 flex w-full max-w-md items-center gap-2 rounded-full border border-border bg-card/95 p-2 shadow-card-lift backdrop-blur">
            <span className="px-3 font-display font-bold text-ink">{selected.size}</span>
            <button
              onClick={() => setSheet("move")}
              className="flex flex-1 flex-col items-center gap-0.5 rounded-xl py-1.5 text-xs font-bold text-ink-soft hover:bg-ink/5"
            >
              <Move size={18} /> {t("cards_move")}
            </button>
            <button
              onClick={() => setSheet("copy")}
              className="flex flex-1 flex-col items-center gap-0.5 rounded-xl py-1.5 text-xs font-bold text-ink-soft hover:bg-ink/5"
            >
              <Copy size={18} /> {t("cards_copy")}
            </button>
            <button
              onClick={onDeleteSelected}
              className="flex flex-1 flex-col items-center gap-0.5 rounded-xl py-1.5 text-xs font-bold text-error hover:bg-error/5"
            >
              <Trash2 size={18} /> {t("cards_delete")}
            </button>
          </div>
        </div>
      )}

      {/* Card detail + edit */}
      <CardDetailSheet
        card={detailCard}
        open={detailCard != null}
        onClose={() => setDetailCard(null)}
        onEdit={() => {
          setEditCard(detailCard);
          setDetailCard(null);
        }}
        onDelete={async () => {
          if (!detailCard) return;
          try {
            await deleteCard({ flashcardId: detailCard.id, deckId: id }).unwrap();
            toast.success(t("card_deleted_success"));
            setDetailCard(null);
          } catch {
            toast.error(t("card_delete_error"));
          }
        }}
      />
      <CardEditSheet
        card={editCard}
        deckId={id}
        open={editCard != null}
        onClose={() => setEditCard(null)}
      />

      {/* Deck menu */}
      <Sheet open={sheet === "menu"} onClose={() => setSheet(null)} title={deck.name}>
        <div className="space-y-2">
          <MenuItem icon={<Pencil size={18} />} label={t("deck_rename_title")} onClick={() => setSheet("rename")} />
          <MenuItem icon={<FolderInput size={18} />} label={t("deck_merge_title")} onClick={() => setSheet("merge")} />
          <MenuItem
            icon={<Trash2 size={18} />}
            label={t("deck_delete_title")}
            danger
            onClick={() => setSheet("delete")}
          />
        </div>
      </Sheet>

      {/* Rename */}
      <Sheet
        open={sheet === "rename"}
        onClose={() => setSheet(null)}
        title={t("deck_rename_title")}
        footer={<Button fullWidth onClick={onRename} disabled={!newName.trim()}>{t("common_save")}</Button>}
      >
        <TextField value={newName} onChange={(e) => setNewName(e.target.value)} autoFocus />
      </Sheet>

      {/* Delete */}
      <Sheet
        open={sheet === "delete"}
        onClose={() => setSheet(null)}
        title={t("deck_delete_title")}
        footer={
          <div className="flex gap-3">
            <Button variant="ghost" fullWidth onClick={() => setSheet(null)}>
              {t("common_cancel")}
            </Button>
            <Button variant="danger" fullWidth onClick={onDeleteDeck}>
              {t("deck_delete_confirm")}
            </Button>
          </div>
        }
      >
        <p className="text-ink-muted">{t("deck_delete_body", { name: deck.name })}</p>
      </Sheet>

      {/* Move / Copy / Merge target pickers */}
      <DeckPicker
        open={sheet === "move"}
        title={t("cards_move_title", { count: selected.size })}
        decks={otherDecks}
        busy={busy}
        onClose={() => setSheet(null)}
        onPick={(d) => fileInto(d, "move")}
      />
      <DeckPicker
        open={sheet === "copy"}
        title={t("cards_copy_title", { count: selected.size })}
        decks={otherDecks}
        busy={busy}
        onClose={() => setSheet(null)}
        onPick={(d) => fileInto(d, "copy")}
      />
      <DeckPicker
        open={sheet === "merge"}
        title={t("deck_merge_title")}
        subtitle={t("deck_merge_subtitle")}
        decks={otherDecks.filter(
          (d) => d.targetLanguage === deck.targetLanguage,
        )}
        busy={busy}
        onClose={() => setSheet(null)}
        onPick={onMerge}
      />
    </div>
  );
}

function MenuItem({
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
      className={cn(
        "flex w-full items-center gap-3 rounded-2xl px-4 py-3.5 text-left font-semibold transition-colors hover:bg-ink/5",
        danger ? "text-error hover:bg-error/5" : "text-ink",
      )}
    >
      {icon} {label}
    </button>
  );
}

function DeckPicker({
  open,
  title,
  subtitle,
  decks,
  busy,
  onClose,
  onPick,
}: {
  open: boolean;
  title: string;
  subtitle?: string;
  decks: Deck[];
  busy: boolean;
  onClose: () => void;
  onPick: (deck: Deck) => void;
}) {
  const t = useT();
  return (
    <Sheet open={open} onClose={onClose} title={title}>
      {subtitle && <p className="mb-3 text-sm text-ink-muted">{subtitle}</p>}
      {decks.length === 0 ? (
        <EmptyState emoji="📭" title={t("home_no_decks_title")} />
      ) : (
        <div className={cn("space-y-2", busy && "pointer-events-none opacity-60")}>
          {decks.map((d) => (
            <button
              key={d.id}
              onClick={() => onPick(d)}
              className="flex w-full items-center gap-3 rounded-2xl border-2 border-border px-4 py-3 text-left hover:border-coral/40"
            >
              <IconTile hue={hueFor(d.id)} solid size="sm">
                {d.name.charAt(0).toUpperCase()}
              </IconTile>
              <span className="flex-1 font-semibold text-ink">{d.name}</span>
              <span className="text-sm text-ink-muted">
                {t("home_deck_card_count", { count: d.cardCount })}
              </span>
            </button>
          ))}
        </div>
      )}
    </Sheet>
  );
}
