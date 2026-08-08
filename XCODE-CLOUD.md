# Shipping updates

The pipeline works. Push to `main` → Xcode Cloud archives on Apple's hardware →
TestFlight → your phone. First green build 2026-08-05.

This is the runbook for *changing* the app now that it exists. Setup history is
at the bottom.

---

## Decide which kind of change it is first

This is the part that saves the most time.

`index.html` **is** the app. GitHub Pages serves it and redeploys on every push,
in about a minute. The iOS build bundles its own copy, which is why native
builds are slower — they have to be rebuilt and re-uploaded.

| Changing | Goes live via | How long |
| --- | --- | --- |
| Movement rigs, copy, colours, layout, generator, pricing, parser | GitHub Pages | ~1 min |
| Anything about feel, immersion, wording, tuning | GitHub Pages | ~1 min |
| Plugins, permissions, app icon, splash, Info.plist, version | TestFlight | ~15–25 min |

**For web changes, don't wait on TestFlight.** Push, wait a minute, open
`frennat.github.io/fatcamp` on your phone. Add it to the home screen and it
runs full screen with its own icon, like the app.

The exception: the home-screen version cannot test **Apple Health** or
**notifications**. Those are native and need a real build.

A good rhythm is to iterate on the web all evening, then cut one TestFlight
build when you want to check the whole batch inside the real shell.

---

## The normal loop

1. You say what to change.
2. Claude edits, runs `npm run sync`, commits, pushes to `main`.
3. Xcode Cloud starts within a minute of the push.
4. Archive takes about 4–8 minutes.
5. TestFlight processes for another 5–15, then your phone gets a notification.

`npm run sync` matters — the iOS bundle carries its own copy of the web app at
`ios/App/App/public/`, committed on purpose so Xcode Cloud can archive from a
clean clone with no build step. `npm run verify` fails loudly if the two drift,
and also checks `Package.resolved` is still present.

### Installing the update

Open **TestFlight** on your phone → Fatcamp → **Update**. Builds do not
install themselves.

**If the build is not offered at all, check the tester group first.** A build
can archive, upload and process perfectly and still be invisible on the phone
because it was never distributed to anyone. Nothing reports this as an error —
Xcode Cloud goes green, App Store Connect lists the build, and the phone simply
has nothing new. It cost most of 2026-08-08 and several wrong theories about
build numbers.

Turn it on once: **App Store Connect → TestFlight → Internal Testing → your
group → Automatically distribute builds.** The same thing can be set as the
workflow's TestFlight post-action, but the group setting applies however the
build arrives.

Only after that is worth suspecting processing time, which runs 5–15 minutes
past the archive going green.

---

## Checking on a build without leaving the terminal

Xcode Cloud reports status back to GitHub, which is readable without any
App Store Connect login:

```bash
curl -s "https://api.github.com/repos/frennat/fatcamp/commits/$(git -C ~/fatcamp rev-parse HEAD)/check-runs" | python3 -m json.tool
```

Look for `Fatcamp | Default | Archive - iOS`. The useful fields are
`status`, `conclusion`, and `output.text` — which carries the actual error when
a build fails, in full, which the email does not.

`conclusion` values worth knowing:

- `success` — archived and handed to TestFlight.
- `action_required` — the archive stopped on an error. Read `output.text`.
- `failure` — the build itself failed.

---

## When a build breaks

Almost every failure so far has been a **file the repo needs but does not
have**, not bad code. A local build passing proves less than it looks like,
because your Mac has things Apple's build machine does not.

Check in this order:

1. **`Package.resolved` present?** At
   `ios/App/App.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`. Xcode
   Cloud disables automatic dependency resolution and cannot build without it.
   **Xcode deletes this file while it has the project open**, and a later
   `git add -A` then commits the deletion. This broke the 2026-08-07 build.
   `npm run verify` now catches it.
2. **Web assets in sync?** `npm run verify`.
3. **Anything new referenced but gitignored?** Capacitor generates
   `public/`, `config.xml` and `capacitor.config.json` and ignores them by
   default; they are committed deliberately.
4. **A new Swift file added to the Xcode project properly?** It needs entries in
   `project.pbxproj` — and the object ids must be genuinely unused, or the
   project reads as "damaged".

**Do not add Capacitor plugins from npm.** They keep their Swift source in
`node_modules`, and `Package.swift` then points at a path a clean clone does not
have. Write the plugin in the app target and register it on the bridge in
`MainViewController`, the way `HealthPlugin.swift` and `NotifyPlugin.swift` do.

---

## Version numbers

`MARKETING_VERSION` is what TestFlight shows as the version (currently `1.1`).
Bump it when a batch of changes is worth naming.

`CURRENT_PROJECT_VERSION` is the build number, **pinned at 1**. If an upload is
ever rejected for a duplicate build number, that is why, and the fix is a small
`ci_pre_xcodebuild.sh` in `ios/App/ci_scripts/` setting it from
`$CI_BUILD_NUMBER`.

---

## Still not solved

- **No billing.** Choosing a plan applies its limits locally; nothing is
  charged. Subscriptions have to become StoreKit products before the app can
  take money — real work, not a config change.
- **No password reset.** Forget the password and there is no way back in.
- **Seller name.** The Developer Program enrolment is Individual, so the public
  App Store listing will show a legal name. Changing it means registering a DBA
  or converting to an Organization account. TestFlight shows nothing public, so
  this only matters before release.
- **Guideline 4.2.** A shell around a web app can be rejected as a website in a
  wrapper. Apple Health and local notifications make that argument much safer
  than it was.

---

## How it got here

Six configuration failures, each hiding the next, all worth knowing because they
are the shape of every future break:

1. No shared `.xcscheme` in the repo — the scheme `xcodebuild -list` shows can
   be autocreated and absent from a clean clone.
2. `public/`, `config.xml`, `capacitor.config.json` generated and gitignored but
   referenced by the project.
3. `ci_scripts` at the repo root instead of beside the `.xcodeproj`; then
   `set -u` against an unset `CI_WORKSPACE`. Deleted the script entirely.
4. `DEVELOPMENT_TEAM` was the Capacitor template's, not yours — hidden for three
   builds because local builds passed the right team on the command line.
5. The default workflow has a Test action; there are no test targets.
6. Ad-hoc and development exports need a registered device or they exit 70, even
   though app-store export succeeds.
