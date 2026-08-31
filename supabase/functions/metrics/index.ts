/* metrics — the Finances workbook's live feed.
 *
 * GET ?k=<METRICS_KEY> answers a two-column CSV of the business numbers:
 * active subscribers (from the subs ledger asc-notify maintains), revenue
 * summed from Apple's own notification events, plus the waitlist and the
 * Upload Media meter. Excel's "From Web" query points at this URL and
 * refreshes on demand.
 *
 * The key is a shared secret in the URL — fine for a private workbook, and
 * the endpoint only ever reads aggregates; nothing row-level, no emails, no
 * transaction ids leave this function.
 *
 * Revenue notes, so nobody is surprised at tax time: price comes from
 * Apple's notification payload, so it is the GROSS customer price in the
 * buyer's currency, mixed across currencies as-is; Apple's commission and
 * local taxes are not netted out, and App Store Connect's daily reports
 * remain the books of record. Free-trial starts carry no charge, so they
 * count as subscribers but add zero revenue — exactly right.
 *
 * Deploy:  supabase functions deploy metrics --no-verify-jwt
 * Secrets: supabase secrets set METRICS_KEY=<long random hex>
 */

import { createClient } from "npm:@supabase/supabase-js@2";

type Row = Record<string, unknown>;

Deno.serve(async (req) => {
  if (req.method !== "GET") return new Response("GET only", { status: 405 });

  const want = Deno.env.get("METRICS_KEY") || "";
  const got = new URL(req.url).searchParams.get("k") || "";
  if (!want) return new Response("metrics key not configured", { status: 503 });
  if (got !== want) return new Response("wrong key", { status: 401 });

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const now = new Date();
  const iso = now.toISOString();
  const today = iso.slice(0, 10);
  const month = iso.slice(0, 7);
  const d30 = new Date(now.getTime() - 30 * 864e5).toISOString();

  /* Volumes are tiny for a long time to come, so rows are fetched and summed
   * here rather than pushed into SQL aggregates. */
  const [subsQ, evQ, wlQ, aiQ] = await Promise.all([
    db.from("subs").select("product_id,environment,status,expires_at,price_milli,currency"),
    db.from("sub_events").select("at,event,environment,price_milli,currency").gte("at", d30),
    db.from("waitlist").select("id", { count: "exact", head: true }),
    db.from("ai_reads").select("k,n"),
  ]);
  for (const q of [subsQ, evQ, aiQ]) {
    if (q.error) return new Response("query failed: " + q.error.message, { status: 500 });
  }

  const subs = (subsQ.data || []) as Row[];
  const live = (s: Row) =>
    (s.status === "active" || s.status === "grace") &&
    (!s.expires_at || String(s.expires_at) > iso);
  const activeProd = subs.filter((s) => live(s) && s.environment === "Production");
  const activeSand = subs.filter((s) => live(s) && s.environment !== "Production");

  const perProduct: Record<string, number> = {};
  for (const s of activeProd) {
    const p = String(s.product_id).split(".").pop() || String(s.product_id);
    perProduct[p] = (perProduct[p] || 0) + 1;
  }
  const mrr = activeProd.reduce((t, s) => t + (Number(s.price_milli) || 0), 0) / 1000;

  const evs = (evQ.data || []) as Row[];
  const paid = (e: Row) =>
    (e.event === "SUBSCRIBED" || e.event === "DID_RENEW" ||
     e.event === "OFFER_REDEEMED" || e.event === "RESUBSCRIBE") &&
    e.environment === "Production" && Number(e.price_milli) > 0;
  const sum = (rows: Row[]) => rows.reduce((t, e) => t + Number(e.price_milli), 0) / 1000;
  const paidToday = evs.filter((e) => paid(e) && String(e.at) >= today);
  const paidMTD = evs.filter((e) => paid(e) && String(e.at).slice(0, 7) === month);
  const paid30 = evs.filter(paid);

  const ai = (aiQ.data || []) as Row[];
  const aiMonth = ai.filter((r) => String(r.k).startsWith("all:" + month))
    .reduce((t, r) => t + Number(r.n), 0);
  const aiSubs = ai.filter((r) => {
    const k = String(r.k);
    return k.startsWith("sub:") && k.endsWith(":" + month);
  }).length;

  const lines: [string, string | number][] = [
    ["generated_at_utc", iso],
    ["active_subscribers", activeProd.length],
    ...Object.entries(perProduct).map(([p, n]) =>
      ["active_" + p, n] as [string, number]),
    ["mrr_gross", mrr.toFixed(2)],
    ["revenue_today_gross", sum(paidToday).toFixed(2)],
    ["revenue_month_to_date_gross", sum(paidMTD).toFixed(2)],
    ["revenue_30d_gross", sum(paid30).toFixed(2)],
    ["paid_transactions_today", paidToday.length],
    ["paid_transactions_30d", paid30.length],
    ["sandbox_active_subs", activeSand.length],
    ["waitlist_signups", wlQ.count ?? 0],
    ["ai_reads_this_month", aiMonth],
    ["ai_read_subscribers_this_month", aiSubs],
  ];

  const csv = "metric,value\n" +
    lines.map(([k, v]) => k + "," + v).join("\n") + "\n";
  return new Response(csv, {
    status: 200,
    headers: { "Content-Type": "text/csv; charset=utf-8", "Cache-Control": "no-store" },
  });
});
