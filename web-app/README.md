# LexiSnap — Web (Next.js)

The web client for LexiSnap, ported from the Flutter app. It reuses the **same
Supabase backend** (`../supabase`): Postgres + RLS, the `avatars` Storage
bucket, and the Edge Functions (`extract-vocabulary`, `translate-words`,
`delete-account`, and the new `send-study-reminders`). This is a frontend
rewrite — no backend change beyond the Web Push additions.

## Stack
- **Next.js (App Router) + TypeScript**
- **Redux Toolkit** (slices + **RTK Query** for server state) with
  **redux-persist** (theme/locale/study-mode/streak kept in `localStorage`)
- **@supabase/ssr** for auth/session (middleware-gated routes)
- **Tailwind CSS** — design tokens ported from `app_colors.dart`
- **Tesseract.js** for OCR, **Web Speech API** for TTS, **Web Push** for reminders
- PWA: `public/manifest.webmanifest` + `public/sw.js`

## Architecture (MVC-style separation)
- `src/lib/domain/` — pure logic (SM-2, study engine, streak rules, study-day,
  deck hue, vocabulary extractor). Framework-free, unit-tested.
- `src/lib/data/` — models + the Supabase repository (plain typed module).
- `src/store/` — Redux slices + RTK Query (the "controller" tier).
- `src/components/`, `src/app/` — presentational React (the "view" tier).

## Getting started
```bash
cp .env.local.example .env.local   # already filled with the shared project
npm install
npm run dev                        # http://localhost:3000
```

## Scripts
- `npm run dev` — dev server
- `npm run build` / `npm start` — production
- `npm run typecheck` — `tsc --noEmit`
- `npm test` — Vitest (domain logic)

## Web Push reminders — setup
1. Generate VAPID keys: `npx web-push generate-vapid-keys`
2. Put the **public** key in `.env.local` as `NEXT_PUBLIC_VAPID_PUBLIC_KEY`.
3. Set the Supabase secrets for the function:
   ```bash
   supabase secrets set VAPID_PUBLIC_KEY=... VAPID_PRIVATE_KEY=... VAPID_SUBJECT=mailto:you@lexisnap.app
   supabase functions deploy send-study-reminders --no-verify-jwt
   ```
4. Apply the migration `supabase/migrations/20261026120000_web_push_reminders.sql`.
5. Schedule the function every ~15 min (pg_cron) — see the header comment in
   `supabase/functions/send-study-reminders/index.ts`.

> iOS requires the PWA to be installed to the home screen before Web Push works.

## Google sign-in
Uses Supabase OAuth (redirect flow). In the Supabase dashboard, add
`http://localhost:3000/auth/callback` (and your production origin) as a
redirect URL for the Google provider.

## Notes
- i18n catalogs in `src/lib/i18n/messages/*.json` were generated from the
  Flutter GetX translations (en/de/es/fr/ko).
- Tesseract OCR accuracy is lower than native ML Kit (esp. CJK); the scan
  pipeline can switch to a cloud-OCR edge function later with no caller change.
