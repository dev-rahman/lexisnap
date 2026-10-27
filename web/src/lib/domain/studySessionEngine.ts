// Port of lib/app/modules/study_session/study_session_engine.dart.
//
// Pure logic with no React/Redux dependency, so the session rules can be
// reasoned about and tested without rendering anything.

import type { Flashcard, StudyMode } from "../data/models";
import { isDue } from "../data/models";
import type { ReviewGrade } from "./srs";

export type StudyStepKind = "choice" | "recall";

export interface StudyStep {
  card: Flashcard;
  kind: StudyStepKind;
  options: string[];
  answerIndex: number;
}

const OPTION_COUNT = 4;
/** A lapsed card comes back this many cards later. */
const REQUEUE_GAP = 3;
/** Longest run of one kind Smart mode allows before switching. */
const MAX_SAME_KIND_IN_A_ROW = 2;

type Rng = () => number;

function shuffle<T>(list: T[], rng: Rng): T[] {
  const a = [...list];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export class StudySessionEngine {
  readonly mode: StudyMode;
  readonly plannedTotal: number;
  readonly nothingWasDue: boolean;
  readonly skippedDueCount: number;
  readonly tally: Record<ReviewGrade, number> = {
    again: 0,
    hard: 0,
    good: 0,
    easy: 0,
  };

  private readonly pool: Flashcard[];
  private readonly rng: Rng;
  private queue: Flashcard[];
  private retired = 0;
  private step: StudyStep | null;
  private lastKind: StudyStepKind | null = null;
  private sameKindRun = 0;

  constructor(opts: {
    deck: Flashcard[];
    cap: number;
    mode?: StudyMode;
    rng?: Rng;
  }) {
    this.pool = [...opts.deck];
    this.rng = opts.rng ?? Math.random;
    this.mode = opts.mode ?? "smart";

    const due = opts.deck.filter((c) => isDue(c));
    this.nothingWasDue = due.length === 0;

    const selected = shuffle(this.nothingWasDue ? opts.deck : due, this.rng);
    this.queue = selected.slice(0, opts.cap);

    this.plannedTotal = this.queue.length;
    this.skippedDueCount = Math.max(0, due.length - this.plannedTotal);
    this.step = this.buildStep();
  }

  get currentStep(): StudyStep | null {
    return this.step;
  }

  get isComplete(): boolean {
    return this.step === null;
  }

  get reviewedCount(): number {
    return (
      this.tally.again + this.tally.hard + this.tally.good + this.tally.easy
    );
  }

  /** Cards retired over cards planned. Lapses deliberately don't advance it. */
  get progress(): number {
    return this.plannedTotal === 0 ? 0 : this.retired / this.plannedTotal;
  }

  get retiredCount(): number {
    return this.retired;
  }

  /** Share of answers recalled on the first try across the session. */
  get accuracy(): number {
    const total = this.reviewedCount;
    if (total === 0) return 0;
    return (total - this.tally.again) / total;
  }

  /** Records [grade] for the current step and moves to the next prompt. */
  complete(updated: Flashcard, grade: ReviewGrade): void {
    this.tally[grade] += 1;

    this.queue.shift();
    if (grade === "again") {
      this.queue.splice(Math.min(REQUEUE_GAP, this.queue.length), 0, updated);
    } else {
      this.retired += 1;
    }

    this.step = this.buildStep();
  }

  private buildStep(): StudyStep | null {
    if (this.queue.length === 0) return null;

    const card = this.queue[0];
    const distractors = this.distractorsFor(card);

    const canOfferChoice = distractors.length >= OPTION_COUNT - 1;
    let wantsChoice: boolean;
    switch (this.mode) {
      case "quiz":
        wantsChoice = true;
        break;
      case "flip":
        wantsChoice = false;
        break;
      default: // smart | listen
        wantsChoice = this.smartWantsChoice();
    }

    if (!canOfferChoice || !wantsChoice) {
      return this.served({ card, kind: "recall", options: [], answerIndex: -1 });
    }

    const options = shuffle([...distractors, card.translation], this.rng);
    return this.served({
      card,
      kind: "choice",
      options,
      answerIndex: options.indexOf(card.translation),
    });
  }

  private smartWantsChoice(): boolean {
    if (this.sameKindRun >= MAX_SAME_KIND_IN_A_ROW) {
      return this.lastKind === "recall";
    }
    return this.rng() < 0.5;
  }

  private served(step: StudyStep): StudyStep {
    this.sameKindRun = step.kind === this.lastKind ? this.sameKindRun + 1 : 1;
    this.lastKind = step.kind;
    return step;
  }

  /** Wrong answers drawn from other cards in the same target language. */
  private distractorsFor(card: Flashcard): string[] {
    const seen = new Set<string>([card.translation, card.word]);
    const candidates: string[] = [];

    for (const other of this.pool) {
      if (other.id === card.id) continue;
      if (other.targetLanguage !== card.targetLanguage) continue;
      if (!seen.has(other.translation)) {
        seen.add(other.translation);
        candidates.push(other.translation);
      }
    }

    return shuffle(candidates, this.rng).slice(0, OPTION_COUNT - 1);
  }
}
