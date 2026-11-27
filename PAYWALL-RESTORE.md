# The paywall: how it was built, and how to turn it back on

Turned off 27 November 2026 for personal use. **Nothing was deleted.** Every piece is
still in the code and in App Store Connect; one switch decides whether it runs.

## Turning it back on (the whole job)

1. In `index.html`, find `const PAYWALL = false;` and make it `true`.
2. `npm run sync` (copies the web app into the iOS bundle), commit, push to `main`.
3. Xcode Cloud builds it; test a purchase on TestFlight (sandbox, not charged).
4. Before release: Paid Apps agreement active, banking + tax done (App Store Connect → Business).

Or just tell Claude: "turn the paywall back on".

## What `PAYWALL = false` does

| Piece | Paywall on | Paywall off (now) |
|---|---|---|
| `tierOf()` | `pro` / `max` from StoreKit, else `trial` (30 days) or `expired` | always `max` |
| `locked()` | true once the first month runs out: new sessions blocked | never true |
| `storePlugin()` | the native Store plugin | `null`, so StoreKit is never called (no Apple ID sign-in prompts, no `AppTransaction`) |
| Plans panel (Profile → "The plan") | price cards, buy / restore / manage buttons | hidden |
| Upload Media (AI reads) | open on a real Max subscription | locked with "Off in this build" (the server only accepts a signed Max transaction) |
| Max limits (20 moves, failure sets, profiles, adaptive) | Max or first month | always on |

## The pieces, for reference

### Products (App Store Connect → Subscriptions, group "Fatcamp")
- `com.frennat.fatcamp.pro.monthly` (Pro, $9.99/mo): 10 moves, no failure sets, 1 profile, 4 training days/week, 1 split.
- `com.frennat.fatcamp.max.monthly` (Max, $14.99/mo): 20 moves, failure sets, surprise, unlimited profiles, adaptive, 7 days/week, unlimited splits, Upload Media.
- **Introductory offer on both: $4.99 for the first month** (pay-up-front, 1 month). That's the "first month" card. It is not a separate product.
- Limits live in `PLANS` in `index.html`; prices on screen come from StoreKit (`storeLoad`), with `PLANS` dollar figures as the web fallback.

### App code
- `index.html`: `PLANS`, `FIRST_MONTH`, `PAYWALL`, `trialDaysLeft`, `tierOf`, `locked`, `limitsOf`, `IAP`, `storePlugin`, `storeLoad`, `firstMonthPrice`, `storeSync`, `anchorTrial`, `storeBuy`, `storeRestore`, `applyPlanLimits`, `renderPlans`, and the paywall check at the top of `doForge`.
- `anchorTrial`: anchors the 30-day clock to the App Store's `AppTransaction` date, so deleting and reinstalling can't buy another free month. On TestFlight this is what can bring up an Apple ID sign-in.
- `ios/App/App/StorePlugin.swift`: StoreKit 2 bridge: `isAvailable`, `products`, `purchase`, `entitlements`, `restore`, `manage`, `firstInstall`.
- Legal links on the plans screen: Apple EULA, Privacy Policy, Fatcamp Terms (required by Apple for subscriptions; their absence got 1.3 rejected once).

### Server (Supabase project `fatcamp`)
- `supabase/functions/read-workout`: Upload Media. Verifies the Max subscription's signed transaction (JWS) against Apple's root, meters reads (`MONTHLY_CAP` 30/sub, `GLOBAL_DAILY_CAP` 400/day), then calls Claude. `ALLOW_SANDBOX=true` lets TestFlight purchases through.
- `supabase/functions/asc-notify`: App Store Server Notifications V2 (purchases, renewals, refunds) into `subs` / `sub_events`. Its URL is registered in App Store Connect (production + sandbox). Still live, and harmless while nobody subscribes.

### App Store Connect state (untouched)
- Both subscriptions and their intro offers exist, with metadata and review screenshots. 1.3 shipped with them approved.
- Nothing needs re-creating. Prices or offers can be edited there before relaunch.

## When you relaunch, re-check
- Paid Apps agreement, banking, tax (W-9) are current, under the LLC if you formed one.
- Privacy label still lists Purchases if you ever add server-side purchase records beyond `asc-notify`.
- The trial copy: "Everything in Max, except AI reads (Upload Media)".
- `ALLOW_SANDBOX` unset in production once real purchases are flowing.
