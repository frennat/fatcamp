// Builds tools/rig-harness/index.html: just the 3D movement rig, outside the app,
// for authoring and checking ARCH poses (and rendering watch frames).
// Usage: node tools/build-rig-harness.mjs [path/to/index.html]
// Open: tools/rig-harness/index.html?arch=<key>&phase=<0..1>   (phase omitted = animate)
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
const src = process.argv[2] || new URL("../index.html", import.meta.url).pathname;
const html = readFileSync(src, "utf8");
const css = (html.match(/<style>([\s\S]*?)<\/style>/) || [,""])[1];
const a = html.indexOf("/* ---------------------------------------------------------------- muscles */");
const b = html.indexOf("/* --------------------------------------------------------------- equipment */");
if (a < 0 || b < 0) throw new Error("rig region markers not found");
const c = html.indexOf("/* ------------------------------------------------------------------ focus */");
if (c < 0) throw new Error("focus marker not found");
/* the rig, then the equipment + exercise catalog (props come from the exercise) */
let js = (html.slice(a, b) + html.slice(b, c)).replace(/\/\* @forge:(begin|end)[^*]*\*\/\n/g, "");
const page = `<!doctype html><html><head><meta charset="utf-8"><style>${css}
html,body{margin:0;background:#17161A} #host{width:${"${W}"}px;height:${"${H}"}px}
</style></head><body><div id="host"></div><script>
const W = +(new URLSearchParams(location.search).get("w")||360), H = +(new URLSearchParams(location.search).get("h")||420);
document.getElementById("host").style.width = W+"px"; document.getElementById("host").style.height = H+"px";
const $ = s => document.querySelector(s), $$ = s => [...document.querySelectorAll(s)];
${js}
const q = new URLSearchParams(location.search);
const key = q.get("arch") || "squat";
window.__ARCH_KEYS = Object.keys(ARCH);
const ex = (q.get("x") && XMAP[q.get("x")]) || X.find(x => x.arch === key);
const inst = mountRig(document.getElementById("host"), key, ex ? {x: ex} : {});
if (q.has("phase")) { inst.playing = false; inst.rig.set(+q.get("phase")); }
window.__ready = true;
</script></body></html>`;
mkdirSync(new URL("./rig-harness/", import.meta.url), { recursive: true });
writeFileSync(new URL("./rig-harness/index.html", import.meta.url), page);
console.log("harness written,", js.length, "chars of rig code");
