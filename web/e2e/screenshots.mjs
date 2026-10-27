// Screenshot harness: boots a running dev/preview server (BASE_URL), visits
// every screen at phone/tablet/desktop in light + dark, and writes PNGs to
// e2e/shots/. Authed screens use ?demo=1 (local fixtures, fake user).
//
//   BASE_URL=http://localhost:4173 node e2e/screenshots.mjs
import { chromium } from "@playwright/test";
import { mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const BASE = process.env.BASE_URL ?? "http://localhost:4173";
const OUT = join(dirname(fileURLToPath(import.meta.url)), "shots");
mkdirSync(OUT, { recursive: true });

const WIDTHS = { phone: 390, tablet: 834, desktop: 1440 };

// name, path, demo?, waitFor selector/text
const SCREENS = [
  { name: "onboarding", path: "/onboarding", demo: false },
  { name: "login", path: "/login", demo: false },
  { name: "signup", path: "/signup", demo: false },
  { name: "forgot", path: "/forgot-password", demo: false },
  { name: "home", path: "/home", demo: true },
  { name: "decks", path: "/decks", demo: true },
  { name: "deck-detail", path: "/deck/deck-es", demo: true },
  { name: "scan", path: "/scan", demo: true },
  { name: "study", path: "/study?deck=deck-es", demo: true, settle: 900 },
  { name: "listen", path: "/listen?deck=deck-es", demo: true, settle: 500 },
  { name: "profile", path: "/profile", demo: true },
  { name: "edit-profile", path: "/edit-profile", demo: true },
  { name: "change-email", path: "/change-email", demo: true },
  { name: "delete-account", path: "/delete-account", demo: true },
  { name: "help", path: "/help", demo: true },
];

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browser = await chromium.launch();
let count = 0;

for (const theme of ["light", "dark"]) {
  for (const [sizeName, width] of Object.entries(WIDTHS)) {
    const context = await browser.newContext({
      viewport: { width, height: sizeName === "phone" ? 844 : 1000 },
      colorScheme: theme,
      deviceScaleFactor: 1,
    });
    const page = await context.newPage();
    for (const s of SCREENS) {
      const url = BASE + s.path + (s.demo ? (s.path.includes("?") ? "&" : "?") + "demo=1" : "?demo=0");
      try {
        await page.goto(url, { waitUntil: "networkidle", timeout: 20000 });
      } catch {
        await page.goto(url, { waitUntil: "domcontentloaded", timeout: 20000 });
      }
      await sleep(s.settle ?? 450);
      const file = join(OUT, `${s.name}__${sizeName}__${theme}.png`);
      await page.screenshot({ path: file, fullPage: true }).catch(() => {});
      count++;
      process.stdout.write(`\r${count} shots…`);
    }
    await context.close();
  }
}

await browser.close();
console.log(`\nDone — ${count} screenshots in ${OUT}`);
