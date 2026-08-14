/* read-workout — the Upload Media reader's server half.
 *
 * The app pulls frames out of a photo or clip on the device and sends them
 * here; Claude looks at them — names on screen and movements being performed
 * both — and answers with catalogue ids the app already knows how to forge.
 *
 * This function exists because the Anthropic key can never ship inside
 * index.html: the app is a public single file, so anything in it belongs to
 * everyone. The key lives here as a secret, and three gates stand in front
 * of it:
 *
 *   1. Entitlement. The request must carry the App Store's own signed
 *      transaction (JWS) for the Max subscription. The signature is checked
 *      against Apple's certificate chain right here — no call to Apple, no
 *      receipt server — so the tier is proved, not claimed.
 *   2. Metering. Reads are counted per subscriber per month and globally per
 *      day in Postgres, and the increment IS the cap check, so racing
 *      requests cannot slip under the limit together.
 *   3. Size. Frames are bounded in count and bytes before anything is spent.
 *
 * Deploy:  supabase functions deploy read-workout --no-verify-jwt
 *          (the StoreKit JWS is the auth here, not a Supabase user token)
 * Secrets: supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
 * Optional secrets:
 *          MODEL              claude model id       (default claude-opus-5)
 *          MONTHLY_CAP        reads per Max sub/mo  (default 30)
 *          GLOBAL_DAILY_CAP   reads per day, total  (default 400)
 *          ALLOW_SANDBOX      "true" to accept Xcode/TestFlight sandbox
 *                             transactions without the production chain pin
 *                             (leave unset in production)
 */

import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";
import { X509Certificate } from "npm:@peculiar/x509";

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

async function sha256hex(bytes: ArrayBuffer): Promise<string> {
  const d = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/* Verify the StoreKit JWS end to end: chain signatures, root pin, JWS
 * signature against the leaf, then the claims. Returns the payload. Throws
 * with a human-sized reason on any failure. */
async function verifyTransaction(jws: string): Promise<Record<string, unknown>> {
  const header = jose.decodeProtectedHeader(jws);
  const x5c = header.x5c as string[] | undefined;
  if (!x5c || x5c.length < 2) throw new Error("transaction carries no certificate chain");

  const certs = x5c.map((c) => new X509Certificate(b64ToBytes(c)));

  /* Each certificate must be signed by the next one up, and the top of the
   * chain must be the pinned Apple root. Without this, anyone could sign a
   * payload with their own key and staple their own certificates on. */
  for (let i = 0; i < certs.length - 1; i++) {
    const ok = await certs[i].verify({ publicKey: certs[i + 1].publicKey });
    if (!ok) throw new Error("certificate chain does not verify");
  }
  const root = certs[certs.length - 1];
  const rootOk = await root.verify({ publicKey: root.publicKey }); // self-signed root
  if (!rootOk) throw new Error("root certificate does not verify");
  if ((await sha256hex(root.rawData)) !== APPLE_ROOT_FP.toLowerCase()) {
    throw new Error("chain does not end at Apple's root");
  }
  const now = new Date();
  for (const c of certs) {
    if (now < c.notBefore || now > c.notAfter) throw new Error("a chain certificate is expired");
  }

  const leafPem = certs[0].toString("pem");
  const key = await jose.importX509(leafPem, "ES256");
  const { payload } = await jose.compactVerify(jws, key);
  return JSON.parse(new TextDecoder().decode(payload));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reply(405, { error: "POST only" });

  let body: {
    jws?: string;
    frames?: string[];
    kind?: string;
    catalog?: { id: string; n: string }[];
  };
  try {
    body = await req.json();
  } catch {
    return reply(400, { error: "the request was not JSON" });
  }

  /* ---- size gates, before any money moves ---- */
  const frames = Array.isArray(body.frames) ? body.frames : [];
  if (!frames.length || frames.length > 8) {
    return reply(400, { error: "between 1 and 8 frames" });
  }
  for (const f of frames) {
    if (typeof f !== "string" || f.length > 2_600_000) {
      return reply(400, { error: "a frame is too large" });
    }
  }
  const catalog = Array.isArray(body.catalog) ? body.catalog : [];
  if (!catalog.length || catalog.length > 400) {
    return reply(400, { error: "catalog missing or oversized" });
  }
  for (const c of catalog) {
    if (!c || typeof c.id !== "string" || typeof c.n !== "string" ||
        c.id.length > 40 || c.n.length > 80) {
      return reply(400, { error: "catalog rows are malformed" });
    }
  }
  const kind = body.kind === "video" ? "video" : "photo";

  /* ---- entitlement ---- */
  if (typeof body.jws !== "string" || !body.jws) {
    return reply(401, { error: "no subscription proof" });
  }
  let tx: Record<string, unknown>;
  try {
    tx = await verifyTransaction(body.jws);
  } catch (e) {
    /* Xcode's local StoreKit configuration signs with a locally generated
     * certificate that can never chain to Apple's root. ALLOW_SANDBOX lets a
     * dev build through on the decoded claims alone — the metering below
     * still applies — and stays off in production. */
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

  /* ---- metering ---- */
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const monthlyCap = Number(Deno.env.get("MONTHLY_CAP") || 30);
  const dailyCap = Number(Deno.env.get("GLOBAL_DAILY_CAP") || 400);
  const subject = String(tx.originalTransactionId || tx.transactionId || "unknown");
  const month = new Date().toISOString().slice(0, 7);
  const day = new Date().toISOString().slice(0, 10);

  const mine = await db.rpc("ai_read_tick", { p_key: `sub:${subject}:${month}`, p_cap: monthlyCap });
  if (mine.error) return reply(500, { error: "the meter is down" });
  if (mine.data < 0) return reply(429, { error: `that's all ${monthlyCap} reads for this month` });

  const all = await db.rpc("ai_read_tick", { p_key: `all:${day}`, p_cap: dailyCap });
  if (all.error) return reply(500, { error: "the meter is down" });
  if (all.data < 0) return reply(503, { error: "the reader is at capacity today — try tomorrow" });

  /* ---- the read ---- */
  const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });
  const model = Deno.env.get("MODEL") || "claude-opus-5";

  const ids = catalog.map((c) => c.id);
  const catalogText = catalog.map((c) => `${c.id} | ${c.n}`).join("\n");
  const content: Anthropic.ContentBlockParam[] = frames.map((f) => ({
    type: "image" as const,
    source: { type: "base64" as const, media_type: "image/jpeg" as const, data: f },
  }));
  content.push({
    type: "text",
    text:
      (kind === "video"
        ? `These ${frames.length} frames were sampled in order across one workout video.`
        : "This is a photo or screenshot of a workout.") +
      " Work out which exercises it shows: read any exercise names written on screen, and also " +
      "recognise exercises actually being performed, even when nothing is written. " +
      "Choose only from this catalogue (each line is `id | name`):\n\n" +
      catalogText +
      "\n\nReturn the ids in the order the exercises appear or are performed. " +
      "One id per distinct exercise, no repeats. When a movement on screen has no close " +
      "match in the catalogue, or you are not reasonably sure, leave it out.",
  });

  try {
    const res = await anthropic.messages.create({
      model,
      max_tokens: 4000,
      output_config: {
        effort: "low",
        format: {
          type: "json_schema",
          schema: {
            type: "object",
            properties: {
              movements: { type: "array", items: { type: "string", enum: ids } },
            },
            required: ["movements"],
            additionalProperties: false,
          },
        },
      },
      messages: [{ role: "user", content }],
    });

    if (res.stop_reason === "refusal") {
      return reply(422, { error: "the AI declined to read that one" });
    }
    const text = res.content.find((b) => b.type === "text");
    const parsed = text ? JSON.parse(text.text) : { movements: [] };
    const allow = new Set(ids);
    const out: string[] = [];
    for (const id of parsed.movements || []) {
      if (allow.has(id) && !out.includes(id)) out.push(id);
    }
    return reply(200, { ids: out, left: mine.data });
  } catch (e) {
    console.error("claude call failed:", e);
    return reply(502, { error: "the AI could not be reached" });
  }
});
