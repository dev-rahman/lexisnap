# Build LexiSnap — a playful, gamified vocabulary web app (React + Vite)

You are building **LexiSnap**: scan any text with your camera → AI pulls out the
vocabulary worth learning and translates it → it becomes flashcard decks you
study with spaced repetition. Think "Duolingo energy" meets a snap‑to‑learn
tool.

This is a **web‑first** app (responsive for mobile, tablet, desktop) built as a
**React single‑page app with Vite**, reusing an existing **Supabase** backend.
The product logic is already specified below exactly — your job is a
**complete, production‑quality app with a genuinely delightful, playful UI**.
Previous attempts failed because the UI was a flat, timid, generic SaaS
dashboard. **Do not do that.** Read the "Design" section first and treat it as
the bar.

**Non‑negotiables:**
1. The UI must look **playful, warm, tactile and gamified** — not a flat admin panel.
2. It must be **fully responsive** and feel native on phone, tablet and desktop.
3. **Verify visually.** Set up Playwright, screenshot every screen at 3 widths,
   look at the screenshots, and keep iterating until each one looks great. Never
   hand off a screen you haven't looked at.
4. No bugs. `npm run build` (runs `tsc` + `vite build`) and the logic unit tests must pass.

---

## 1. Tech stack (pin these)

- **React 19 + Vite + TypeScript** (SPA — no SSR), `src/` dir, path alias
  `@/* → src/*` (set in both `vite.config.ts` via `resolve.alias` and
  `tsconfig.json` `paths`).
- **React Router v7** (`react-router-dom`, `createBrowserRouter`) for routing.
  There is no server, so auth gating is a **client‑side route guard** component,
  not middleware.
- **Tailwind CSS** (design tokens as CSS variables).
- **Redux Toolkit** + **RTK Query** (server state) + **redux-persist** (theme,
  locale, study-mode, streak → localStorage). Strict separation: pure logic in
  `src/lib/domain`, data in `src/lib/data`, state/controllers in `src/store`,
  presentational React in `src/components` + `src/routes`.
- **@supabase/supabase-js** for auth/session (single browser client,
  `persistSession: true`, `detectSessionInUrl: true` for the OAuth redirect).
- **tesseract.js** (OCR), Web Speech API (TTS), **web-push** (reminders — note
  the sender runs in a Supabase edge function, not in the SPA),
  **@marsidev/react-turnstile** (captcha), **lucide-react** (icons).
- A **rounded, friendly display font** loaded via **@fontsource** packages (or a
  Google Fonts `<link>` in `index.html`) — use **Baloo 2** or **Fredoka** for
  headings/numbers and **Plus Jakarta Sans** (or Nunito) for body. (The playful
  font choice matters a lot — don't use a generic geometric sans only.)
- **vite-plugin-pwa** for the installable PWA (manifest + service worker +
  Web Push handling).
- **Playwright** (dev dependency) for screenshot verification. **Vitest** for logic tests.

---

## 2. Design — this is the point. Make it playful.

**Mood:** bright, friendly, motivating, tactile. A learner should feel rewarded.
Reference feel: Duolingo, Finch, Gameful habit apps — rounded, colorful,
bouncy — but keep it clean and premium, not childish clutter.

**Commit to color and depth. Specifically avoid** (these are what the owner
rejected): flat white cards floating on grey; washed‑out/low‑contrast colors;
a cramped phone‑width column stretched across a desktop; generic Linear/Notion
minimalism; a dull navy box as the only color.

### Color (light mode — also ship a great dark mode)
- **Coral** `#F15A32` → primary actions, the brand. Use it boldly.
- **Ink navy** `#1B2038` → headings/text.
- **Paper** `#FBF7F0` warm cream → app background (warm, never cold grey).
- **Card** `#FFFFFF`.
- **Streak/flame** amber‑orange `#FF9F1C`. **Success** green `#2BB673`.
- **Deck identity palette** (use these to color decks + accents, don't be shy):
  teal `#17998F`, violet `#7C5CD3`, amber `#E39E36`, rose `#D65078`, sky `#3480C6`, moss `#569E48`.
- Use **soft tinted backgrounds** (e.g. `coral/10`, `teal/12`) behind icons and
  sections so the app feels colorful, not a sea of white.

### Tactility & motion (do this — it's what makes it feel gamified)
- **3D pressable buttons** (Duolingo‑style): a solid fill with a darker bottom
  "lip" (e.g. `box-shadow: 0 4px 0 <darker>`), that depresses on `:active`
  (translate‑y + remove the lip). Big, chunky, `rounded-2xl`/pill, confident labels.
- **Big rounded cards** (`rounded-3xl`), generous padding, soft layered shadows.
- **Animated progress**: a circular **goal ring** and streak bar that animate on
  load. A **streak flame** that grows with the streak number.
- **Study feedback**: correct answer → green pop + subtle **confetti**; wrong →
  shake + red. Card flip animation for recall.
- **Delightful empty states** with a friendly illustration/emoji and a clear CTA.
- Micro‑interactions everywhere: hover‑lift on cards, press‑scale, smooth
  transitions (150–250ms, ease‑out/spring). Don't overdo — keep it smooth.
- Optional: a small **mascot** motif (a cute scanner/owl/spark) for empty states
  and the completion screen. Keep it tasteful.

### Typography
- Headings & big numbers: rounded display font, **bold/extrabold**, large and
  confident (home greeting ~32–40px). Numbers (streak, %, counts) should feel
  like a scoreboard.
- Body: clean, readable, 15–16px.

### Layout / responsiveness
- **Mobile (<768px):** single column; a **floating rounded bottom tab bar**
  (Home · Scan center FAB in coral · Decks); content full‑width with 16px gutters.
- **Tablet/Desktop (≥768/≥1024):** a **left sidebar** (brand, Home, Decks, a
  highlighted Scan button, profile at bottom). Content centered with sensible
  max‑widths; decks in a **responsive grid** (2→3→4 cols). Never a tiny centered
  phone strip on desktop.
- Immersive screens (Study, Scan, Listen) are focused and centered with a max
  width (~640px), big tap targets.
- Respect iOS safe areas; works as an installable PWA.

### Concrete north‑star layouts
- **Home:** warm greeting ("Hi, {name} 👋"). A bold **"Today" hero**: a colorful
  (not dull‑navy) panel with an animated **goal ring**, a **streak flame + count**,
  the **7‑day streak strip** (lit days glow coral/amber, frozen days show a
  snowflake), and ONE chunky 3D CTA ("Review 12 cards →" or "Practice 10 more").
  Below: a vivid **Scan** card and a grid of colorful **deck tiles**.
- **Study:** top progress bar + counter; a big centered flashcard; for multiple
  choice, 4 chunky tactile option buttons that animate green/red on answer; for
  recall, a flip‑to‑reveal card with Forgot/Got‑it 3D buttons. End with a
  **celebration screen**: confetti, accuracy ring, streak increment, "Done".
- **Deck tile:** colored by the deck's hue (bold square/avatar with its initial),
  name, language flags (🇪🇸→🇬🇧), card count; hover‑lift.

Ship a **real dark mode** (deep navy canvas, slightly lighter cards, brighter
hues) and a theme toggle (System/Light/Dark).

---

## 3. Product — concept, features, and every screen

A vocabulary flashcard app. Core loop: **Scan → pick words → save deck → study
(spaced repetition) → keep a streak.**

### Auth & gating
- Email/password + **Google** (Supabase OAuth redirect flow) + password reset
  via emailed OTP code + email change via OTP. Optional **Cloudflare Turnstile**
  captcha on email auth when a site key is set.
- **Client‑side route guard** (a `<RequireAuth>` wrapper reading the Supabase
  session from the store): signed‑out users can't reach app routes (→ `/login`);
  signed‑in users skipping the auth flow go to `/home`. The splash route decides
  onboarding vs login vs home once the session is known. Show a loading state
  until the session is resolved so you never flash the wrong screen.

### Screens (build all; keep this flow)
1. **Splash** — routes to home/onboarding/login once session is known.
2. **Onboarding** — 4 playful intro slides (scan → we find words → example
   sentences → study), progress dots, "Get started".
3. **Login / Sign up / Forgot password** — forgot is a 3‑step OTP flow
   (email → code → new password) with a 60s resend cooldown.
4. **Home** — see north‑star above (greeting, Today hero, Scan card, recent decks).
5. **Decks** — stat row (Decks / Words / Due), a **"Mixed review"** panel (study
   everything due across decks), deck grid with infinite "load more", empty state.
6. **Deck detail** — header (name, language pair, due count), **Study** + **Listen**
   buttons, paginated card list, tap a card → detail. Multi‑select mode for bulk
   **move / copy / delete** and **merge into another deck**. Rename / delete deck.
   Enforce: a word can't appear twice in one deck (dedupe on add/move/copy/merge).
7. **Card detail / edit** — word + translation (each tappable to hear via TTS),
   definition, example sentences (listenable), SRS status (reviewed N times, next
   review in N days). Edit word/translation/description/examples. Delete.
8. **Scan** (the core feature) — a staged state machine:
   `pickingImage → reviewing → processing → wordSelection → savingDeck` (or `empty`).
   - Pick image: Take photo (`<input type=file accept=image/* capture=environment>`)
     or choose from gallery. Review the photo, then **Use photo**.
   - Run **OCR (Tesseract.js)** → if no text, show empty state. Then call the
     `extract-vocabulary` edge function (AI). On network/API failure, fall back
     to a local regex extractor. Fill any missing translations via `translate-words`.
   - **Word selection:** candidate words shown as selectable chips, **grouped by
     detected language** (a scan can mix languages). Select all / per‑group. A
     single deck holds one language — block a selection that spans languages.
   - **File selection → a deck:** either a **new deck** (pick target language +
     name, prefilled with the AI's suggested name) or an **existing deck**
     (translate into that deck's target language, skip duplicates). One scan can
     be filed into several decks in turn; closing shows a summary.
9. **Study session** — see north‑star. Modes: **Smart** (random mix of multiple‑
   choice and flip, capped at 2 of a kind in a row), **Quiz** (always 4 options),
   **Flip** (always recall), **Listen** (hands‑free, nothing graded). Grades are
   **inferred**, never chosen (see §5). Lapsed cards requeue a few cards later.
   Persist each review (unless practice‑only), credit the streak, celebrate.
10. **Listen session** — hands‑free TTS: speak word → pause → translation →
    pause → next; play/pause, prev/next. Nothing graded.
11. **Profile / settings** — avatar + name + email (→ edit profile), and settings:
    **Daily reminder** (Web Push toggle + time), **Study mode**, **Daily goal**
    (10/20/30/50), **Appearance** (System/Light/Dark), **Language** (5 options),
    Help & support, About, Sign out.
12. **Edit profile** — avatar upload (shrink to 256px, store in `avatars` bucket),
    name, change/set password (reauth for password accounts), links to change
    email + delete account.
13. **Change email** — OTP flow (Supabase secure email change sends a code to the
    new address, then one to the current address).
14. **Delete account** — deliberate multi‑step (understand + type "DELETE" +
    reauth) → calls `delete-account` edge function → wipe local state → login.
15. **Help** — FAQ accordion + contact form. The SPA has no server route, so send
    via the **EmailJS browser SDK** (`@emailjs/browser`, public key only) or a
    small `send-support-email` Supabase edge function, with a `mailto:` fallback.

---

## 4. Architecture & folders

```
src/
  main.tsx                     # mount React, Redux Provider + PersistGate, RouterProvider
  router.tsx                   # createBrowserRouter: route tree + <RequireAuth> guard
  routes/                      # route components (thin views)
    auth/login|signup|forgot-password
    app/home|decks|deck/$id|scan|study|listen|profile|edit-profile|change-email|delete-account|help
    onboarding/, auth-callback  (handles the OAuth redirect: reads session, routes on)
    splash  (index route), app-layout (authed shell: sidebar + bottom nav + <Outlet/>)
  lib/
    supabase/  (client.ts — single @supabase/supabase-js browser client)
    data/      (models.ts, repository.ts [typed Supabase CRUD], languages.ts)
    domain/    (PURE, framework-free, unit-tested — see §5)
    services/  (ocr.ts, tts.ts, push.ts, vocabulary.ts [edge fns], profilePhoto.ts, support.ts)
    auth/      (authService.ts, mapUser.ts)
    i18n/      (en/de/es/fr/ko message catalogs + translate())
    hooks/     (useScanController, useStudySession, useStreakView)
  store/
    index.ts (configureStore + persist), hooks.ts (typed), api/decksApi.ts (RTK Query),
    slices/ (auth, prefs, streak, scan, shell)
  components/
    ui/ (design system: Button[3D], Card, Chip, ProgressRing, StreakFlame,
         SegmentedControl, Field, Sheet/Modal, Toast, Skeleton, EmptyState, Confetti, Avatar)
    shell/ (Sidebar, BottomNav, AppShell, PageShell, TabScaffold)
    decks/, study/, streak/, brand/
  styles/globals.css
public/  manifest + icons (vite-plugin-pwa generates the service worker)
index.html
```

No `"use client"` directives and no Next.js imports — this is a plain React SPA.
Navigation uses React Router (`useNavigate`, `<Link>`, `<Outlet>`), not
`next/navigation` or `next/link`. Keep components **dumb**: business logic lives
in the store (slices + RTK Query) and the controller hooks; components read
selectors and dispatch.

---

## 5. Core domain logic — implement EXACTLY (these are correct and tested)

All pure TypeScript, no framework deps. Write Vitest tests for them.

### Study day (Anki‑style, 4am rollover)
Days run 4am→4am local. `studyDayStart(at)` = that day's 4am, or previous day's
4am if `at` is before 4am. `dueDateAfter(reviewedAt, intervalDays)` =
`studyDayStart(reviewedAt)` + `intervalDays` days, at 4am. `studyDaysBetween(a,b)`
= round(hours‑between‑their‑day‑starts / 24).

### SM‑2 spaced repetition
Grade → quality: `again=0, hard=3, good=4, easy=5`.
```
ef' = max(1.3, ef + (0.1 - (5-q)*(0.08 + (5-q)*0.02)))
if q < 3:  repetitions = 0; interval = 0            // lapse → due again today
else:      repetitions += 1
           interval = repetitions==1 ? 1 : repetitions==2 ? 6 : round(prevInterval * ef')
dueAt = dueDateAfter(now, interval)
```
New cards default `ef=2.5, interval=0, repetitions=0, dueAt=now` (immediately due).

### Grade inference (user never picks a grade)
Collect yes/no ("got it?") + time‑to‑answer. `!recalled → again`;
`≤4s → easy`; `≤10s → good`; else `hard`.

### Study‑session engine (pure class)
Input: cards, cap, mode. Due cards first (if none due → practice over all,
`nothingWasDue=true`); shuffle; take `cap`. Each step is `choice` (4 options:
the answer + 3 distractors drawn from OTHER cards **in the same target
language**, excluding the prompt word itself; needs ≥3 distractors else falls
back to recall) or `recall`. Mode: quiz=always choice, flip=always recall,
smart/listen=random but never >2 of the same kind in a row. On `again`, requeue
the card 3 positions later (don't advance "retired" count). Track tally,
progress (retired/planned), accuracy (1 − again‑rate).

### Streak + freezes (gamification, on‑device/persisted)
`dailyGoal` default 20 (clamp 5–100). `maxFreezes=2`, earn 1 freeze each **7**
streak‑days, keep **14** days of history. A study day counts if ≥1 card reviewed
(practice counts; listening doesn't). On launch/resume, `reconcile(now)`: reset
today's tally on a new day, then spend banked freezes to cover each missed day;
if missed > freezes, streak resets to 0 (freezes kept). `recordStudy(now, count)`:
extend streak if yesterday was active, else start at 1; earn a freeze when the
streak grows onto a multiple of 7. `week(now)` → last 7 days as studied/frozen/missed.

### Deck hue (stable color per deck)
FNV‑1a 32‑bit hash over the deck id's char codes, `% 6` →
`[teal, amber, violet, moss, rose, sky]`. (NOT `String.hashCode` — must be stable
across sessions/platforms.)

### Vocabulary extractor (offline fallback)
Regex `/[\p{L}][\p{L}'-]*/gu`, dedupe case‑insensitively (first‑seen order),
drop length <2, cap 150.

---

## 6. Backend — Supabase (reuse existing or recreate)

The backend already exists and is correct — **reuse it**. It's plain SQL + Deno
edge functions, portable to any Supabase project.

### Tables (RLS on; every row scoped to `auth.uid()`)
- **decks**: `id uuid pk`, `user_id uuid default auth.uid()` FK→auth.users cascade,
  `name text`, `source_language text?` (ISO code, null on local fallback),
  `target_language text`, `created_at timestamptz`, `notes text?`.
- **flashcards**: `id`, `deck_id` FK→decks cascade, `word text`, `level text?` (CEFR),
  `word_description text?`, `translation text`, `notes text?`, `audio_url text?`,
  `created_at`, + SM‑2: `ease_factor double precision default 2.5`,
  `interval_days int default 0`, `repetitions int default 0`,
  `due_at timestamptz default now()`, `last_reviewed_at timestamptz?`.
  Unique index on `(deck_id, lower(word))` (no dup word per deck).
- **example_sentences**: `id`, `flashcard_id` FK cascade, `sentence text`, `created_at`.
- **Storage bucket `avatars`** (public, 256KB, jpeg/png/webp; path `avatars/<uid>/<ts>.jpg`;
  RLS limits each user to their own folder).
- **Quota triggers** (SECURITY DEFINER): 200 decks/user, 1000 cards/deck, 20000 cards/user.
- **push_subscriptions**: `user_id`, `endpoint text unique`, `keys jsonb`, `created_at` (RLS).
- **user_reminders**: `user_id pk`, `enabled bool`, `hour int`, `minute int`,
  `timezone text`, `last_studied_at timestamptz?` (RLS). Needed so the reminder
  push can skip days already studied.

### Edge functions (Deno, `verify_jwt` default on)
- **extract-vocabulary**: input `{text, ui_language?}`. Calls **Groq**
  (`https://api.groq.com/openai/v1/chat/completions`, OpenAI‑compatible, model
  `openai/gpt-oss-120b`, `response_format: json_object`, `GROQ_API_KEY` secret).
  Returns `{words:[{word, level(A1–C2), word_description, example_sentence,
  language_code, translation}], language_code, language_name, suggested_deck_name}`.
  Validates/drops malformed entries. Prompt: pick 5–25 learnable words, CEFR level,
  a definition + one example sentence at that level in `ui_language`, per‑word ISO
  code (scans can mix languages), dominant source language, a thematic deck name.
- **translate-words**: input `{words:string[], source_language?, target_language}`
  → `{translations:[{word, translation}]}` (dictionary form). Same Groq key.
- **delete-account**: service‑role; deletes the caller's avatar files then
  `admin.auth.admin.deleteUser` (cascades decks/cards/sentences).
- **send-study-reminders**: scheduled via **pg_cron** (every ~15 min). Uses
  `web-push` + VAPID secrets; finds users whose local reminder time just passed
  and who haven't studied this study‑day, sends a push to their subscriptions,
  prunes dead (404/410) subscriptions.
- *(optional)* **send-support-email**: if you don't use the EmailJS browser SDK,
  add a tiny function the Help form posts to (keeps any mail provider key server‑side).

Call all edge functions from the SPA with `supabase.functions.invoke(name, { body })`.

### Env vars (client = `VITE_*`, read via `import.meta.env`; the rest are server/edge secrets)
Client (safe to ship; must be prefixed `VITE_` for Vite to expose them):
`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` (anon),
`VITE_TURNSTILE_SITE_KEY` (optional), `VITE_VAPID_PUBLIC_KEY`,
`VITE_SUPPORT_EMAIL`, and EmailJS public ids if using the browser SDK
(`VITE_EMAILJS_SERVICE_ID`, `VITE_EMAILJS_TEMPLATE_ID`, `VITE_EMAILJS_PUBLIC_KEY`).
Server/edge secrets (NEVER prefixed `VITE_`, set as Supabase function secrets):
`GROQ_API_KEY`, `VAPID_PRIVATE_KEY`, service role (auto), and any mail provider
key if you add `send-support-email`. Google OAuth is configured in the Supabase
dashboard (add `<origin>/auth/callback` to the Supabase Auth redirect URLs; add
`https://<ref>.supabase.co/auth/v1/callback` to the Google web client). Note Vite
only inlines `import.meta.env.VITE_*` at build time, so anything secret must stay
in an edge function, never in the client bundle.

---

## 7. Device features → web

| Native | Web |
|---|---|
| Camera / gallery | `<input type=file accept=image/* capture=environment>` |
| OCR (ML Kit) | **Tesseract.js** in a web worker (Latin bundle `eng+deu+fra+spa+ita+por+nld`; `kor`/`jpn`/`chi_sim` when the source hints CJK). Lower accuracy than native — acceptable; keep the pipeline swappable to a cloud OCR later. |
| TTS (flutter_tts) | **Web Speech API** `speechSynthesis`; map ISO code → BCP‑47 (en→en‑US, es→es‑ES, …, no→nb‑NO, tl→fil‑PH). `speak()` resolves on `end` so Listen mode can chain. |
| Local notifications | **Web Push** (service worker from vite-plugin-pwa + VAPID + the scheduled `send-study-reminders` function). Note: iOS requires the PWA installed to the home screen. |
| Google Sign‑In (ID token) | `supabase.auth.signInWithOAuth({provider:'google', options:{ redirectTo: \`\${location.origin}/auth/callback\` }})`; the `/auth/callback` route lets `detectSessionInUrl` finish, then navigates to `/home`. |
| Turnstile (webview) | `@marsidev/react-turnstile` inline, only when a site key is set. |
| SharedPreferences | redux-persist (localStorage): theme, locale, study mode, streak, reminder prefs. |

---

## 8. i18n

5 languages: **en, de, es, fr, ko** (English fallback). ~365 string keys
(snake_case) with `{param}` placeholders. A light `translate(locale, key, params)`
+ a React context/hook `useT()`; locale from the prefs slice; set
`document.documentElement.lang` when the locale changes (there's no server
`<html lang>` to set — do it from a small effect in the app shell). The picker
shows each language in its own script (English/Deutsch/Español/Français/한국어).
(If you can access the existing repo, the catalogs are at
`web-app/src/lib/i18n/messages/*.json` — reuse them verbatim.)

---

## 9. Quality bar & verification (do this, don't skip)

1. **Playwright screenshots.** Add Playwright. Write a script that boots the Vite
   dev server (or `vite preview` on a production build), signs in a test user (or
   stubs the Supabase session in localStorage), navigates each route, and captures
   screenshots at **390px (phone), 834px (tablet), 1440px (desktop)** in light AND
   dark mode. **Open the screenshots and critique them.** Iterate on each screen
   until it genuinely looks polished and on‑brand. Seed a little demo data (a
   couple of decks with cards) so Home/Decks/Study aren't empty.
2. `npm run build` (i.e. `tsc --noEmit && vite build`) must pass clean (no type
   errors, no unused).
3. `vitest run` — unit tests for SM‑2, grade inference, study‑day math, streak
   rules (incl. freezes), the session engine, and the deck‑hue hash.
4. Manually walk the full flow: sign up → scan (upload an image) → select words →
   save deck → study a session (check TTS + confetti) → see streak increment →
   toggle dark mode → resize phone↔desktop.

**Reject your own work** if a screen looks flat/generic/cramped. The owner's
explicit complaint was "flat, timid, generic, unusable" — the gamified tactile
look in §2 is the fix. Spend real effort on Home, Study, Decks, and the Scan flow.

---

## 10. If you have the existing repo at `/Users/rahman/lexisnap`

Reuse as‑is (they're correct and framework‑agnostic): `supabase/` (migrations +
all edge functions), `web-app/src/lib/domain/*` (SM‑2, study day, streak rules,
session engine, deck hue, vocab extractor — and their tests),
`web-app/src/lib/i18n/messages/*.json`, `web-app/src/lib/data/languages.ts`, and
the repository/service shapes. The existing `web-app/` is a **Next.js** build —
you are starting a fresh **React + Vite** app, so **do not copy its `app/`
routes, middleware, `@supabase/ssr` clients, `next/*` imports or `"use client"`
files.** Port the data/repository and service modules (strip any `next/*`
dependency), and **rebuild the entire UI and routing layer fresh** (Vite entry,
React Router tree, `components/`, route components, design tokens) in the playful
style. Keep the Redux/RTK Query architecture.

Build it beautifully. Ship something a real user would be happy to open every day.
