/* video-agent — Upload Media's video reader, server half.
 *
 * The app does the heavy lifting on the phone: it transcribes the video's
 * audio, OCRs the on-screen captions, and samples a handful of frames. All of
 * that arrives here, and a Claude agent turns it into ONE workout built from
 * that video alone: movements, equipment, sets, reps, rest, and for each
 * movement either a catalogue id (the app's own 3D figure), a time range to
 * cut a clip from the video, or — only when neither exists — a picture found
 * by image search.
 *
 * Gating is identical to read-workout (owner key or a verified Max JWS, then
 * the ai_read_tick meter) — the helpers below are copied from it verbatim.
 *
 * Deploy:  supabase functions deploy video-agent --no-verify-jwt
 * Secrets: ANTHROPIC_API_KEY, MODEL, OWNER_KEY (shared with read-workout)
 * Optional: GOOGLE_CSE_KEY + GOOGLE_CSE_CX  (image_search; without them the
 *           tool answers {"unavailable":true} and the movement ships bare)
 */

import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const BUNDLE = "com.frennat.fatcamp";
const MAX_ID = "com.frennat.fatcamp.max.monthly";

/* SHA-256 of Apple Root CA - G3, the root every real App Store transaction
 * chains to. Pinning the root (and verifying each signature down the chain)
 * is what stops a forged JWS that carries its own homemade certificates. */
const APPLE_ROOT_FP =
  Deno.env.get("APPLE_ROOT_FP") ||
  "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function reply(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64.replace(/-/g, "+").replace(/_/g, "/"));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

async function sha256hex(bytes: BufferSource): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/* ---- just enough DER to verify a certificate chain ----
 *
 * @peculiar/x509 kills the edge runtime at import, so the three things we
 * need from each certificate — its to-be-signed bytes, its signature, and
 * its public key — are cut straight out of the DER by hand. A certificate
 * is SEQ{ tbsCertificate, signatureAlgorithm, signature BITSTRING }, and
 * WebCrypto does the actual verifying. */

type TLV = { tag: number; hStart: number; start: number; end: number };

function derTLV(b: Uint8Array, at: number): TLV {
  const tag = b[at];
  let len = b[at + 1], next = at + 2;
  if (len & 0x80) {
    const n = len & 0x7f;
    len = 0;
    for (let i = 0; i < n; i++) len = len * 256 + b[at + 2 + i];
    next = at + 2 + n;
  }
  if (len < 0 || next + len > b.length) throw new Error("malformed certificate");
  return { tag, hStart: at, start: next, end: next + len };
}
function derChildren(b: Uint8Array, t: TLV): TLV[] {
  const out: TLV[] = [];
  let at = t.start;
  while (at < t.end) { const c = derTLV(b, at); out.push(c); at = c.end; }
  return out;
}
const rawOf = (b: Uint8Array, t: TLV) => b.subarray(t.hStart, t.end);
const bodyOf = (b: Uint8Array, t: TLV) => b.subarray(t.start, t.end);
const oidIs = (b: Uint8Array, t: TLV, hex: string) =>
  t.tag === 0x06 && [...bodyOf(b, t)].map((x) => x.toString(16).padStart(2, "0")).join("") === hex;

/* the only algorithms Apple's chain uses; anything else is refused */
function hashFor(b: Uint8Array, algSeq: TLV): string {
  const oid = derChildren(b, algSeq)[0];
  if (oidIs(b, oid, "2a8648ce3d040302")) return "SHA-256";  // ecdsa-with-SHA256
  if (oidIs(b, oid, "2a8648ce3d040303")) return "SHA-384";  // ecdsa-with-SHA384
  if (oidIs(b, oid, "2a8648ce3d040304")) return "SHA-512";  // ecdsa-with-SHA512
  throw new Error("unsupported certificate signature algorithm");
}

/* SubjectPublicKeyInfo sits in the tbs after version?, serial, sigAlg,
 * issuer, validity, subject — i.e. child 6 with the explicit version tag
 * (0xA0), child 5 without. */
function spkiOf(b: Uint8Array, cert: TLV): { spki: Uint8Array; curve: string; size: number } {
  const tbs = derChildren(b, cert)[0];
  const kids = derChildren(b, tbs);
  const spki = kids[kids[0].tag === 0xa0 ? 6 : 5];
  const curveOid = derChildren(b, derChildren(b, spki)[0])[1];
  if (oidIs(b, curveOid, "2a8648ce3d030107")) return { spki: rawOf(b, spki), curve: "P-256", size: 32 };
  if (oidIs(b, curveOid, "2b81040022"))       return { spki: rawOf(b, spki), curve: "P-384", size: 48 };
  throw new Error("unsupported certificate key type");
}

/* ECDSA signatures live in certificates as DER SEQ{r,s}; WebCrypto wants
 * raw r||s at the curve's width. */
function rawSig(b: Uint8Array, sigBits: TLV, size: number): Uint8Array {
  const der = bodyOf(b, sigBits).subarray(1);           // skip unused-bits byte
  const seq = derTLV(der, 0);
  const [r, s] = derChildren(der, seq);
  const out = new Uint8Array(size * 2);
  const put = (t: TLV, at: number) => {
    let v = bodyOf(der, t);
    while (v.length > size && v[0] === 0) v = v.subarray(1);
    out.set(v, at + size - v.length);
  };
  put(r, 0); put(s, size);
  return out;
}

/* is `cert` signed by `issuer`? */
async function signedBy(certDer: Uint8Array, issuerDer: Uint8Array): Promise<boolean> {
  const cert = derTLV(certDer, 0);
  const [tbs, sigAlg, sigBits] = derChildren(certDer, cert);
  const iss = spkiOf(issuerDer, derTLV(issuerDer, 0));
  const key = await crypto.subtle.importKey(
    "spki", iss.spki, { name: "ECDSA", namedCurve: iss.curve }, false, ["verify"]);
  return crypto.subtle.verify(
    { name: "ECDSA", hash: hashFor(certDer, sigAlg) },
    key, rawSig(certDer, sigBits, iss.size), rawOf(certDer, tbs));
}

function toPem(b64: string): string {
  return "-----BEGIN CERTIFICATE-----\n" +
    (b64.match(/.{1,64}/g) || []).join("\n") +
    "\n-----END CERTIFICATE-----";
}

/* Verify the StoreKit JWS end to end: chain signatures, root pin, JWS
 * signature against the leaf, then the claims. Returns the payload. Throws
 * with a human-sized reason on any failure. */
async function verifyTransaction(jws: string): Promise<Record<string, unknown>> {
  const header = jose.decodeProtectedHeader(jws);
  const x5c = header.x5c as string[] | undefined;
  if (!x5c || x5c.length < 2) throw new Error("transaction carries no certificate chain");

  const certs = x5c.map(b64ToBytes);

  /* Each certificate must be signed by the next one up, the root by itself,
   * and the root must be the pinned Apple root. Without this, anyone could
   * sign a payload with their own key and staple their own certificates on. */
  for (let i = 0; i < certs.length - 1; i++) {
    if (!(await signedBy(certs[i], certs[i + 1]))) {
      throw new Error("certificate chain does not verify");
    }
  }
  const root = certs[certs.length - 1];
  if (!(await signedBy(root, root))) throw new Error("root certificate does not verify");
  if ((await sha256hex(root)) !== APPLE_ROOT_FP.toLowerCase()) {
    throw new Error("chain does not end at Apple's root");
  }

  const key = await jose.importX509(toPem(x5c[0]), "ES256");
  const { payload } = await jose.compactVerify(jws, key);
  return JSON.parse(new TextDecoder().decode(payload));
}


/* ---------------------------------------------------------------------- */
/*  the agent                                                              */
/* ---------------------------------------------------------------------- */

type Span = { t0: number; t1: number; text: string };
type Frame = { t: number; b64: string };
type Row = { id: string; n: string; eq: string[] };

const MAX_TURNS = 6;
const MAX_SEARCHES = 8;

const SYSTEM = `You turn ONE workout video into ONE workout, built only from what that video teaches. You are the reader inside a fitness app: the phone has already transcribed the video's audio, read the text that appears on screen, and sampled frames. Your answer becomes a session the user will actually do and log, so every movement, number and time range must come from the video.

# What you are given
- DURATION of the video in seconds.
- TRANSCRIPT: speech-to-text of the audio, as [t0–t1] phrases. May be empty (music-only videos) and may contain recognition errors.
- CAPTIONS: on-screen text read by OCR, as [t0–t1] text. Short-form videos often show captions word by word, so consecutive lines form sentences — stitch them together in time order. OCR is noisy: correct obvious misreads ("TICHTENING" → tightening, "CYM" → gym) and ignore app chrome (usernames, like/comment counts, "Follow", "Original audio", "Add comment…", promotional lines like "DM me … for 1:1 training", "follow for more").
- FRAMES: still images sampled across the video, each labelled with its timestamp. They are sparse (often 1–1.5 s apart).
- CATALOG: the app's exercise library, one per line as \`id | name | equipment ids\`.
- MUSCLE IDS and EQUIPMENT IDS: the only ids you may use in pri, sec and equipment.

# How to read it
1. Speech and captions are the PRIMARY source. They usually name each movement and its prescription ("100 jumping jacks", "3 sets of 12", "rest 60 seconds", "each leg"). When transcript and captions say the same thing, they are one statement, not two.
2. Frames are SECONDARY. Use them to (a) confirm a named movement is really performed and find WHEN it is performed, (b) see the equipment, and (c) see body position and exact motion so you describe the movement correctly (standing vs lying, straight leg vs bent knee, alternating vs both legs).
3. A movement named in speech/captions is usually shown on screen around the moment it is named and until the next movement is named — but videos often start performing the first movement under an intro hook, before naming it. Place each movement by what the frames actually show, using the naming only as a guide.
4. Motivational talk ("your metabolism spikes", "abs start carving out", "no gym, no excuses") is not a movement. Program context ("every morning on an empty stomach", "do this for 14 days") goes in notes.

# The rules
- Include ONLY movements this video prescribes or performs. Never add warm-ups, cool-downs, or "complementary" exercises. Never pad. Keep the video's order. One entry per distinct movement.
- name: what the video calls it, in Title Case (e.g. "Jumping Jacks"). If the video never names it, give the plainest accurate name for what is filmed.
- sets: total sets of that movement the person performs. "100 jumping jacks" once = sets 1. A circuit done 3 rounds = rounds 3 AND sets 3 on each movement in it.
- reps: a string — an exact count ("100"), a range with an en dash ("8–10"), or a time ("30 s", "1 min"). unit is "sec" for timed work, else "reps". each = true only when the video says the count is per side/per leg/per arm ("10 each leg"). Alternating sides under one total count ("100 single leg raises") is each = false.
- If the video never gives a count, choose a sensible one for that movement and set source "inferred".
- rest_sec: only if the video mentions rest; otherwise null. Never invent rest.
- equipment: ids from EQUIPMENT IDS for what is actually used. Bodyweight on the floor/standing = "bw".
- pri / sec: muscle ids from MUSCLE IDS — primary movers, then meaningful secondary muscles.
- catalog_id: the catalog id ONLY when that entry is genuinely the SAME exercise as filmed — same body position, same equipment, same motion. A cousin is not a match: a standing straight-leg kick is not a lying or hanging leg raise; a lying knee tuck is not a hanging knee raise; a crunch reaching for the toes is not a V-up or a sit-up. Check the catalog honestly; when in doubt, null. Videos from social media usually have few or no true matches.
- clip: {t0, t1} in seconds — the stretch of the video where THIS movement is visibly being performed, so the app can cut it out as the movement's demo. Start it at the first frame where that motion is visibly being done (even if that is before the movement is named) and end it at the last such frame. Frames are sparse, so a range may extend to about halfway toward the neighbouring frames that show something else, but it must not include another movement, a title card, or a talking/posing shot. Clips of different movements must not overlap. Keep it within 0–DURATION. Typical length 2–8 s. null if the movement is never shown being performed.
- image_url: only for a movement with no catalog_id AND no clip. For those, call image_search with a precise query ("lying toe touch crunch exercise") and pick the result that best shows the movement; null if search is unavailable or nothing fits. Do not search for movements that have a clip or a catalog match.
- cue: one or two short coaching sentences in plain English, faithful to how it is done in the video.
- source: where the movement and its prescription came from — "speech" (transcript), "caption" (on-screen text), "visual" (only seen in frames), or "inferred" (prescription guessed).
- title: short (at most 40 characters), taken from the video's own hook or theme. notes: one or two sentences of program context the video gives (when, how often, for how long), or "" if none.

When you are finished, call submit_workout exactly once with the whole workout. Do not answer in prose.`;

const SUBMIT_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string" },
    notes: { type: "string" },
    rounds: { type: "integer" },
    movements: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          catalog_id: { type: ["string", "null"] },
          equipment: { type: "array", items: { type: "string" } },
          pri: { type: "array", items: { type: "string" } },
          sec: { type: "array", items: { type: "string" } },
          sets: { type: "integer" },
          reps: { type: "string" },
          unit: { type: "string", enum: ["reps", "sec"] },
          each: { type: "boolean" },
          rest_sec: { type: ["integer", "null"] },
          clip: {
            type: ["object", "null"],
            properties: { t0: { type: "number" }, t1: { type: "number" } },
            required: ["t0", "t1"],
          },
          image_url: { type: ["string", "null"] },
          cue: { type: "string" },
          source: { type: "string", enum: ["speech", "caption", "visual", "inferred"] },
        },
        required: ["name", "catalog_id", "equipment", "pri", "sec", "sets", "reps",
          "unit", "each", "rest_sec", "clip", "image_url", "cue", "source"],
      },
    },
  },
  required: ["title", "notes", "rounds", "movements"],
};

const TOOLS: Anthropic.Tool[] = [
  {
    name: "image_search",
    description:
      "Search the web for pictures of an exercise. Use ONLY for a movement that has no catalog match " +
      "and is never shown being performed in the video. Returns up to 3 image URLs with titles, or " +
      '{"unavailable": true} when search is not configured.',
    input_schema: {
      type: "object",
      properties: { query: { type: "string", description: "precise exercise description, e.g. 'lying toe touch crunch exercise'" } },
      required: ["query"],
    },
  },
  {
    name: "submit_workout",
    description: "Submit the finished workout. Call exactly once, as your final action.",
    input_schema: { type: "object", properties: { workout: SUBMIT_SCHEMA }, required: ["workout"] } as Anthropic.Tool.InputSchema,
  },
];

async function imageSearch(query: string): Promise<unknown> {
  const key = Deno.env.get("GOOGLE_CSE_KEY") || "";
  const cx = Deno.env.get("GOOGLE_CSE_CX") || "";
  if (!key || !cx) return { unavailable: true };
  const q = String(query || "").slice(0, 120);
  if (!q) return { error: "empty query" };
  const u = new URL("https://www.googleapis.com/customsearch/v1");
  u.searchParams.set("key", key);
  u.searchParams.set("cx", cx);
  u.searchParams.set("q", q);
  u.searchParams.set("searchType", "image");
  u.searchParams.set("num", "3");
  u.searchParams.set("safe", "active");
  try {
    const r = await fetch(u, { signal: AbortSignal.timeout(8000) });
    if (!r.ok) return { error: `search failed (${r.status})` };
    const j = await r.json();
    const results = (j.items || [])
      .filter((it: { link?: string }) => typeof it.link === "string" && it.link.startsWith("https://"))
      .slice(0, 3)
      .map((it: { link: string; title?: string }) => ({ url: it.link, title: it.title || "" }));
    return { results };
  } catch {
    return { error: "search timed out" };
  }
}

const fmt = (n: number) => (Math.round(n * 10) / 10).toFixed(1);
const str = (v: unknown, max: number, dflt = "") =>
  typeof v === "string" ? v.trim().slice(0, max) : dflt;
const int = (v: unknown, lo: number, hi: number, dflt: number) => {
  const n = Math.round(Number(v));
  return Number.isFinite(n) ? Math.min(hi, Math.max(lo, n)) : dflt;
};

/* The model's answer is checked field by field: ids against the lists the
 * app sent, numbers into sane ranges, clips into the video's own length. */
function sanitize(
  w: Record<string, unknown>, duration: number, catalog: Map<string, Row>,
  muscles: Set<string>, equipment: Set<string>,
) {
  const mv = Array.isArray(w.movements) ? w.movements : [];
  const movements = [];
  for (const raw of mv.slice(0, 30)) {
    if (!raw || typeof raw !== "object") continue;
    const m = raw as Record<string, unknown>;
    const name = str(m.name, 80);
    if (!name) continue;
    const cid = typeof m.catalog_id === "string" && catalog.has(m.catalog_id) ? m.catalog_id : null;
    const ids = (v: unknown, ok: Set<string>) =>
      [...new Set((Array.isArray(v) ? v : []).filter((x): x is string => typeof x === "string" && ok.has(x)))];
    let eq = ids(m.equipment, equipment);
    if (!eq.length && cid) eq = catalog.get(cid)!.eq.filter((e) => equipment.has(e));
    if (!eq.length && equipment.has("bw")) eq = ["bw"];
    const pri = ids(m.pri, muscles);
    const sec = ids(m.sec, muscles).filter((x) => !pri.includes(x));
    let clip: { t0: number; t1: number } | null = null;
    const c = m.clip as Record<string, unknown> | null;
    if (c && typeof c === "object") {
      const t0 = Math.max(0, Math.min(duration, Number(c.t0)));
      const t1 = Math.max(0, Math.min(duration, Number(c.t1)));
      if (Number.isFinite(t0) && Number.isFinite(t1) && t1 - t0 >= 0.5) {
        clip = { t0: Math.round(t0 * 10) / 10, t1: Math.round(t1 * 10) / 10 };
      }
    }
    let image_url: string | null = str(m.image_url, 1000) || null;
    if (image_url && !/^https:\/\//.test(image_url)) image_url = null;
    if (cid || clip) image_url = null;
    const unit = m.unit === "sec" ? "sec" : "reps";
    const rest = m.rest_sec === null || m.rest_sec === undefined ? null : int(m.rest_sec, 0, 600, 0);
    const source = ["speech", "caption", "visual", "inferred"].includes(String(m.source))
      ? String(m.source) : "inferred";
    movements.push({
      name, catalog_id: cid, equipment: eq, pri, sec,
      sets: int(m.sets, 1, 20, 1),
      reps: str(m.reps, 20) || (unit === "sec" ? "30 s" : "10"),
      unit, each: m.each === true, rest_sec: rest, clip, image_url,
      cue: str(m.cue, 300), source,
    });
  }
  return {
    title: str(w.title, 60) || "Video workout",
    notes: str(w.notes, 400),
    rounds: int(w.rounds, 1, 20, 1),
    movements,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reply(405, { error: "POST only" });

  let body: {
    jws?: string;
    owner?: string;
    duration?: number;
    transcript?: Span[];
    captions?: Span[];
    frames?: Frame[];
    catalog?: Row[];
    muscles?: string[];
    equipment?: string[];
  };
  try {
    body = await req.json();
  } catch {
    return reply(400, { error: "the request was not JSON" });
  }

  /* ---- size gates, before any money moves ---- */
  const duration = Number(body.duration);
  if (!Number.isFinite(duration) || duration <= 0 || duration > 3600) {
    return reply(400, { error: "duration missing or out of range" });
  }
  const spans = (v: unknown, name: string): Span[] | string => {
    if (v === undefined || v === null) return [];
    if (!Array.isArray(v) || v.length > 2000) return `${name} is malformed or too long`;
    const out: Span[] = [];
    for (const s of v) {
      if (!s || typeof s.text !== "string" || s.text.length > 500 ||
          !Number.isFinite(Number(s.t0)) || !Number.isFinite(Number(s.t1))) {
        return `${name} rows are malformed`;
      }
      const text = s.text.trim();
      if (text) out.push({ t0: Number(s.t0), t1: Number(s.t1), text });
    }
    return out;
  };
  const transcript = spans(body.transcript, "transcript");
  if (typeof transcript === "string") return reply(400, { error: transcript });
  const captions = spans(body.captions, "captions");
  if (typeof captions === "string") return reply(400, { error: captions });

  const framesIn = Array.isArray(body.frames) ? body.frames : [];
  if (framesIn.length > 24) return reply(400, { error: "at most 24 frames" });
  const frames: Frame[] = [];
  for (const f of framesIn) {
    if (!f || typeof f.b64 !== "string" || !f.b64 || f.b64.length > 1_000_000 ||
        !Number.isFinite(Number(f.t))) {
      return reply(400, { error: "a frame is malformed or too large" });
    }
    frames.push({ t: Number(f.t), b64: f.b64.replace(/^data:[^,]*,/, "") });
  }
  if (!transcript.length && !captions.length && !frames.length) {
    return reply(400, { error: "nothing to read: no transcript, captions or frames" });
  }

  const catalogIn = Array.isArray(body.catalog) ? body.catalog : [];
  if (!catalogIn.length || catalogIn.length > 400) {
    return reply(400, { error: "catalog missing or oversized" });
  }
  for (const c of catalogIn) {
    if (!c || typeof c.id !== "string" || typeof c.n !== "string" ||
        c.id.length > 40 || c.n.length > 80 ||
        (c.eq !== undefined && (!Array.isArray(c.eq) || c.eq.length > 12))) {
      return reply(400, { error: "catalog rows are malformed" });
    }
  }
  const idList = (v: unknown) =>
    Array.isArray(v) && v.length <= 100 && v.every((x) => typeof x === "string" && x.length <= 40)
      ? (v as string[]) : null;
  const muscleIds = idList(body.muscles);
  const equipIds = idList(body.equipment);
  if (!muscleIds || !muscleIds.length || !equipIds || !equipIds.length) {
    return reply(400, { error: "muscles and equipment lists are required" });
  }

  /* ---- owner key (same as read-workout) ---- */
  const ownerKey = Deno.env.get("OWNER_KEY") || "";
  const isOwner = ownerKey.length >= 32 && typeof body.owner === "string" &&
    body.owner.length === ownerKey.length &&
    (await sha256hex(new TextEncoder().encode(body.owner))) ===
      (await sha256hex(new TextEncoder().encode(ownerKey)));

  /* ---- entitlement (same as read-workout) ---- */
  let tx: Record<string, unknown> = {};
  if (!isOwner) {
    if (typeof body.jws !== "string" || !body.jws) {
      return reply(401, { error: "no subscription proof" });
    }
    try {
      tx = await verifyTransaction(body.jws);
    } catch {
      if (Deno.env.get("ALLOW_SANDBOX") === "true") {
        try {
          tx = jose.decodeJwt(body.jws) as Record<string, unknown>;
          const env = String(tx.environment || "");
          if (env !== "Sandbox" && env !== "Xcode") throw new Error("not a sandbox transaction");
        } catch {
          return reply(401, { error: "subscription proof did not verify" });
        }
      } else {
        return reply(401, { error: "subscription proof did not verify" });
      }
    }
    if (tx.bundleId !== BUNDLE) return reply(401, { error: "wrong app" });
    if (tx.productId !== MAX_ID) return reply(403, { error: "reading media is a Max feature" });
    if (tx.revocationDate) return reply(403, { error: "that subscription was refunded" });
    const expires = Number(tx.expiresDate || 0);
    if (!expires || expires < Date.now()) return reply(403, { error: "that Max subscription has lapsed" });
  }

  /* ---- metering (same meter and keys as read-workout) ---- */
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const monthlyCap = isOwner
    ? Number(Deno.env.get("OWNER_MONTHLY_CAP") || 300)
    : Number(Deno.env.get("MONTHLY_CAP") || 30);
  const dailyCap = Number(Deno.env.get("GLOBAL_DAILY_CAP") || 400);
  const subject = isOwner ? "owner" : String(tx.originalTransactionId || tx.transactionId || "unknown");
  const month = new Date().toISOString().slice(0, 7);
  const day = new Date().toISOString().slice(0, 10);

  const mine = await db.rpc("ai_read_tick", { p_key: `sub:${subject}:${month}`, p_cap: monthlyCap });
  if (mine.error) return reply(500, { error: "the meter is down" });
  if (mine.data < 0) return reply(429, { error: `that's all ${monthlyCap} reads for this month` });

  const all = await db.rpc("ai_read_tick", { p_key: `all:${day}`, p_cap: dailyCap });
  if (all.error) return reply(500, { error: "the meter is down" });
  if (all.data < 0) return reply(503, { error: "the reader is at capacity today — try tomorrow" });

  /* ---- the agent ---- */
  const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });
  const model = Deno.env.get("MODEL") || "claude-opus-5";

  const catalog = new Map<string, Row>(
    catalogIn.map((c) => [c.id, { id: c.id, n: c.n, eq: (c.eq || []).filter((e) => typeof e === "string") }]),
  );
  const muscles = new Set(muscleIds);
  const equipment = new Set(equipIds);
  const lines = (s: Span[]) =>
    s.length ? s.sort((a, b) => a.t0 - b.t0).map((x) => `[${fmt(x.t0)}–${fmt(x.t1)}] ${x.text}`).join("\n")
      : "(none)";

  const content: Anthropic.ContentBlockParam[] = [{
    type: "text",
    text:
      `DURATION: ${fmt(duration)} s\n\n` +
      `TRANSCRIPT (speech):\n${lines(transcript)}\n\n` +
      `CAPTIONS (on-screen text, OCR):\n${lines(captions)}\n\n` +
      `MUSCLE IDS: ${muscleIds.join(", ")}\n` +
      `EQUIPMENT IDS: ${equipIds.join(", ")}\n\n` +
      `CATALOG (id | name | equipment):\n` +
      [...catalog.values()].map((c) => `${c.id} | ${c.n} | ${c.eq.join(",")}`).join("\n") +
      `\n\nFRAMES (${frames.length}, in time order):`,
  }];
  for (const f of frames.sort((a, b) => a.t - b.t)) {
    content.push({ type: "text", text: `frame t=${fmt(f.t)}s` });
    content.push({ type: "image", source: { type: "base64", media_type: "image/jpeg", data: f.b64 } });
  }
  content.push({
    type: "text",
    text: "Build the workout this video teaches, following the rules, then call submit_workout.",
  });

  const messages: Anthropic.MessageParam[] = [{ role: "user", content }];
  const outputConfig: Record<string, unknown> = {};
  if (!model.includes("haiku")) outputConfig.effort = "medium";
  let searches = 0;

  try {
    for (let turn = 0; turn < MAX_TURNS; turn++) {
      const res = await anthropic.messages.create({
        model,
        max_tokens: 16000,
        system: SYSTEM,
        tools: TOOLS,
        ...(Object.keys(outputConfig).length ? { output_config: outputConfig } : {}),
        messages,
      } as Anthropic.MessageCreateParamsNonStreaming);

      if (res.stop_reason === "refusal") {
        return reply(422, { error: "the AI declined to read that one" });
      }
      messages.push({ role: "assistant", content: res.content });

      const uses = res.content.filter((b): b is Anthropic.ToolUseBlock => b.type === "tool_use");
      const submit = uses.find((u) => u.name === "submit_workout");
      if (submit) {
        const inp = submit.input as Record<string, unknown>;
        const w = (inp && typeof inp.workout === "object" && inp.workout) ? inp.workout : inp;
        const workout = sanitize(w as Record<string, unknown>, duration, catalog, muscles, equipment);
        if (!workout.movements.length) {
          return reply(422, { error: "no workout movements were found in that video" });
        }
        return reply(200, { workout, left: mine.data });
      }

      if (!uses.length) {
        messages.push({
          role: "user",
          content: "Call submit_workout now with the finished workout. Do not answer in prose.",
        });
        continue;
      }

      const results: Anthropic.ToolResultBlockParam[] = [];
      for (const u of uses) {
        if (u.name === "image_search") {
          const q = String((u.input as { query?: unknown })?.query || "");
          const out = ++searches > MAX_SEARCHES ? { error: "search limit reached" } : await imageSearch(q);
          results.push({ type: "tool_result", tool_use_id: u.id, content: JSON.stringify(out) });
        } else {
          results.push({
            type: "tool_result", tool_use_id: u.id, is_error: true,
            content: `unknown tool ${u.name}`,
          });
        }
      }
      messages.push({ role: "user", content: results });
    }
    return reply(502, { error: "the AI did not finish building the workout" });
  } catch (e) {
    console.error("video agent failed:", e);
    return reply(502, { error: "the AI could not be reached" });
  }
});
