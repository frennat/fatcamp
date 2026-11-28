// Pre-renders every 3D movement (ARCH) into a frame strip for the Apple Watch,
// which can't run the app's JS rig. One headless-Chrome pass over the rig
// harness draws N phases of each motion into a horizontal strip and dumps
// them as PNG data URLs; this script writes them into an asset catalog:
//   ios/App/FatcampWatch/Rigs.xcassets/rig_<key>.imageset/rig.png
// Usage: node tools/render-watch-rigs.mjs [--only key1,key2]
import { readFileSync, writeFileSync, mkdirSync, rmSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";

const ROOT = new URL("..", import.meta.url).pathname;
const FRAMES = 12, FW = 150, FH = 176;           // per-frame size in px (≈ 75×88 pt @2x)
const CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

execFileSync("node", [ROOT + "tools/build-rig-harness.mjs"], { stdio: "inherit" });
const harness = readFileSync(ROOT + "tools/rig-harness/index.html", "utf8");
const only = (process.argv.find((a, i) => process.argv[i - 1] === "--only") || "").split(",").filter(Boolean);

const exporter = harness.replace("</script></body>", `
;(function(){
  const keys = ${JSON.stringify(only)}.length ? ${JSON.stringify(only)} : Object.keys(ARCH);
  const out = {};
  const host = document.getElementById("host");
  for (const k of keys) {
    host.innerHTML = "";
    try {
      const ex = X.find(x => x.arch === k);           /* props (bar, dumbbells, bench) come from the exercise */
      const inst = mountRig(host, k, ex ? {x: ex} : {});
      inst.playing = false;
      const cv = host.querySelector("canvas");
      const strip = document.createElement("canvas");
      strip.width = ${FW} * ${FRAMES}; strip.height = ${FH};
      const g = strip.getContext("2d");
      for (let i = 0; i < ${FRAMES}; i++) {
        inst.rig.set(i / ${FRAMES});
        g.drawImage(cv, i * ${FW}, 0, ${FW}, ${FH});
      }
      out[k] = strip.toDataURL("image/png");
      RIGS.delete(inst);
    } catch (e) { out[k] = "ERR " + e.message; }
  }
  const pre = document.createElement("pre"); pre.id = "out"; pre.textContent = JSON.stringify(out);
  document.body.appendChild(pre);
})();
</script></body>`).replace(/const ex = \(q\.get\("x"\)[\s\S]*?window\.__ready = true;/, "");
const tmp = ROOT + "tools/rig-harness/export.html";
writeFileSync(tmp, exporter);
const dom = execFileSync(CHROME, ["--headless=new", "--disable-gpu", "--allow-file-access-from-files",
  `--window-size=${FW * 2},${FH * 2}`, "--virtual-time-budget=60000", "--dump-dom",
  `file://${tmp}?w=${FW * 2}&h=${FH * 2}`], { maxBuffer: 1 << 30, stdio: ["ignore", "pipe", "ignore"] }).toString();
const m = dom.match(/<pre id="out">([\s\S]*?)<\/pre>/);
if (!m) throw new Error("no output from the renderer");
const data = JSON.parse(m[1].replace(/&quot;/g, '"').replace(/&amp;/g, "&"));

const cat = ROOT + "ios/App/FatcampWatch/Rigs.xcassets/";
if (!only.length && existsSync(cat)) rmSync(cat, { recursive: true });
mkdirSync(cat, { recursive: true });
writeFileSync(cat + "Contents.json", JSON.stringify({ info: { author: "xcode", version: 1 } }));
let ok = 0, bad = [];
for (const [k, v] of Object.entries(data)) {
  if (!v.startsWith("data:image/png;base64,")) { bad.push(k + ": " + v); continue; }
  const dir = cat + `rig_${k}.imageset/`;
  mkdirSync(dir, { recursive: true });
  writeFileSync(dir + "rig.png", Buffer.from(v.split(",")[1], "base64"));
  writeFileSync(dir + "Contents.json", JSON.stringify({ images: [{ filename: "rig.png", idiom: "universal" }], info: { author: "xcode", version: 1 } }));
  ok++;
}
console.log(`  watch rigs: ${ok} strips (${FRAMES} frames, ${FW}x${FH})` + (bad.length ? `, ${bad.length} failed:\n   ` + bad.join("\n   ") : ""));
