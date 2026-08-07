# Getting Fatcamp onto your phone, and eventually into the App Store

Two separate jobs. The first one you can finish today; the second takes a
developer account, a wrapper, and Apple's review queue.

---

## Part 1 — On your iPhone today, no App Store involved

The app is already a progressive web app: it has a manifest, a service worker,
icons, and the iOS meta tags. Installed to the home screen it gets its own icon,
opens full screen with no address bar, and runs with no signal. It behaves like
an app because, on iOS, that *is* what an installed web app is.

It just needs to live at a public HTTPS address. Service workers refuse to run
over plain HTTP, so a local file or a `file://` link will not do it.

### Turn on GitHub Pages (about two minutes)

1. Go to **github.com/frennat/fatcamp → Settings → Pages**.
2. Under **Build and deployment → Source**, choose **Deploy from a branch**.
3. Branch **main**, folder **/ (root)**. Save.
4. Wait a minute. The app is then at:
   - **App:** `https://frennat.github.io/fatcamp/`
   - **Marketing site:** `https://frennat.github.io/fatcamp/site/`

Every path in the app is relative, so the subfolder does not break anything —
the manifest, the icons and the service worker all resolve correctly there.

### Add it to your home screen

1. Open `https://frennat.github.io/fatcamp/` in **Safari**. It has to be
   Safari — Chrome on iOS cannot install web apps.
2. Tap **Share** (the square with the arrow coming out of the top).
3. Scroll down, tap **Add to Home Screen**, then **Add**.
4. Launch it from the icon.

Load it once with signal and the service worker caches the whole thing; after
that it opens in a basement with no bars.

### Quicker loop while you are still changing things

To try a change without pushing, serve the folder from your Mac and open it
from the phone on the same wifi:

```
cd ~/fatcamp && python3 -m http.server 8000
```

Then browse to `http://<your-mac-ip>:8000` from the phone. The service worker
will not register over plain HTTP, so it will not install or work offline —
fine for checking a change, not for real use.

---

## Part 2 — The App Store

> The concrete, step-by-step version of this now lives in
> [`XCODE-CLOUD.md`](XCODE-CLOUD.md), which is the route being taken:
> Xcode Cloud builds on Apple's hardware and hands off to TestFlight, so
> nothing has to be archived on this Intel Mac. What follows is the background.

### The Mac app you were thinking of

There are three pieces and they are easy to mix up:

- **Xcode** — free, Mac App Store. This is where the app is built, signed and
  archived. It is the big one.
- **Transporter** — free, Mac App Store. A single-purpose app that uploads a
  finished build to Apple. Optional; Xcode can upload directly.
- **App Store Connect** — *not* a Mac app. It is the website at
  `appstoreconnect.apple.com` where the listing, screenshots, pricing,
  subscriptions, TestFlight and review submissions all live.

### What has to happen, in order

**1. Apple Developer Program — $99/year.**
`developer.apple.com/programs`. Enrol as an individual (fastest — your legal
name becomes the seller name) or as an organisation (needs a D-U-N-S number and
an LLC, and takes longer, but the seller name is the company). Approval is
usually a day or two.

**2. Wrap the web app.**
An iOS app has to be a native binary; you cannot upload HTML. Two routes:

- **Capacitor** (recommended). `npm i -D @capacitor/cli && npx cap init`, point
  it at this folder, `npx cap add ios`. You get a real Xcode project that loads
  the app locally, plus proper plugin access for Health, notifications and
  StoreKit. This is the normal path for a PWA going to the store.
- **A bare WKWebView wrapper.** Faster to stand up, but riskier — see below.

**3. Do not ship a bare wrapper.**
App Review guideline **4.2 (Minimum Functionality)** exists specifically to
reject apps that are a website in a shell. Fatcamp has a real case to make —
it runs entirely offline, it is not a view onto a server — but you want native
hooks on top of it before you submit. The cheapest credible ones:
   - Apple Health: write workouts, read bodyweight.
   - Local notifications: nudge the streak.
   - Haptics on set completion.
   - StoreKit subscriptions (which you need anyway — see next).

**4. Subscriptions have to be In-App Purchase.**
Apple requires IAP for digital subscriptions and takes a commission — 15% under
the Small Business Program (under $1M/year, which is you) and 30% above it. So
the $5 first month, $10 Pro and $17 Max become StoreKit products configured in
App Store Connect, not Stripe.

Stripe is still the right answer for people who subscribe **through the website**
on a laptop — Apple has no claim on that. Historically you could not link to it
from inside the app; a 2025 US court ruling loosened that. Verify the current
rule before you rely on it, because it is still moving.

**5. Set up the listing in App Store Connect.**
A bundle ID, an app record, screenshots (at least one 6.7-inch set; check the
current required sizes in the console, Apple changes them), a description,
keywords, an age rating, a **privacy policy URL** (required — it can be a page
on the marketing site), and the App Privacy questionnaire.

**6. TestFlight — this is the part you actually want first.**
Archive in Xcode (**Product → Archive → Distribute App → App Store Connect**),
then in App Store Connect add yourself as an **internal tester**. Internal
builds skip review entirely and land on your phone through the TestFlight app,
usually within minutes. That is how you use the real native app yourself before
anyone else sees it — and before you commit to a public release.

**7. Submit for review.** Typically 24–48 hours. First submissions get more
scrutiny; expect at least one round of notes.

---

## What is not done yet

Being straight about the gaps:

- **No billing anywhere.** Choosing a plan applies that tier's limits locally so
  each one can be felt out. Nothing is charged, there is no Stripe account, and
  there are no StoreKit products. The pricing screens are honest about this.
- **No password reset.** Sign-in is email and password against Supabase. If a
  password is forgotten there is currently no way back in without a reset flow.
- **No privacy policy page.** Apple requires a URL before review.
- **The trial is time-based and lives on the device.** Clearing site data resets
  it. That is fine for a founder build; it needs to be server-side before money
  is involved.
