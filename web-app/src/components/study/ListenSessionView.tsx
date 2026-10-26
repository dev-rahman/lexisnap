"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { Pause, Play, SkipBack, SkipForward, Volume2, X } from "lucide-react";

import { useT } from "@/components/providers/I18nProvider";
import type { Flashcard } from "@/lib/data/models";
import { speak, stopSpeaking } from "@/lib/services/tts";

const RECALL_GAP_MS = 1600;
const AFTER_GAP_MS = 900;
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** Hands-free playback — speaks word, pause, translation, pause, next.
 *  Nothing is graded and no schedule is touched (ports listen_session_view). */
export function ListenSessionView({ cards }: { cards: Flashcard[] }) {
  const t = useT();
  const router = useRouter();
  const [index, setIndex] = useState(0);
  const [playing, setPlaying] = useState(false);
  const runId = useRef(0);

  const stop = useCallback(() => {
    runId.current++;
    stopSpeaking();
    setPlaying(false);
  }, []);

  useEffect(() => stop, [stop]);

  const playFrom = useCallback(
    async (start: number) => {
      runId.current++;
      const myRun = runId.current;
      setPlaying(true);
      for (let i = start; i < cards.length; i++) {
        if (runId.current !== myRun) return;
        setIndex(i);
        const card = cards[i];
        await speak(card.word, card.sourceLanguage);
        if (runId.current !== myRun) return;
        await wait(RECALL_GAP_MS);
        if (runId.current !== myRun) return;
        await speak(card.translation, card.targetLanguage);
        if (runId.current !== myRun) return;
        await wait(AFTER_GAP_MS);
      }
      if (runId.current === myRun) setPlaying(false);
    },
    [cards],
  );

  const card = cards[index];
  const finished = index >= cards.length - 1 && !playing;

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col px-5 py-4">
      <div className="flex items-center justify-between safe-top">
        <button onClick={() => router.back()} aria-label="Close" className="text-ink-muted">
          <X size={24} />
        </button>
        <span className="text-sm text-ink-muted">
          {index + 1} / {cards.length}
        </span>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <p className="mb-1 text-sm font-medium uppercase tracking-wide text-ink-muted">
          {t("listen_title")}
        </p>
        {card && (
          <>
            <button
              onClick={() => speak(card.word, card.sourceLanguage)}
              className="flex items-center gap-2 text-4xl font-bold text-ink"
            >
              {card.word}
              <Volume2 size={24} className="text-ink-muted" />
            </button>
            <p className="mt-4 text-2xl text-accent">{card.translation}</p>
          </>
        )}
        {finished && <p className="mt-6 text-ink-muted">{t("listen_finished")}</p>}
        <p className="mt-8 max-w-xs text-sm text-ink-muted">{t("listen_hint")}</p>
      </div>

      {/* Controls */}
      <div className="flex items-center justify-center gap-6 pb-8">
        <button
          onClick={() => {
            stop();
            setIndex((i) => Math.max(0, i - 1));
          }}
          className="text-ink-muted"
          aria-label="Previous"
        >
          <SkipBack size={28} />
        </button>
        <button
          onClick={() => (playing ? stop() : playFrom(finished ? 0 : index))}
          className="flex h-16 w-16 items-center justify-center rounded-full bg-accent text-white shadow-lg"
          aria-label={playing ? "Pause" : "Play"}
        >
          {playing ? <Pause size={30} /> : <Play size={30} className="ml-1" />}
        </button>
        <button
          onClick={() => {
            stop();
            setIndex((i) => Math.min(cards.length - 1, i + 1));
          }}
          className="text-ink-muted"
          aria-label="Next"
        >
          <SkipForward size={28} />
        </button>
      </div>
    </div>
  );
}
