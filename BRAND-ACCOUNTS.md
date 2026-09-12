# Brand accounts & migration map

Generated Sep 12, 2026 from a full sweep of the repo, HQ folder, memory notes, git/SSH config and local tool config. The brand identity is **fatcamp.ai@gmail.com**. This is the honest map of what is bound to the personal address, what can move, how, and whose hands each step needs.

## First: harden the brand mailbox

Rotate the password (it was pasted into a chat once), turn on 2-step verification, set recovery phone + recovery email, and make sure it is an inbox that gets read daily — every account below inherits its strength.

## Account by account

### Google — fatcamp.ai@gmail.com (destination) — movable: n/a

- **Bound to:** New Google account Tanner created 2026-09-12 (memory/fatcamp-brand-accounts.md). Password was pasted into chat once and should be rotated.
- **Role:** The brand identity every other account is supposed to hang off: privacy contact, ASC contact/user, GitHub/Supabase/Anthropic member, future IG/TikTok/YouTube logins.
- **How:** Before moving anything onto it: rotate the password, turn on 2-step verification, set recovery phone + recovery email (tanman0495@gmail.com is fine as recovery), and confirm the inbox is one the owner actually reads daily.
- **Risk:** If this mailbox is weak or unwatched, every account bound to it inherits that weakness; Apple review mail and user privacy requests will go here.
- **Whose hands:** Owner only (password, 2FA).

### Apple Developer Program / Apple Account (Account Holder) — movable: partially

- **Bound to:** Unknown from files. Individual enrollment (XCODE-CLOUD.md 'Seller name'). The Apple Account email holding it is nowhere in the repo, HQ docs or memory; memory only says ASC login lives in the tanman0495@gmail.com Chrome profile and that the App Review contact is tfrancis26@jcu.edu. Team ID: not in files (DEVELOPMENT_TEAM = "" in project.pbxproj; Xcode Cloud supplies it). Xcode on this Mac has no Apple ID signed in (defaults list empty).
- **Role:** Owns bundle id com.frennat.fatcamp, ASC app 6799269953 (FatCamp.AI 1.3, subs pro.monthly/max.monthly, group 22294910), Paid Apps agreement + banking/tax, Small Business Program, certificates, Xcode Cloud, TestFlight, HealthKit entitlement, App Store Server Notifications webhook (asc-notify).
- **How:** For an Individual enrollment the Account Holder cannot be reassigned. Three options, safest first. (1) Add access without moving ownership: owner creates an Apple Account for fatcamp.ai@gmail.com (2FA required), then ASC → Users and Access → + → invite it as Admin with App Status Reports notifications; set it as App Review contact on 1.4. Nothing else changes. (2) Re-email the existing Apple Account: account.apple.com → Sign-In and Security → change the Apple Account email to fatcamp.ai@gmail.com (allowed only if the current Apple Account is a third-party address, not @icloud/@me, and fatcamp.ai@gmail.com is not already an Apple Account). Team, app, subs, agreements, Xcode Cloud all stay intact. BUT if that Apple Account is also his personal iCloud/App Store identity, every device and purchase would now sign in as the brand address — only do this if it is a developer-only Apple Account. (3) App Transfer: enroll a NEW developer account under fatcamp.ai@gmail.com ($99/yr, identity check, 1–2 days; Organization needs D-U-N-S + legal entity), accept Paid Apps agreement + banking/tax there, then ASC → App Information → Transfer App → recipient Team ID + Apple ID → recipient accepts.
- **Risk:** App Transfer criteria: no version, subscription or IAP in Waiting for Review / In Review (or otherwise unsettled) — an in-review app cannot transfer; Apple requires the app to have an approved version and both parties on the latest agreements (verify against the current ASC Help list). Transfer drops ALL TestFlight builds and testers, does not carry Xcode Cloud workflows, certificates, provisioning profiles, in-app purchase keys/App Store Server API keys (all team-scoped — regenerate); re-verify the asc-notify webhook URL afterwards; Small Business Program must be re-enrolled on the new account (30% commission until accepted); subscribers keep their subscriptions and proceeds switch to the recipient from the transfer date; seller name is still the legal name unless Organization/DBA. read-workout's JWS check pins bundle id + Apple root, not the team, so it survives. Option (2) risk is the personal-iCloud side effect. Option (1) has essentially no risk.
- **Whose hands:** Owner only: Apple Account creation, 2FA on a trusted device, identity verification, agreements, banking. Claude can drive ASC in his signed-in Chrome only for non-credential steps (e.g. adding a user, editing contact fields on an editable version).

### App Store Connect metadata (app 6799269953) — movable: partially

- **Bound to:** The developer team above. App Review contact = Tanner Francis / +1 716 870 7151 / tfrancis26@jcu.edu (memory). Support URL and Privacy URL point at frennat.github.io (GitHub username). Copyright 'Tater Tot Studios'. Both subscriptions' metadata untouched during 1.3 review.
- **Role:** Listing, review correspondence, subscriptions, TestFlight, Xcode Cloud, server-notification webhook registration (Production + Sandbox).
- **How:** Contact email/phone: edit on the next editable version (1.4 in Prepare for Submission). Support/Privacy URLs: change only if/when the site URL changes (custom domain). Add fatcamp.ai@gmail.com as an ASC user for notifications. Ownership moves only via App Transfer (previous row).
- **Risk:** FLAGGED: nothing should be edited on a version Apple is currently reviewing; current review state on 2026-09-12 is unknown from files (1.3 approved 8/31; 1.4 pre-review pass still pending per memory) — check ASC first. If the GitHub Pages URL ever changes, Apple will see a dead privacy URL.
- **Whose hands:** Owner (ASC login, 2FA); Claude can edit fields in his signed-in session once he confirms the version is editable.

### Xcode Cloud — movable: partially

- **Bound to:** Apple team + the GitHub App authorization granted by the frennat GitHub account for repo frennat/fatcamp (workflow 'Fatcamp', Distribution Preparation = App Store Connect since 2026-08-11; build numbers from ios/App/ci_scripts/ci_pre_xcodebuild.sh).
- **Role:** Push to main → archive on Apple hardware → TestFlight / store-eligible builds.
- **How:** If the Apple team and the GitHub repo owner both stay: nothing to do. If the repo transfers to another GitHub account: re-install the Xcode Cloud GitHub App on the new owner and re-link the workflow's primary repository in ASC. If the Apple team changes (App Transfer): recreate product + workflow from scratch in the new team (set Distribution Preparation = App Store Connect, tester-group auto-distribute).
- **Risk:** Workflows never transfer between teams. Rebuilt workflows re-hit the two silent traps documented in XCODE-CLOUD.md (TestFlight-internal-only distribution; build counter behind the project — the ci script guards the second). CI_BUILD_NUMBER counter resets on a new workflow.
- **Whose hands:** Owner for the GitHub OAuth grant and any Apple sign-in; Claude can verify builds via the GitHub check-runs API.

### TestFlight — movable: no

- **Bound to:** Apple team; Internal Testing group with auto-distribute; the tester Apple ID on Tanner's phone (unknown from files).
- **Role:** Delivers builds 38+ to his phone for 1.4 QA.
- **How:** Not transferable. After any App Transfer, re-upload a build and re-create the internal group + tester.
- **Risk:** All builds and testers are discarded on App Transfer; a paused workflow means no build offered on the phone (documented silent failure).
- **Whose hands:** Owner (Apple ID on device).

### GitHub account 'frennat' — movable: yes

- **Bound to:** Primary email tanman0495@gmail.com (git author on all 117 commits, ~/.gitconfig, SSH key comment). Repo github.com/frennat/fatcamp (public), Actions workflow supabase-keepalive.yml (embeds the Supabase publishable key), Xcode Cloud GitHub App, GitHub Pages. gh CLI is not installed; pushes go over SSH with ~/.ssh/id_ed25519.
- **Role:** Source of truth, deploy trigger for both Pages and Xcode Cloud, host of the product URL.
- **How:** Safest: GitHub → Settings → Emails → add fatcamp.ai@gmail.com, verify from the brand inbox, set as primary; keep tanman0495@gmail.com as a secondary verified email so history stays attributed; notifications (Pages/Actions/Xcode Cloud status mail) then flow to the brand inbox. Then `git config user.email fatcamp.ai@gmail.com` inside the repo. Alternatives: create a second GitHub account under fatcamp.ai@gmail.com and add it as a collaborator (Settings → Collaborators), or transfer the repo (Settings → Danger Zone → Transfer) — see GitHub Pages row before doing that.
- **Risk:** Changing the primary email is zero-risk. Transferring the repo or renaming the user breaks the Pages URL (next row), requires re-adding the SSH key and re-installing the Xcode Cloud GitHub App, and scheduled Actions may need re-enabling on the new owner. If the Supabase login is GitHub OAuth, it follows the GitHub user id, not the email, so an email change does not affect it.
- **Whose hands:** Owner (GitHub login/2FA, email verification click). Claude can do the repo-local git config and doc edits.

### GitHub Pages — https://frennat.github.io/fatcamp/ — movable: partially

- **Bound to:** The GitHub username 'frennat' (project site, branch main, root). No custom domain.
- **Role:** IS the product: web app, marketing site (/site/), privacy policy (/site/privacy.html). Hard-wired into: index.html:9068 (and its www/ and ios/App/App/public/ copies) privacy link; ASC Support + Privacy URLs; Quick Links/*.webloc and Fatcamp HQ.html; the five printed poster QR codes (Marketing/QR Codes/h1–h5.svg → ?p=h1…h5); MARKETING.md/README/DEPLOY/XCODE-CLOUD docs; Supabase Auth Redirect URLs (README:108); installed PWAs' service-worker scope.
- **How:** Do NOT transfer the repo or rename the user until a custom domain is in place: buy a domain (e.g. the fatcamp.ai brand domain), add it as the Pages custom domain (CNAME) with HTTPS, update every reference above, re-register ASC URLs on an editable version, add the domain to Supabase redirect URLs, reprint posters. Only then can the repo live under any GitHub owner without breaking anything.
- **Risk:** HIGH if the URL changes: GitHub redirects github.com/frennat/fatcamp after a transfer but does NOT redirect *.github.io Pages URLs, so every printed QR code, the app's privacy link, the ASC privacy URL Apple checks, and existing home-screen installs (service worker scope) all die at once.
- **Whose hands:** Owner buys the domain and sets DNS; Claude can do all reference edits.

### Supabase — movable: yes

- **Bound to:** Org isevbuknjsyfcgcxqgpz, project chghvwnytjlakuvkkluv (still named 'Lifted.AI' — supabase/.temp/linked-project.json). Login identity unknown from files (memory: the session lives in the tanman0495@gmail.com Chrome profile; whether it is GitHub OAuth, Google, or email+password is not recorded). Free tier (2-project cap, pauses after a week idle — GitHub Action keeps it awake). The Supabase CLI on this Mac is logged in as that same unknown identity (token in keychain, not read).
- **Role:** Auth (email+password, Confirm email OFF, built-in SMTP — no custom sender), tables standings/sessions/waitlist/events/subs/sub_events/ai_reads, edge functions read-workout / asc-notify / metrics, secrets ANTHROPIC_API_KEY, METRICS_KEY, MODEL, ALLOW_SANDBOX.
- **How:** Dashboard → Organization → Team → Invite fatcamp.ai@gmail.com as Owner → owner creates a Supabase account under that address (email+password or Google) and accepts → verify it can see the project → then optionally demote/remove the old member (the last Owner cannot be removed). Alternative: Organization → Project settings → Transfer project to a new org owned by the brand account. Afterwards run `npx supabase login` on this Mac under the new identity so CLI deploys keep working.
- **Risk:** Low for a membership change: project ref, publishable key, secrets, functions, webhook URL and data all stay put. A brand-new org re-inherits the free-tier caps (2 active projects, 1-week pause). No Resend key or SMTP is configured anywhere in the repo, so auth mail is not bound to any personal account.
- **Whose hands:** Owner (both logins, invite acceptance); Claude can re-link the CLI and update DEPLOY.md after.

### Anthropic Console (API billing) — movable: partially

- **Bound to:** Unknown from files. The console login email is not recorded anywhere; the only footprints are the HQ card/webloc to console.anthropic.com, the Notebook's 'Re-set the Anthropic API key' note, and the key stored as the Supabase secret ANTHROPIC_API_KEY. It may or may not be the same org as the Claude account tfrancis26@jcu.edu used by Claude Code.
- **Role:** Pays for every Upload Media read (read-workout, MODEL=claude-haiku-4-5, ~1.6¢/video); monthly spend limit lives here. Memory: 'the first real bill is Anthropic'.
- **How:** Console → Settings → Members → invite fatcamp.ai@gmail.com as Admin (owner accepts from the brand inbox). API keys are organization-scoped, so the Supabase secret needs no change. Check in the console whether the Primary Owner (billing) role can be reassigned; if the UI does not offer it, it is an Anthropic support request. If instead a fresh org is created under the brand email: create a key there, `npx supabase secrets set ANTHROPIC_API_KEY=...`, move the spend limit/payment method; prepaid credits do not transfer.
- **Risk:** If the org's only owner is the jcu.edu identity, that address expiring strands billing. Rotating the key breaks Upload Media until the secret is updated (Max users silently fall back to OCR per memory).
- **Whose hands:** Owner (login, billing, key creation — API keys are credentials Claude must not handle); Claude can run the secret-set command once the owner supplies the key out of band.

### Claude.ai / Claude Code (tfrancis26@jcu.edu) — movable: no

- **Bound to:** tfrancis26@jcu.edu (this session; ~/.claude.json). Owns the Poster Designs artifact https://claude.ai/code/artifact/dddce29e-7b30-4b58-af8d-f553ac0c9fea (linked from Fatcamp HQ.html and Quick Links), these memory notes, the Chrome extension, and the 'claude.ai Higgsfield' / 'claude.ai OpenArt.AI' connectors.
- **Role:** Workshop tooling; the poster artifact is the only brand asset that lives only here.
- **How:** Artifacts cannot be transferred between accounts. Export the five posters to PDF into Desktop/Fatcamp/Marketing/ and update the HQ link/webloc to the local file; if a brand Claude account is wanted later, re-publish from the saved HTML.
- **Risk:** University address will expire on graduation; the artifact link and connector authorizations go with it.
- **Whose hands:** Owner (account); Claude can export/re-publish the artifact now.

### Higgsfield — movable: no

- **Bound to:** Unknown from files. Connected to Claude as connector 'claude.ai Higgsfield'; MARKETING.md:268 notes 0.38 credits left on the current plan; memory says the TikTok publish OAuth click is the owner's. No email or login method recorded.
- **Role:** AI b-roll / trend clips for the launch content kit; TikTok publishing bridge.
- **How:** No ownership transfer exists for a consumer AI-media account. Owner creates a new Higgsfield account under fatcamp.ai@gmail.com (Google or email login), re-authorizes the Claude connector and the TikTok connection from it, and cancels any paid plan on the old account after the remaining credits are used.
- **Risk:** Credits, generation history and the existing TikTok OAuth link do not move.
- **Whose hands:** Owner only (account creation, OAuth clicks, CAPTCHAs).

### OpenArt — movable: no

- **Bound to:** Unknown from files. Connector 'claude.ai OpenArt.AI' exists in ~/.claude.json; no repo/HQ/memory file references OpenArt in Fatcamp work.
- **Role:** Image generation tool available to the workshop; no Fatcamp asset is documented as depending on it.
- **How:** If it should live under the brand: owner creates an OpenArt account with fatcamp.ai@gmail.com and re-connects the Claude connector. Otherwise leave it as a personal tool.
- **Risk:** None to the product; history/credits stay on the old account.
- **Whose hands:** Owner.

### Resend — movable: n/a

- **Bound to:** Unknown from files. Memory calls the backend 'free Supabase + Resend', but no Resend key, domain or SMTP config exists in the repo, and the shipped app sends no email (signup with Confirm-email OFF, no magic link, no password reset).
- **Role:** None today; would matter only if password reset / magic links ship (then the 100/day cap binds).
- **How:** If an account exists, either leave it or invite the brand address; nothing in production depends on it. When email is eventually wired up, create it fresh under fatcamp.ai@gmail.com with a brand sending domain.
- **Risk:** None currently.
- **Whose hands:** Owner.

### Social accounts (Instagram / TikTok / YouTube) — planned — movable: n/a

- **Bound to:** Not created yet; per MARKETING.md:266 and memory they are meant to be created under the brand email.
- **Role:** Launch content distribution (?p=tt / ?p=ig / ?p=yt attribution codes are already live in the app).
- **How:** Create directly under fatcamp.ai@gmail.com from the 'Fatcamp' Chrome profile so nothing ever touches the personal address; Claude preps handles/bios/profile art (Marketing/Social/fatcamp-profile-*.png).
- **Risk:** Platform sign-ups involve CAPTCHAs and phone verification.
- **Whose hands:** Owner creates and signs in; Claude runs profiles/posts afterwards on explicit go.

### Local git/SSH identity on this Mac — movable: yes

- **Bound to:** ~/.gitconfig user.email = tanman0495@gmail.com (no repo-local override); ~/.ssh/id_ed25519 (comment tanman0495@gmail.com) registered on GitHub 'frennat'.
- **Role:** Every commit/push from this machine.
- **How:** `git -C /Users/tannerfrancis/Desktop/Fatcamp/fatcamp config user.email fatcamp.ai@gmail.com` after the address is verified on the GitHub account; keep the SSH key (or generate a new one and add it to GitHub).
- **Risk:** Setting the email before GitHub verifies it produces unattributed commits (cosmetic, reversible).
- **Whose hands:** Claude can set the config; owner verifies the email on GitHub.

## File-level references

- DONE/SAFE — `/Users/tannerfrancis/Desktop/Fatcamp/fatcamp/site/privacy.html`: <a href="mailto:fatcamp.ai@gmail.com">fatcamp.ai@gmail.com</a> (change both the href and the visible text). Optionally also bump the 'Last updated' date on line 221. *(This is the only user-facing personal-email reference in the whole project and the one App Review actually reads. Swapping a contact address changes no data-practice claim, so it cannot contradict an in-flight review the way the Upload Media wording could. It is not mirrored into www/ or ios/App/App/public/ (only index.html is), so no `npm run sync` is needed — commit + push and GitHub Pages republishes in about a minute. Verify the brand mailbox is actually monitored before pushing, since this becomes the address Apple and users write to.)*
- DONE/SAFE — `/Users/tannerfrancis/Desktop/Fatcamp/fatcamp/MARKETING.md`: **Unblocked:** the brand mailbox is fatcamp.ai@gmail.com (created 2026-09-12); the social accounts follow it. *(Internal planning doc in the repo; nothing external reads it. After editing, regenerate Desktop/Fatcamp/Marketing/Marketing Plan.docx from it (the .docx is a pandoc export of this file per memory/fatcamp-hq-layout.md).)*
- DONE/SAFE — `/Users/tannerfrancis/Desktop/Fatcamp/Marketing/Marketing Plan.docx`: Regenerate the .docx from the corrected MARKETING.md rather than hand-editing (source of truth is the .md). *(Human-facing HQ document only; it follows the .md. No LibreOffice on this Mac (memory), so regenerate with pandoc or the docx skill, not by round-tripping through Office.)*
- DONE/SAFE — `/Users/tannerfrancis/.claude/projects/-Users-tannerfrancis-Desktop-Conduit/memory/fatcamp-launch-funnel.md`: **Brand email: fatcamp.ai@gmail.com** (created 2026-09-12; see fatcamp-brand-accounts.md). *(Stale memory note; it will mislead future sessions into referencing the wrong address.)*
- HOLD — `/Users/tannerfrancis/.claude/projects/-Users-tannerfrancis-Desktop-Conduit/memory/fatcamp-app-store-submission.md`: Update this line only after the ASC field itself is changed (to 'contact … fatcamp.ai@gmail.com'). *(The memory line is just a record; the binding it documents is App Store Connect metadata (see next entry). Changing the note before ASC changes would make the record wrong.)*
- HOLD — `APP STORE CONNECT (not a file) — App 6799269953 → version page → App Review Information → Contact Information (email = tfrancis26@jcu.edu, phone +1 716 870 7151); also Users and Access notification emails`: fatcamp.ai@gmail.com as the App Review contact on the NEXT editable version (1.4, 'Prepare for Submission'); additionally add fatcamp.ai@gmail.com as an ASC user (Users and Access) with App Status Reports notifications so review mail reaches the brand inbox without changing ownership. *(FLAGGED: App Review Information is per-version and is read-only while a version is Waiting for Review / In Review; per memory 1.3 was approved 2026-08-31 (manual release), but the current state on 2026-09-12 is unknown from files — verify in ASC before touching anything. Do not edit metadata on a submission Apple is looking at. Also note tfrancis26@jcu.edu is a university address that will lapse; Apple correspondence must land somewhere the owner reads. Owner's hands (ASC login + Apple 2FA).)*
- DONE/SAFE — `/Users/tannerfrancis/.gitconfig`: Leave the global config alone (other projects use it); in the fatcamp repo run `git config user.email fatcamp.ai@gmail.com` (or the GitHub noreply address) so new commits carry the brand address. Do NOT rewrite history — the 117 existing commits stay as they are. *(Repo-local override is harmless, but GitHub only links new commits to the frennat profile if fatcamp.ai@gmail.com has first been added and verified on that GitHub account (Settings → Emails), otherwise they show as unattributed. Keep tanman0495@gmail.com as a secondary verified email on GitHub so past commits stay attributed.)*
- DONE/SAFE — `/Users/tannerfrancis/.ssh/id_ed25519.pub`: No change needed — the comment is cosmetic; the binding is the key registered on GitHub. If the repo ever moves to a different GitHub account, add this public key (or a new one) to that account. *(Purely informational; nothing reads the comment.)*
- HOLD — `/Users/tannerfrancis/.claude.json`: Nothing to edit in the file. Export the poster artifact to PDF into Desktop/Fatcamp/Marketing/ so no brand asset depends on the jcu.edu Claude account; consider a Claude account under fatcamp.ai@gmail.com later. *(Tool account, not project metadata; jcu.edu is a student address that will expire, which would strand the artifact link.)*
- DONE/SAFE — `/Users/tannerfrancis/.claude/projects/-Users-tannerfrancis-Desktop-Conduit/memory/fatcamp-brand-accounts.md`: Keep as-is; amend once individual logins actually move to the Fatcamp Chrome profile / brand address. *(Accurate description of the current state; it is the map for the migration, not something to change ahead of it.)*

## Sweep notes

Scope and method: grepped the repo (all text types, excluding node_modules/.git/dist/build), the HQ folder (HTML, .webloc XML, and the Word/Excel files via unzip/Python), and every memory note; also checked ~/.gitconfig, the repo's git log/remotes, SSH public-key comments, Xcode's account defaults (empty), Supabase's linked-project metadata, and email addresses only (no tokens) in ~/.claude.json. No browser tools were used.

Headline: exactly ONE user-facing personal-email reference exists in the whole project — site/privacy.html:233 (mailto:tanman0495@gmail.com). It is safe and worth changing now; it is the page Apple's Privacy Policy URL points at and the app's paywall links to. Everything else is either stale internal text mentioning the abandoned 'fatcamp@gmail.com' (MARKETING.md:266, its .docx export, memory/fatcamp-launch-funnel.md:18), local git identity, or App Store Connect metadata that is not in any file.

Bindings I could NOT determine from files: the Apple Account email that holds the Individual developer enrollment (only known: ASC login lives in the tanman0495 Chrome profile; App Review contact is tfrancis26@jcu.edu); the Supabase login method/email; the Anthropic Console login; Higgsfield/OpenArt logins; whether a Resend account exists at all; the ASC review state on 2026-09-12 (memory ends at 1.3 approved / pending manual release on 8/31, with 1.4's pre-review pass still to do).

Two things that matter more than any email: (1) The brand's real identity surface is the GitHub username 'frennat', not an email — frennat.github.io/fatcamp is hard-coded in index.html:9068 (plus www/ and ios public copies), in ASC's Support/Privacy URLs, in the printed QR posters (h1–h5), in Supabase redirect URLs, and in every HQ link. Changing the GitHub primary email is free; transferring the repo or renaming the user without a custom domain first would take the product, the privacy URL Apple checks, and every printed poster offline at once. (2) Apple ownership cannot simply be re-emailed for an Individual enrollment; the low-risk move is adding fatcamp.ai@gmail.com as an ASC user + review contact, and an App Transfer is a last resort that must not be attempted while anything is in review and that drops TestFlight and Xcode Cloud.

Suggested order: harden fatcamp.ai@gmail.com (rotate the pasted password, 2FA, recovery) → repo-side edits (privacy.html, MARKETING.md + regenerate the .docx, memory notes) → add the brand address as a member/user on GitHub (primary email), Supabase (Owner), Anthropic (Admin), ASC (Admin user + 1.4 review contact) — no ownership transfers → export the poster artifact to PDF → buy a domain before ever touching the GitHub repo owner/username → consider App Transfer only if a legal-entity seller name is wanted. Per the hard rule in memory, all account creation, sign-ins, 2FA, CAPTCHAs and API keys are the owner's hands; Claude handles file edits, doc regeneration, CLI re-link, and drives already-signed-in sessions for non-credential steps.
