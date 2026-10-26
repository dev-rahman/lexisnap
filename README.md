# LexiSnap

AI flashcards from anything you scan: snap text → AI extracts & translates the
vocabulary into decks → study with spaced repetition.

This is a monorepo with two clients sharing one backend.

```
lexisnap/
├── web-app/      Next.js web client (primary, PWA-ready)   → web-app/README.md
├── mobile-app/   Flutter app (iOS/Android)                 → mobile-app/README.md
├── supabase/     Shared backend: Postgres + RLS, Storage,  Edge Functions
└── docs/         EmailJS support-form templates (shared)
```

## Backend (shared)
`supabase/` holds the migrations, RLS policies, the `avatars` Storage bucket,
and the Edge Functions (`extract-vocabulary`, `translate-words`,
`delete-account`, `send-study-reminders`). Both clients talk to the **same**
Supabase project — the web rewrite changed no backend behaviour beyond adding
Web Push for reminders. Run `supabase` CLI commands from this root.

## Web app
```bash
cd web-app && npm install && npm run dev   # http://localhost:3000
```
Next.js + Redux Toolkit (RTK Query) + Supabase SSR + Tailwind. See
[web-app/README.md](web-app/README.md) for setup (Google OAuth, Web Push).

## Mobile app
```bash
cd mobile-app && flutter pub get && flutter run
```
Flutter + GetX + Supabase. See [mobile-app/SETUP.md](mobile-app/SETUP.md).

## Direction
The project is moving to web-first; the Flutter app is kept for now and can
later be replaced by a WebView wrapper around the web app if a store presence
is needed.
