// Text-to-speech via the Web Speech API — the web replacement for
// flutter_tts. Free, offline-ish (uses OS voices), no key. speak() resolves
// when the utterance finishes, which is what lets Listen mode chain
// word → pause → translation → pause without guessing durations.

import { TTS_LOCALE_BY_CODE } from "@/lib/data/languages";

export function ttsSupported(): boolean {
  return typeof window !== "undefined" && "speechSynthesis" in window;
}

export function speak(
  text: string,
  languageCode?: string | null,
): Promise<void> {
  if (!ttsSupported() || !text.trim()) return Promise.resolve();

  return new Promise<void>((resolve) => {
    const synth = window.speechSynthesis;
    synth.cancel(); // stop anything currently speaking

    const utterance = new SpeechSynthesisUtterance(text);
    const locale = languageCode ? TTS_LOCALE_BY_CODE[languageCode] : undefined;
    if (locale) {
      utterance.lang = locale;
      const voice = synth
        .getVoices()
        .find((v) => v.lang.toLowerCase().startsWith(locale.toLowerCase().slice(0, 2)));
      if (voice) utterance.voice = voice;
    }

    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      resolve();
    };
    utterance.onend = finish;
    utterance.onerror = finish;
    // Safety net: some browsers never fire onend for short clips.
    const timeout = setTimeout(finish, 15000);
    utterance.onend = () => {
      clearTimeout(timeout);
      finish();
    };

    synth.speak(utterance);
  });
}

export function stopSpeaking(): void {
  if (ttsSupported()) window.speechSynthesis.cancel();
}
