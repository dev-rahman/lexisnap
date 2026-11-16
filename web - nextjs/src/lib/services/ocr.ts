// On-device OCR via Tesseract.js (WASM) — the web replacement for Google ML
// Kit. Free, no API key, runs entirely in the browser. Accuracy is lower than
// ML Kit, especially for CJK; the pipeline can swap to a cloud OCR edge
// function later without any caller change.

import Tesseract, { type Worker } from "tesseract.js";

// A Latin bundle covering the app's non-CJK languages; Korean adds "kor".
const LATIN_LANGS = "eng+deu+fra+spa+ita+por+nld";

let workerPromise: Promise<Worker> | null = null;
let workerLangs = "";

async function getWorker(langs: string): Promise<Worker> {
  if (workerPromise && workerLangs === langs) return workerPromise;
  if (workerPromise) {
    const w = await workerPromise;
    await w.terminate();
    workerPromise = null;
  }
  workerLangs = langs;
  workerPromise = Tesseract.createWorker(langs);
  return workerPromise;
}

/**
 * Picks the OCR language set from an optional source-language hint. Korean
 * needs its own model; everything else falls back to the Latin bundle.
 */
function langsForHint(sourceLanguageHint?: string | null): string {
  if (sourceLanguageHint === "ko") return "kor+eng";
  if (sourceLanguageHint === "ja") return "jpn+eng";
  if (sourceLanguageHint === "zh") return "chi_sim+eng";
  return LATIN_LANGS;
}

/** Recognises text in an image (data URL, Blob, or File). */
export async function recognizeText(
  image: string | Blob | File,
  sourceLanguageHint?: string | null,
): Promise<string> {
  const worker = await getWorker(langsForHint(sourceLanguageHint));
  const { data } = await worker.recognize(image);
  return data.text ?? "";
}
