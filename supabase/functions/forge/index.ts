/* forge — "speak today's lift into existence" from the wrist.
 *
 * The Apple Watch sends what was dictated plus the person's saved kit, movement
 * limitations, unit and recent history (the phone keeps the watch's copy fresh).
 * This runs the very same generator the app uses — gen.js is copied out of
 * index.html by scripts/build-forge.mjs on every build — and returns:
 *   watch  — the session in the watch's own format, ready to train
 *   packed — the phone's format, handed to the iPhone when the two reconnect
 *
 * It works with the phone out of range (cellular watch), because nothing here
 * needs the phone. No AI, no paid API: the generator is rules, so the only gate
 * is size.
 *
 * Deploy:  node scripts/build-forge.mjs && supabase functions deploy forge --no-verify-jwt
 */
import { forge } from "./gen.js";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return reply(405, { error: "POST only" });

  const raw = await req.text();
  if (raw.length > 40_000) return reply(413, { error: "request too large" });
  let body: { text?: string; profile?: Record<string, unknown> };
  try {
    body = JSON.parse(raw);
  } catch {
    return reply(400, { error: "the request was not JSON" });
  }
  const text = String(body.text || "").trim().slice(0, 400);
  if (text.length < 2) return reply(400, { error: "say what you want to train" });

  try {
    const out = forge({ text, profile: (body.profile || {}) as Record<string, unknown> });
    if (!out.heard) {
      return reply(422, { error: "didn't catch a workout in that — try \"push day, go hard\"" });
    }
    return reply(200, out);
  } catch (e) {
    console.error("forge failed:", e);
    return reply(500, { error: "the forge jammed — try again" });
  }
});
