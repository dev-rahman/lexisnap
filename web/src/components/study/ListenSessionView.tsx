import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Pause, Play, SkipBack, SkipForward, Volume2, X } from "lucide-react";

import type { Flashcard } from "@/lib/data/models";
import { speak, stopSpeaking } from "@/lib/services/tts";
import { Button } from "@/components/ui/Button";
import { useT } from "@/providers/I18nProvider";
import { cn } from "@/lib/utils/cn";

const PAUSE_MS = 650;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export function ListenSessionView({ cards }: { cards: Flashcard[] }) {
  const t = useT();
  const navigate = useNavigate();
  const [index, setIndex] = useState(0);
  const [playing, setPlaying] = useState(true);
  const [phase, setPhase] = useState<"word" | "translation">("word");
  const runId = useRef(0);

  const card = cards[index];

  // Drive the hands-free loop: word → pause → translation → pause → next.
  useEffect(() => {
    if (!playing || !card) return;
    const myRun = ++runId.current;
    let active = true;

    (async () => {
      setPhase("word");
      await speak(card.word, card.sourceLanguage);
      if (!active || runId.current !== myRun) return;
      await sleep(PAUSE_MS);
      if (!active || runId.current !== myRun) return;
      setPhase("translation");
      await speak(card.translation, card.targetLanguage);
      if (!active || runId.current !== myRun) return;
      await sleep(PAUSE_MS);
      if (!active || runId.current !== myRun) return;
      setIndex((i) => (i + 1 < cards.length ? i + 1 : i));
      if (index + 1 >= cards.length) setPlaying(false);
    })();

    return () => {
      active = false;
      stopSpeaking();
    };
  }, [playing, index, card, cards.length]);

  useEffect(() => () => stopSpeaking(), []);

  function go(delta: number) {
    runId.current++;
    stopSpeaking();
    setIndex((i) => Math.min(cards.length - 1, Math.max(0, i + delta)));
  }

  if (!card) return null;
  const finished = !playing && index === cards.length - 1 && phase === "translation";

  return (
    <div className="app-wash flex min-h-dvh flex-col bg-paper safe-top">
      <div className="flex items-center justify-between px-4 py-3">
        <span className="font-display text-sm font-bold text-ink-muted">
          {index + 1} / {cards.length}
        </span>
        <button
          onClick={() => navigate(-1)}
          aria-label={t("common_cancel")}
          className="grid h-10 w-10 place-items-center rounded-full text-ink-soft hover:bg-ink/5"
        >
          <X size={22} />
        </button>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
        <div
          className={cn(
            "grid h-20 w-20 place-items-center rounded-full bg-coral-soft text-coral transition-transform",
            playing && "scale-110",
          )}
        >
          <Volume2 size={36} className={playing ? "animate-pulse" : ""} />
        </div>

        <h1
          className={cn(
            "mt-8 font-display text-5xl font-bold transition-colors",
            phase === "word" ? "text-ink" : "text-ink-muted",
          )}
        >
          {card.word}
        </h1>
        <p
          className={cn(
            "mt-4 text-2xl font-bold transition-colors",
            phase === "translation" ? "text-coral" : "text-ink-muted/60",
          )}
        >
          {card.translation}
        </p>

        {finished && (
          <p className="mt-8 font-display text-lg font-bold text-success">
            {t("listen_finished")}
          </p>
        )}
      </div>

      {/* Transport */}
      <div className="mx-auto mb-10 flex w-full max-w-xs items-center justify-between px-4">
        <button
          onClick={() => go(-1)}
          disabled={index === 0}
          className="grid h-14 w-14 place-items-center rounded-full text-ink-soft hover:bg-ink/5 disabled:opacity-30"
        >
          <SkipBack size={28} fill="currentColor" />
        </button>
        <button
          onClick={() => {
            if (finished) {
              setIndex(0);
              setPlaying(true);
            } else {
              setPlaying((p) => !p);
            }
          }}
          className="btn3d h-20 w-20 rounded-full bg-coral text-white shadow-pop"
        >
          {playing ? <Pause size={34} fill="currentColor" /> : <Play size={34} fill="currentColor" />}
        </button>
        <button
          onClick={() => go(1)}
          disabled={index >= cards.length - 1}
          className="grid h-14 w-14 place-items-center rounded-full text-ink-soft hover:bg-ink/5 disabled:opacity-30"
        >
          <SkipForward size={28} fill="currentColor" />
        </button>
      </div>

      <div className="px-6 pb-8">
        <p className="text-center text-sm text-ink-muted">{t("listen_hint")}</p>
        <Button variant="ghost" fullWidth className="mt-2" onClick={() => navigate(-1)}>
          {t("study_done")}
        </Button>
      </div>
    </div>
  );
}
