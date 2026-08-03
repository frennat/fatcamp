# Xcode Cloud → TestFlight

The goal: you describe a change, Claude edits and pushes to GitHub, Xcode Cloud
builds it on Apple's machines, and TestFlight puts it on your phone.

Getting there has five steps. Two of them are yours because they need your
Apple ID; the rest are mine.

---

## Where things stand on this Mac

| | |
| --- | --- |
| Xcode | 26.2 — installed, command line tools pointed at it |
| iPhone simulators | 5 available |
| Node / npm | **not installed** — step 1 |
| Homebrew | not installed |
| Codesigning identities | **none** — no developer account attached yet |
| Machine | Intel Core i5, macOS 15.7.4, 17 GB free |

Two things follow from that last row.

**Get the x64 build of Node**, not arm64. This is an Intel Mac, and nodejs.org
will often offer the Apple Silicon build by default.

**Xcode Cloud is the right call here, more than I realised.** Builds run on
Apple's hardware, so a 1.4 GHz i5 never has to archive anything. Local builds
on this machine would be slow enough to be a real tax on iteration.

---

## Step 1 — Node (yours, five minutes)

1. Go to **nodejs.org/en/download**.
2. Choose **macOS**, then the **LTS** version, then **Installer (.pkg)**.
3. Set the architecture to **x64** — *not* arm64. The page may preselect arm64;
   change it. An arm64 build will not run on this Mac.
4. Open the downloaded `.pkg` and follow it. It asks for your Mac password
   because it writes to `/usr/local/bin`.
5. Open a **new** Terminal window (the old one has a stale PATH) and check:

```
node --version && npm --version
```

Two version numbers means you are done. Tell me and I will do step 3.

*Why the installer and not Homebrew:* Homebrew is not on this machine, and
installing it is a bigger job than installing Node. The `.pkg` is one download.

---

## Step 2 — Apple Developer Program (yours, start it now)

**Do this today, in parallel with step 1** — approval takes 24–48 hours and
everything else waits on it.

1. **developer.apple.com/programs** → Enroll. $99/year.
2. Enrol as an **individual** unless you already have an LLC. Individual is
   approved fastest; the tradeoff is that your legal name shows as the seller
   on the App Store listing. Enrolling as an organisation needs a D-U-N-S
   number and takes noticeably longer.
3. When it is approved: open Xcode → **Settings → Accounts → +** → sign in with
   that Apple ID.

You will know it worked when `security find-identity -p codesigning -v` stops
saying "0 valid identities found".

Xcode Cloud itself is free up to **25 compute hours a month**, which is a lot
of builds for an app this size. It is included with the membership.

---

## Step 3 — The iOS project (mine, once Node exists)

I run:

```
npm install @capacitor/core @capacitor/cli @capacitor/ios
npx cap init "Lifted.AI" ai.lifted.app --web-dir=www
npm run build
npx cap add ios
```

That produces `ios/App/App.xcworkspace` — a real Xcode project that loads the
app from inside the bundle. It gets committed, because Xcode Cloud builds from
what is in the repo.

Already in place for this:

- **`package.json`** — `npm run build` stages `index.html`, `manifest.json` and
  `icons/` into `www/`, which is what Capacitor packages. `sw.js` is
  deliberately left out: Capacitor serves over `capacitor://`, the service
  worker would never register, and a stale cache layer inside a native app is
  a bug waiting to happen. The app already guards its own registration call, so
  nothing breaks.
- **`ci_scripts/ci_post_clone.sh`** — Xcode Cloud runs this after cloning. It
  installs Node via Homebrew (Apple's build images have brew but not Node),
  installs dependencies, stages the web app, and syncs it into the iOS project.
- **`.gitignore`** — `node_modules/`, `www/` and the generated iOS artefacts.

GitHub Pages keeps working exactly as it does now. `www/` is a build artefact;
the app still lives at the repo root, so `frennat.github.io/lifted-ai/` is
unaffected.

---

## Step 4 — Create the workflow (yours, ten minutes, GUI)

This part cannot be scripted — it is Xcode talking to App Store Connect with
your credentials.

1. Open `ios/App/App.xcworkspace` in Xcode.
2. Select the **App** target → **Signing & Capabilities** → tick **Automatically
   manage signing** and pick your team.
3. **Product → Xcode Cloud → Create Workflow**.
4. Xcode asks to connect a source repository. Choose **GitHub**, authorise it,
   and grant access to `frennat/lifted-ai`.
5. Set the workflow to:
   - **Start Condition:** Branch Changes → `main`
   - **Action:** Archive → iOS
   - **Post-Action:** TestFlight (Internal Testing Only)
6. Save. The first build kicks off immediately.

Then in **App Store Connect → TestFlight → Internal Testing**, add yourself as
a tester. Internal builds skip App Review entirely and arrive in the TestFlight
app on your phone in minutes.

---

## Step 5 — From then on

You tell me what to change. I edit, test, commit and push to `main`. Xcode Cloud
sees the push, runs `ci_post_clone.sh`, archives, and hands the build to
TestFlight. Your phone gets a notification.

I can also drive the iOS Simulator on this Mac to check a build before pushing,
which is faster than waiting on a cloud build for something small.

---

## What still is not solved

- **No billing.** Choosing a plan applies its limits locally; nothing is
  charged. Subscriptions have to become StoreKit products before the app can
  take money — that is a real piece of work, not a config change.
- **No password reset.** Forget the password and there is currently no way back
  into an account.
- **No privacy policy page.** App Review requires a URL. It can be a page on the
  marketing site; it does not exist yet.
- **Guideline 4.2.** A shell around a web app can be rejected as a website in a
  wrapper. The offline-first argument is genuine here, but native hooks —
  Apple Health, local notifications, haptics — make it much safer. Worth doing
  before the first submission rather than after a rejection.
