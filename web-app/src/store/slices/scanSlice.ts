// The scan flow's staged state machine — ports ScanController's observable
// state. Orchestration (OCR, edge-function calls, saving) lives in the
// useScanController hook; this slice holds only the serialisable state.

import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

import type { VocabularyWord } from "@/lib/data/models";

export type ScanStage =
  | "pickingImage"
  | "reviewing"
  | "processing"
  | "wordSelection"
  | "savingDeck"
  | "empty";

export interface FiledBatch {
  name: string;
  count: number;
  isNew: boolean;
}

export interface ScanState {
  stage: ScanStage;
  imageDataUrl: string | null;
  candidateWords: VocabularyWord[];
  /** Lowercased words currently selected. */
  selectedKeys: string[];
  sourceLanguageCode: string | null;
  sourceLanguageName: string | null;
  suggestedDeckName: string | null;
  processingLabel: string | null;
  savingLabel: string | null;
  filedWordCount: number;
  filed: FiledBatch[];
}

const initialState: ScanState = {
  stage: "pickingImage",
  imageDataUrl: null,
  candidateWords: [],
  selectedKeys: [],
  sourceLanguageCode: null,
  sourceLanguageName: null,
  suggestedDeckName: null,
  processingLabel: null,
  savingLabel: null,
  filedWordCount: 0,
  filed: [],
};

const key = (w: VocabularyWord) => w.word.toLowerCase();

const scanSlice = createSlice({
  name: "scan",
  initialState,
  reducers: {
    resetScan: () => initialState,
    setStage(state, action: PayloadAction<ScanStage>) {
      state.stage = action.payload;
    },
    setImage(state, action: PayloadAction<string | null>) {
      state.imageDataUrl = action.payload;
      state.stage = action.payload ? "reviewing" : "pickingImage";
    },
    setProcessingLabel(state, action: PayloadAction<string | null>) {
      state.processingLabel = action.payload;
    },
    setSavingLabel(state, action: PayloadAction<string | null>) {
      state.savingLabel = action.payload;
    },
    setCandidates(
      state,
      action: PayloadAction<{
        words: VocabularyWord[];
        sourceLanguageCode: string | null;
        sourceLanguageName: string | null;
        suggestedDeckName: string | null;
      }>,
    ) {
      state.candidateWords = action.payload.words;
      state.selectedKeys = [];
      state.sourceLanguageCode = action.payload.sourceLanguageCode;
      state.sourceLanguageName = action.payload.sourceLanguageName;
      state.suggestedDeckName = action.payload.suggestedDeckName;
    },
    /** Overwrite candidates in place (e.g. after filling translations). */
    patchCandidates(state, action: PayloadAction<VocabularyWord[]>) {
      state.candidateWords = action.payload;
    },
    toggleWord(state, action: PayloadAction<string>) {
      const k = action.payload;
      const idx = state.selectedKeys.indexOf(k);
      if (idx >= 0) state.selectedKeys.splice(idx, 1);
      else state.selectedKeys.push(k);
    },
    toggleSelectAll(state) {
      const all = state.candidateWords.map(key);
      state.selectedKeys = state.selectedKeys.length === all.length ? [] : all;
    },
    toggleSelectAllInLanguage(state, action: PayloadAction<string | null>) {
      const group = state.candidateWords.filter(
        (w) => w.languageCode === action.payload,
      );
      const groupKeys = group.map(key);
      const allSelected = groupKeys.every((k) => state.selectedKeys.includes(k));
      if (allSelected) {
        state.selectedKeys = state.selectedKeys.filter(
          (k) => !groupKeys.includes(k),
        );
      } else {
        for (const k of groupKeys) {
          if (!state.selectedKeys.includes(k)) state.selectedKeys.push(k);
        }
      }
    },
    clearSelection(state) {
      state.selectedKeys = [];
    },
    /** Record a saved batch and drop its words from the candidate list. */
    recordBatch(
      state,
      action: PayloadAction<{ batch: FiledBatch; filedKeys: string[] }>,
    ) {
      state.filed.push(action.payload.batch);
      state.filedWordCount += action.payload.batch.count;
      const filed = new Set(action.payload.filedKeys);
      state.candidateWords = state.candidateWords.filter(
        (w) => !filed.has(key(w)),
      );
      state.selectedKeys = state.selectedKeys.filter((k) => !filed.has(k));
    },
  },
});

export const {
  resetScan,
  setStage,
  setImage,
  setProcessingLabel,
  setSavingLabel,
  setCandidates,
  patchCandidates,
  toggleWord,
  toggleSelectAll,
  toggleSelectAllInLanguage,
  clearSelection,
  recordBatch,
} = scanSlice.actions;
export default scanSlice.reducer;
