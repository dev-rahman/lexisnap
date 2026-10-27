# LexiSnap — Web (React + Vite)

Playful, gamified vocabulary flashcard SPA. Scan text → AI extracts the words
worth learning → study with spaced repetition → keep a streak.

Built as a **React 19 + Vite + TypeScript** single-page app, reusing the shared
Supabase backend in `../supabase` and the framework-agnostic domain/i18n/data
logic ported from the earlier Next.js build in `../web-app`.

## Stack

- React 19 + Vite 6 + TypeScript (SPA, no SSR)
- React Router v7 (`createBrowserRouter`) with a client-side `<RequireAuth>` guard
- Redux Toolkit + RTK Query + redux-persist (theme, locale, study mode, streak)
- `@supabase/supabase-js` (single browser client; `persistSession` + `detectSessionInUrl`)
- Tailwind CSS (tokens as CSS variables), Baloo 2 + Plus Jakarta Sans
- tesseract.js (OCR), Web Speech API (TTS), Web Push, Turnstile, lucide-react
- vite-plugin-pwa (installable PWA + push service worker)
- Vitest (domain tests) + Playwright (screenshot verification)

## Getting started

```bash
cp .env.local.example .env.local   # fill in VITE_SUPABASE_* (others optional)
npm install
npm run dev                         # http://localhost:5173
```

### Scripts

| Script | What it does |
| --- | --- |
| `npm run dev` | Vite dev server |
| `npm run build` | `tsc --noEmit` + `vite build` |
| `npm run preview` | Serve the production build on :4173 |
| `npm run test` | Vitest — SM-2, grade inference, study-day, streak, session engine, deck hue |
| `npm run shots` | Playwright screenshots of every screen (needs a running server) |

## Demo mode

Append `?demo=1` to any URL (or build with `VITE_DEMO=1`) to run the full authed
app against local fixtures with a fake user — no Supabase round-trips. Used for
screenshot verification and offline previews. `?demo=0` clears it.

## Architecture

```
src/
  main.tsx                 mount Redux + PersistGate + RouterProvider
  router.tsx               route tree + guards (heavy routes are code-split)
  routes/                  thin route views (auth/, app/)
  providers/               I18n, Theme, AuthListener, route guards
  components/ ui|shell|decks|study|streak|brand|auth
  lib/
    domain/                PURE, unit-tested (SM-2, streak, session engine, …)
    data/                  models, languages, repository (+ demo facade)
    services/              ocr, tts, push, vocabulary, profilePhoto, support
    auth/ · i18n/ · hooks/ · supabase/ · demo/
  store/                   slices + RTK Query (decksApi)
  sw.ts                    PWA service worker (precache + Web Push)
```

Pure logic lives in `lib/domain`; data access in `lib/data`; state/controllers in
`store` + `lib/hooks`; components stay presentational.

## Screenshot verification

`e2e/screenshots.mjs` captures each screen at 390 / 834 / 1440 px in light and
dark, into `e2e/shots/`. Run against a live server:

```bash
npm run build && npm run preview &
BASE_URL=http://localhost:4173 npm run shots
```
