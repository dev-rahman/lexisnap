import { chromium } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const OUT = join(dirname(fileURLToPath(import.meta.url)), "shots");
const browser = await chromium.launch();
for (const [w, h, name] of [[390, 844, "phone"], [1440, 1000, "desktop"]]) {
  for (const theme of ["light", "dark"]) {
    const ctx = await browser.newContext({ viewport: { width: w, height: h }, colorScheme: theme });
    const page = await ctx.newPage();
    await page.goto("http://localhost:4173/home?demo=1", { waitUntil: "networkidle" });
    await page.waitForTimeout(500);
    await page.getByRole("button", { name: "Scan" }).first().click();
    await page.waitForTimeout(500);
    await page.screenshot({ path: `${OUT}/scan-dialog__${name}__${theme}.png`, fullPage: false });
    await ctx.close();
  }
}
await browser.close();
console.log("dialog shots done");
