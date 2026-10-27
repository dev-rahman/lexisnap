/// <reference lib="webworker" />

declare const self: ServiceWorkerGlobalScope & {
  __WB_MANIFEST: Array<{ url: string; revision: string | null }>;
};

// injectManifest needs this reference as its injection point. We keep a simple
// runtime cache keyed off the precache list rather than pulling in Workbox.
const PRECACHE = "lexisnap-v1";
const ASSETS = self.__WB_MANIFEST.map((e) => e.url);

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(PRECACHE).then((cache) => cache.addAll(["/", ...ASSETS]).catch(() => undefined)),
  );
  void self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== PRECACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

// Cache-first for same-origin GETs so the installed PWA opens offline.
self.addEventListener("fetch", (event: FetchEvent) => {
  const { request } = event;
  if (request.method !== "GET" || new URL(request.url).origin !== self.location.origin) return;
  event.respondWith(
    caches.match(request).then((hit) => hit ?? fetch(request).catch(() => caches.match("/") as Promise<Response>)),
  );
});

// Study-reminder push from the send-study-reminders edge function.
self.addEventListener("push", (event: PushEvent) => {
  let payload: { title?: string; body?: string } = {};
  try {
    payload = event.data?.json() ?? {};
  } catch {
    payload = { body: event.data?.text() };
  }
  event.waitUntil(
    self.registration.showNotification(payload.title ?? "LexiSnap", {
      body: payload.body ?? "Time for today's review 🔥",
      icon: "/icons/icon-192.png",
      badge: "/icons/icon-192.png",
      tag: "study-reminder",
    }),
  );
});

self.addEventListener("notificationclick", (event: NotificationEvent) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: "window" }).then((clients) => {
      for (const client of clients) if ("focus" in client) return client.focus();
      return self.clients.openWindow("/home");
    }),
  );
});
