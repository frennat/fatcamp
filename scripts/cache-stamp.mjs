/* Stamps sw.js with a hash of what it actually caches.
 *
 * The service worker only refreshes an installed copy when CACHE changes, so a
 * forgotten bump means the phone keeps serving the old app and the change looks
 * like it never shipped. That was a hand-edit before, which is exactly the kind
 * of step that gets skipped at 1am on the fifth tweak of the evening.
 *
 * Content-derived rather than incrementing: rebuilding without changing
 * anything leaves the stamp alone, so identical builds don't churn the cache. */
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";

const files = ["index.html", "manifest.json"];
const h = createHash("sha256");
for (const f of files) h.update(readFileSync(f));
const stamp = h.digest("hex").slice(0, 10);

const sw = readFileSync("sw.js", "utf8");
const next = sw.replace(/const CACHE = "[^"]*";/, `const CACHE = "fatcamp-${stamp}";`);

if (next === sw) {
  const has = /const CACHE = "fatcamp-([^"]*)";/.exec(sw);
  if (!has) {
    console.error("cache-stamp: no CACHE constant found in sw.js");
    process.exit(1);
  }
  console.log(`  cache unchanged (${has[1]})`);
} else {
  writeFileSync("sw.js", next);
  console.log(`  cache stamped fatcamp-${stamp}`);
}
