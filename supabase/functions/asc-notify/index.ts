/* asc-notify — Apple's App Store Server Notifications land here.
 *
 * App Store Connect posts a signed payload within seconds of every purchase,
 * renewal, billing failure, expiry and refund. The signature chains to the
 * same pinned Apple root the Upload Media reader trusts, so a notification is
 * proved to be Apple's before a row is written. subs keeps the current state
 * of each subscription; sub_events keeps the history revenue is summed from.
 *
 * Sandbox notifications sign with Apple's real chain too, so they verify the
 * same way and are kept apart only by their environment column — sandbox
 * tests light the pipeline up before launch without polluting the numbers.
 *
 * Deploy:  supabase functions deploy asc-notify --no-verify-jwt
 *          (Apple sends no Supabase auth header; the JWS is the auth)
 * Then paste the function URL into App Store Connect under
 * App Information → App Store Server Notifications (V2), production and
 * sandbox both.
 *
 * The chain-verification helpers are copied verbatim from read-workout,
 * which proved them against a local OpenSSL harness; a change to one copy
 * belongs in the other.
 */

import { createClient } from "npm:@supabase/supabase-js@2";
import * as jose from "npm:jose@5";

const BUNDLE = "com.frennat.fatcamp";

const APPLE_ROOT_FP =
  Deno.env.get("APPLE_ROOT_FP") ||
  "63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179";

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

function hashFor(b: Uint8Array, algSeq: TLV): string {
  const oid = derChildren(b, algSeq)[0];
  if (oidIs(b, oid, "2a8648ce3d040302")) return "SHA-256";
  if (oidIs(b, oid, "2a8648ce3d040303")) return "SHA-384";
  if (oidIs(b, oid, "2a8648ce3d040304")) return "SHA-512";
  throw new Error("unsupported certificate signature algorithm");
}

function spkiOf(b: Uint8Array, cert: TLV): { spki: Uint8Array; curve: string; size: number } {
  const tbs = derChildren(b, cert)[0];
  const kids = derChildren(b, tbs);
  const spki = kids[kids[0].tag === 0xa0 ? 6 : 5];
  const curveOid = derChildren(b, derChildren(b, spki)[0])[1];
  if (oidIs(b, curveOid, "2a8648ce3d030107")) return { spki: rawOf(b, spki), curve: "P-256", size: 32 };
  if (oidIs(b, curveOid, "2b81040022"))       return { spki: rawOf(b, spki), curve: "P-384", size: 48 };
  throw new Error("unsupported certificate key type");
}

function rawSig(b: Uint8Array, sigBits: TLV, size: number): Uint8Array {
  const der = bodyOf(b, sigBits).subarray(1);
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

async function verifyJWS(jws: string): Promise<Record<string, unknown>> {
  const header = jose.decodeProtectedHeader(jws);
  const x5c = header.x5c as string[] | undefined;
  if (!x5c || x5c.length < 2) throw new Error("payload carries no certificate chain");
  const certs = x5c.map(b64ToBytes);
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

/* Apple's notificationType → the sub's current standing. Anything not named
 * here (price consents, renewal-pref changes, …) records an event but leaves
 * the standing alone. */
function statusFor(type: string, subtype: string): string | null {
  if (type === "REVOKE" || type === "REFUND") return "revoked";
  if (type === "EXPIRED" || type === "GRACE_PERIOD_EXPIRED") return "expired";
  if (type === "DID_FAIL_TO_RENEW") return subtype === "GRACE_PERIOD" ? "grace" : "expired";
  if (type === "SUBSCRIBED" || type === "DID_RENEW" || type === "OFFER_REDEEMED" ||
      type === "RESUBSCRIBE") return "active";
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("POST only", { status: 405 });

  let signedPayload = "";
  try {
    const body = await req.json();
    signedPayload = String(body.signedPayload || "");
  } catch {
    return new Response("not JSON", { status: 400 });
  }
  if (!signedPayload) return new Response("no signedPayload", { status: 400 });

  let note: Record<string, unknown>;
  try {
    note = await verifyJWS(signedPayload);
  } catch (e) {
    console.error("notification did not verify:", e);
    return new Response("signature did not verify", { status: 401 });
  }

  const type = String(note.notificationType || "");
  const subtype = String(note.subtype || "");
  const data = (note.data || {}) as Record<string, unknown>;
  const environment = String(data.environment || "Production");

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  /* App Store Connect's "send test notification" button has no transaction;
   * write the event so the wiring can be seen to work, and stop there. */
  if (type === "TEST") {
    await db.from("sub_events").insert({ event: "TEST", environment });
    return new Response(JSON.stringify({ ok: true }), { status: 200 });
  }

  let tx: Record<string, unknown> = {};
  if (typeof data.signedTransactionInfo === "string") {
    try {
      tx = await verifyJWS(data.signedTransactionInfo);
    } catch (e) {
      console.error("transaction inside notification did not verify:", e);
      return new Response("transaction did not verify", { status: 401 });
    }
  }
  if (tx.bundleId && tx.bundleId !== BUNDLE) {
    return new Response("wrong app", { status: 401 });
  }

  const otid = String(tx.originalTransactionId || tx.transactionId || "");
  const productId = String(tx.productId || "");
  const expiresAt = tx.expiresDate ? new Date(Number(tx.expiresDate)).toISOString() : null;
  const priceMilli = tx.price != null ? Number(tx.price) : null;
  const currency = tx.currency ? String(tx.currency) : null;

  const ev = await db.from("sub_events").insert({
    otid: otid || null, product_id: productId || null,
    event: type, subtype: subtype || null, environment,
    price_milli: priceMilli, currency, expires_at: expiresAt,
  });
  if (ev.error) console.error("event insert failed:", ev.error);

  const status = statusFor(type, subtype);
  if (otid && productId && status) {
    const up = await db.from("subs").upsert({
      otid, product_id: productId, environment, status,
      expires_at: expiresAt, price_milli: priceMilli, currency,
      updated_at: new Date().toISOString(),
    });
    if (up.error) console.error("subs upsert failed:", up.error);
  }

  /* Apple retries anything that is not a 200; the write errors above are
   * logged rather than surfaced so a transient DB hiccup on a minor event
   * type does not turn into a retry storm. */
  return new Response(JSON.stringify({ ok: true }), { status: 200 });
});
