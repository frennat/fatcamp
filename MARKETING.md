# Getting the first hundred people to use Fatcamp

Written for a standing start: no social, no ad budget, no press. Posters,
stickers, and people telling other people.

---

## The thing to fix before printing anything

**Right now a QR code has nowhere good to send someone.** The app is in
TestFlight, and TestFlight is a wall: a public link needs Beta App Review, and
without one you are adding testers by Apple ID one at a time. Nobody scanning a
poster in a coffee shop is going to do that.

But `frennat.github.io/fatcamp/` already works. It opens instantly in Safari,
it installs to the home screen, it works offline, and it needs no account. That
is the QR target. The App Store version becomes the target later, and the same
sticker keeps working because you control the URL.

So: **point every QR at the web app.** Do not wait for the App Store.

---

## The offer is the whole game

A poster gets about three seconds. "AI workout app" earns none of them — that
phrase is worn out, and the person reading it already has three fitness apps
they stopped opening.

What is actually unusual about this app, in the order a stranger would care:

1. **It writes the session for you in about a minute.** You say what you have
   and how you feel; it hands you the workout. No programme to follow, no
   subscription to think about first.
2. **It works with whatever equipment you have** — a full gym, three dumbbells,
   or nothing at all.
3. **It works signed out.** Nothing to create, nothing to verify, no email.

That third one is the sharpest thing you have and almost nobody leads with it.
"No account. No email. Just a workout." is a poster.

**Test the headline before you print a hundred.** Print five, put them in five
places, use a different QR on each, and see which gets scanned.

---

## Where to put things, easiest permission first

| Where | Who you reach | How hard | Notes |
| --- | --- | --- | --- |
| Coffee shops with a community board | Broad, high foot traffic | Easy — most say yes | Ask the person at the counter, not corporate |
| Campus buildings (JCU, UB) | Students, high app adoption | Easy | Usually a stamp from student affairs |
| Climbing gyms / CrossFit boxes | Already training, already app-literate | Medium | Owner-run, so one conversation decides it |
| Physical therapy / chiro waiting rooms | People rebuilding, need limits respected | Medium | Your injury-limits feature is the pitch here |
| Big-box gyms (Planet, LA Fitness) | Perfect audience | **Hard** | They sell training. You look like competition |
| Bike shops, run clubs, rec centres | Cardio-side, cross-over | Easy | Under-used and under-competed |

**Do not lead with big-box gyms** even though the audience fits best. A manager
who thinks you are poaching personal-training revenue says no and remembers you.
Independent gyms where the owner is on the floor are a different conversation —
they will say yes or no in thirty seconds and mean it.

The waiting-room angle is the one most people miss. Someone sitting in physio
has a specific reason to want a workout that routes around a bad shoulder, and
your app does that. That is a warmer audience than a gym full of people who
already have a routine.

---

## Stickers

Different job from posters. A poster explains; a sticker is a reminder for
someone who already heard about it. Put them where someone is standing still
and bored:

- Water fountains, squat-rack uprights, the inside of bathroom stall doors
- Bus shelters and the back of stop signs on running routes
- Laptop stickers — give them away, they travel

Keep them small, one line of text, and a code. Do not try to explain the app on
a two-inch sticker; the URL does the explaining.

**Ask before sticking things on private property.** A gym that finds unapproved
stickers on its equipment removes all of them and remembers your name. The
approved ten beat the unapproved hundred.

---

## Make every code tell you where it came from

This is the highest-value thing in this document and it costs almost nothing.

Give each location its own URL: `frennat.github.io/fatcamp/?p=spot-coffee`,
`?p=jcu-rec`, `?p=elmwood-physio`. The app reads `p`, stores it, and you learn
which five of your forty placements are doing all the work — so you print more
of those and stop wasting paper on the rest.

Without this you are guessing, and after two months you will have no idea
whether the coffee shops or the physio offices worked. *I can wire the `?p=`
capture into the app whenever you want it — it is small.*

---

## The word-of-mouth loop

Word of mouth does not happen because an app is good. It happens because
someone has a reason to say a sentence out loud.

The reason here is the **streak and the standings**. Someone on a 40-day streak
who is second on a leaderboard has something to talk about. That machinery is
already built, which means the marketing job is mostly getting people far
enough in to care.

What actually helps:

- **Get the first twenty users in person.** Not posters — people you can hand
  your phone to. Watch where they get confused. That is worth more than a
  thousand impressions.
- **A regional leaderboard needs regional density.** Twenty people in East
  Aurora beats two hundred scattered nationally, because twenty locals can see
  each other on the board. Concentrate the posters geographically on purpose.
- **Ask the first users directly.** "Who else would like this?" converts far
  better than any share button.

---

## What to measure, and when to stop

Check weekly:

- **Scans per placement** — from the `?p=` codes
- **Scan → forged a session** — the only conversion that matters; a scan that
  bounces is a wasted poster
- **Came back on day 2 and day 7** — retention is the honest signal

**Rules of thumb.** A placement with under five scans in two weeks is dead;
pull it. A placement converting under one in ten to a forged session means the
poster is over-promising or the first screen is confusing — that is a product
fix, not a printing fix. If day-7 retention is under 10%, stop printing
entirely and fix retention first, because more people will not help.

---

## First two weeks, concretely

1. Pick one headline and one alternate. Print **five posters each**, ten total.
2. Ten placements, ten different `?p=` codes. Mix coffee shops, campus, one
   physio, one independent gym.
3. Get twenty people in person — friends, gym floor, wherever. Watch them use it.
4. Wait two weeks. Read the scan numbers.
5. Print fifty more of whichever headline won, in the two location *types* that
   won. Kill the rest.

Ten placements is enough to learn from and cheap enough to throw away. A
hundred posters of an untested headline is how people waste a few hundred
dollars and conclude that posters do not work.

---

## Reaching out to creators

See [OUTREACH.md](OUTREACH.md). Short version: the accounts worth messaging
right now are local coaches and gym owners at 1k–20k followers, not
influencers — and the ask is "tell me what's wrong with it," not "please
promote this."

---

## Posters themselves

I can design these — poster layouts, sticker sheets, the QR codes with the
per-location codes baked in, print-ready. Say the word and tell me:

- Print size (11×17 is the usual community-board size; 8.5×11 fits more places)
- Whether to match the app's dark look or invert to light for cheaper printing
  (dark posters eat toner and look bad on a home printer — worth deciding early)

---

## Short-form video, and the trend mandate *(added Aug 30, 2026)*

**Standing rule from Tanner: every AI-generated video follows current trends.**
Before each batch, check what's actually pulling views that week — formats,
sounds, hooks — and shape the batch to ride it. Trends are checked at
production time, never assumed from an old note (this section's snapshot
included).

### The hybrid production model

Two content streams, one feed:

1. **Zero-cost app captures** (the recording rig): the real product forging
   real sessions. These carry the proof. Cost: $0, unlimited.
2. **AI-generated b-roll and trend riffs** (Higgsfield): gym atmosphere,
   trend-format skits, hooks. These carry the reach. Cost: credits.

The AI garnishes the real thing — never the reverse. A stranger should always
land on what the app actually does.

### Budget math (Higgsfield credits)

Measured ratios from their live pricing: a basic clip (Kling-tier, 5s) ≈ 5
credits; a premium clip (Seedance-tier) ≈ 25 credits; a finished video takes
2–3 generation attempts. Rule of thumb: **plan ~15 credits per finished basic
clip, ~60 per finished premium clip.** An entry-tier plan (~300–400
credits/mo) supports roughly 5–7 finished basic clips or ~5 premium hero
clips per month — so the cadence below leans on the free stream for volume
and spends credits on the highest-leverage trend pieces.

### Cadence that fits an entry plan

4–5 posts/week across TikTok + Reels + Shorts (same video, re-cut):
- 2–3 × zero-cost app captures (new ask lines each time — "leg day, 45
  minutes", "bad shoulder, work around it")
- 1–2 × AI-assisted trend pieces (this week's format, Fatcamp twist)

Platform cuts: TikTok 15–30s · Reels 30–60s · Shorts 60–90s. Longer
(60–90s) currently outperforms ultra-short on most platforms — make the
long cut first, trim down.

### Formats that map to Fatcamp (trend snapshot, Aug 2026)

- **Micro-education clips** — one movement, why it's in the session. The
  app's own "why it's here" coaching lines are ready-made scripts.
- **"With me" companion videos** — "forge today's workout with me": type the
  ask on camera, session appears, go lift.
- **Serialized storytelling** — "Day N of letting AI write my workouts."
  Recurring, cheap, compounding.
- **Founder visibility** — Tanner building the thing, unscripted.
- **Fitness-side trends** — variety training (mobility, boxing, dance),
  tech-in-training, community/leaderboard angles.
- Word-level captions on everything; sound added natively in-app at post
  time for algorithmic favor.

### The weekly ritual

Every batch day: 10 minutes on each platform's trending/fitness feeds +
trending-audio charts → pick one format to ride → write the Fatcamp twist →
generate/capture → post with per-platform ?p= links in bio.

## Day 1 production log (Aug 31, 2026)

**Trend check at production time (per the standing rule).** This week: lo-fi,
handheld, single-topic tutorials are OUTPERFORMING polished edits (the
polish-to-value ratio inverted); before/after formats want the "after" as the
opening hook; day-in-the-life with a specific frame is the strongest hook
structure; repetition ("Bob") and side-by-side comparison formats are the big
general-purpose templates. Zero-cost app captures are exactly the winning
grain right now.

**Produced today (zero cost, from the real app):**
- `Fatcamp Day1 - Coached in 3D.mp4` (~24s) — type the ask, forge, open the
  deadlift's 3D demo (the new authored biomechanics), orbit, end card.
- `Fatcamp Day1 - Before After.mp4` (~21s) — opens ON the "Another one down"
  bank celebration (after-first hook), rewinds to the 15-second ask, logs
  sets, banks.
- Plus `Fatcamp Demo Short v1.mp4` from Aug 30 = a three-clip Day-1 kit.

**Captions, ready to paste** (link in bio gets a per-platform code:
`?p=tt` TikTok, `?p=ig` Reels, `?p=yt` Shorts — attribution is live now):
- Coached in 3D: "POV: your workout app actually shows you how to deadlift.
  Hips back BEFORE they go down. #gymtok #deadlift #formcheck"
- Before/After: "From 'idk what to train' to a banked session in under a
  minute. No account. No email. #homeworkout #gym #fitnessapp"

**Unblocked Sep 12:** the brand mailbox is **fatcamp.ai@gmail.com** (created
2026-09-12); the social accounts follow it under the handle **fatcamp.ai** on
both Instagram and TikTok (verified free on both; plain @fatcamp is taken on
TikTok). The AI trend piece still waits on a Higgsfield plan (0.38 credits).

## Social launch kit (Sep 12, 2026)

**Handle everywhere:** `fatcamp.ai` · **Display name:** FATCAMP.AI

**Instagram bio** (141/150):

```
Type "push day at home, go hard." Full workout in under a minute.
No account. No email. Just a workout.
iOS + web. The reps are still on you.
```

**TikTok bio** (72/80):

```
Type what you want to train. Full workout in under a minute. No account.
```

Link field: TikTok `https://frennat.github.io/fatcamp/?p=tt` · Instagram `https://frennat.github.io/fatcamp/?p=ig` · Shorts channel About `?p=yt`.
Profile picture: `Marketing/Social/fatcamp-profile-320.png` (1080 master alongside).

### Trend check at production time — week of Sep 12

Week of 2026-09-12. Three things are winning for fitness and app content right now. (1) Receipts over affirmations: the "Potential-Maxxing" format (NewEngen Sept 1, SocialBee Sept 10) has creators proving self-improvement with hard numbers on screen instead of vague claims, and "10/10 Habits" rates one concrete habit in the first two seconds; both run on original audio, which matters because business accounts are locked out of most licensed music on Reels. (2) Result-first, then rewind: NapoleonCat's Aug 27 "It's a clock" delayed-realization format (2.4M likes on a caption alone), Ramdam's Sept 9 "You're Staying Until the End" (failed attempts then one clean result) and the Sept 9 "Deep Breaths, Honey" narrative (overwhelmed → with [app] → done) are all payoff-forward structures that the trend sites explicitly recommend for app demos. (3) Underrated-alternative positioning: "Someone Has to Hold It Down" (Sept 2) pits the niche choice against the popular one, and September's startup roundups say raw single-take demos and founder-voice proof are outperforming glossy edits, with social search now favouring plain customer language in captions and on-screen text over hashtag stacks. Hook mechanics have not changed: 1–3 seconds, 8–15 words, three layers (spoken, visual-in-motion, on-screen caption), no throat-clearing opener; 75–85% of TikTok viewing is muted so captions are mandatory, and screen-recording demos land best at 15–30 seconds with critical UI kept in the middle ~1470 px (TikTok chrome eats the bottom ~250 px and top ~150–200 px). Platform signals: Reels ranks on watch time, likes, and sends (sends weighted for new audiences, per Mosseri); the average Short is now ~16 s and small channels' Shorts views are up 200%+, so retention-first; third-party analyses claim TikTok now gates distribution on the first 3 seconds and Shorts on ~65–70% retention (not platform-confirmed, but every source agrees the first frame decides). Sounds this week: on TikTok, "Muscle Drive" (Wbsound, low-key techno used as a workout backdrop), "Mind Blank" (OTE), "Homework" (Lil Sugar) and "Vibin" (Wxoda, +158% on Tokchart Sept 12); on Reels, "Timber" (Pitbull/Kesha) for PR montages, plus original-sound reveal beds "Work & Result" (arceriinteriors), "Wait… Let Me Wipe the Camera" and "Money Can't Buy You Happiness" for process-to-result showcases. Cadence norms: TikTok 2–5/week minimum with new accounts pushed to 1–2/day spaced 3–4 hours apart; Reels 3–5/week; Shorts 2–4/week; startups are told 2–6 high-signal posts a week beats forced volume. Native re-uploads only: a TikTok watermark costs roughly 15% on Reels.

**Formats worth riding:**

- **Potential-Maxxing (receipts on screen)** — Sept 1–10 roundups list it as the dominant self-improvement format: creators prove growth with hard numbers instead of affirmations, original audio, business-account safe. Meltwater measured 'maxxing' usage +96% and engagement +208% Jan–May 2026. *Fatcamp angle:* The bank screen, points, streak count and PR numbers are literally receipts. Open on 'ANOTHER ONE DOWN' with the session total visible; let the numbers do the bragging in a dry voice.
- **Result-first rewind / 'It's a clock' delayed realization** — NapoleonCat Aug 27: show the payoff, then the moment the viewer understands how it happened; one video hit 2.4M likes on a caption. NapoleonCat and Ramdam both flag this structure as the best fit for app demos and 'text prompt to result' workflows. *Fatcamp angle:* Exactly the Before After cut: celebration screen first, rewind to the 15-second typed ask. Add a one-line text hook on frame one so the realization is explicit.
- **Output Showcase (15–30 s screen demo)** — Screenify (Apr 2026) puts tech demos at 15–30 s; Metricool (Jul 29) has the average Short at ~16 s with retention-first ranking; theviralapp lists 'Output Showcase' as a core winning format. Raw single-take demos are outperforming polished edits per mean.ceo (Sept 2). *Fatcamp angle:* All three clips already sit in this window. Keep the typing visible and readable, keep UI in the middle 1470 px, and never open on a splash without a text hook over it.
- **'Someone Has to Hold It Down' (underrated alternative)** — Ramdam Sept 2 and Pepper's September list: text overlay positions the niche choice against the popular one; recommended for apps as the 'underrated solution'. *Fatcamp angle:* 'Everyone's making accounts and picking plans. Someone has to just type push day and go.' The no-account, no-email line is a native fit.
- **'You're Staying Until the End' / struggle then one clean result** — Ramdam Sept 9 (original sound by Em): escalating failed attempts, then it works. Suggested for finance and learning apps showing manual mess → app → organized. *Fatcamp angle:* Future cut, not one of the three: scrolling a generic program, screenshots, notes app chaos, then one typed sentence and a forged session.
- **10/10 Habits rating hook** — NewEngen Sept 1 and Pepper: rate one habit a perfect 10, viewer decides in two seconds whether they agree; original audio or voiceover. *Fatcamp angle:* Caption-level hook for any of the three: 'Typing the workout instead of planning it: 10/10.' Works as a comment-bait first line on Reels.
- **'Everyday, Once a Week, Once a Month' routine format** — Ramdam Instagram Sept 2: routine broken into frequency tiers, flagged as highly relevant for gym and fitness apps. *Fatcamp angle:* Later clip for streaks, heat map and ranks: every day = train and bank, once a week = check the muscle map, once a month = PRs and rank.

### Posting order and captions

**1. Before After** (still fits: yes)
- TikTok: Typed it. Trained it. Banked it. 15 seconds of typing, a full session, no account, no email. Link in bio.
- Instagram: ANOTHER ONE DOWN. /  / Rewind: one typed sentence, 15 seconds, a full session forged. Log the sets, bank it, move on. No account. No email. Just a workout. Link in bio.
- Hashtags: #gymtok #fittok #workoutapp #fitnessapp #pushday #gymmotivation #aiworkout #fatcamp
- Notes: Strongest first post on all three platforms: the celebration screen is a big in-motion first frame (Potential-Maxxing receipts) and the rewind is the 'It's a clock' structure trend sites recommend for app demos. Add a first-frame text hook in the middle third of the frame (pixel 700–1300): 'This took 15 seconds to set up.' Sound: the clip is silent, so record a one-line dry voiceover as original audio ('Fifteen seconds of typing. That's the workout.') and layer keyboard-click foley on the typing plus one low hit on the bank screen. If you want a trending bed: TikTok 'Muscle Drive' (Wbsound) or 'Mind Blank' (OTE) at low volume under the VO; Reels 'Work & Result' (arceriinteriors original) or 'Wait… Let Me Wipe the Camera' for the rewind reveal; 'Timber' only if the account has licensed-music access (creator, not business). Shorts: original audio plus burned captions, since Shorts average ~16 s and loop rate matters. Set the Reels cover to the ANOTHER ONE DOWN frame. Upload natively to each platform (no TikTok watermark on Reels). Bio links: TikTok ?p=tt, Instagram ?p=ig; Shorts descriptions can't carry clickable links, so put the web app in the channel About links.

**2. Demo Short v1** (still fits: yes)
- TikTok: "push day at home, go hard." That's the whole setup. Full session in under a minute. No account. No email. Just a workout.
- Instagram: "push day at home, go hard." /  / That's the entire onboarding. Type what you want to train, get a full session with the muscle figure in under a minute. No account. No email. Just a workout. Link in bio.
- Hashtags: #homeworkout #pushday #workoutapp #fitnessapp #gymtok #fittok #aifitness #fatcamp
- Notes: Fits: it is the Output Showcase plus 'Someone Has to Hold It Down' positioning, and the caption carries the exact search phrases social search now rewards ('push day at home', 'workout app', 'no account'). Weakness: it opens on a splash, which reads as throat-clearing under the 1–3 s hook rule. Fix on-platform without re-cutting: put the text hook over frame one ('Everyone's picking plans. Just type it.') and, on TikTok/Shorts, trim the splash to under a second in the native editor. Sound: dry VO reading the typed line then 'no account, no email, just a workout' as the end card lands; keyboard foley on typing; optional low bed 'Muscle Drive' (TikTok) or 'Money Can't Buy You Happiness' (@eresdigna original, Reels) with beat cuts on the session tour. Post one day after Before After (same order on every platform, stagger platforms by a few hours). Best Shorts candidate of the three for retention because the end card resolves inside 25 s.

**3. Coached in 3D** (still fits: yes)
- TikTok: Every movement, coached in 3D. Orbit the deadlift, check the hinge, fix the setup. Typed the whole session in 10 seconds.
- Instagram: Every movement, coached in 3D. /  / Type "deadlift session", forge it, open any exercise and orbit the demo. New biomechanics under the hood so a hinge looks like a hinge. No account. No email. Link in bio.
- Hashtags: #deadlift #formcheck #liftingform #gymtok #fittok #workoutapp #fitnessapp #fatcamp
- Notes: Fits: the orbit view is visually novel and form-education content is a durable fitness format (the 2026 hook guides use 'wrong movement then why' as the fitness example), and Reels ranks sends, which form content earns. Caveat: its opener (typing → forge) repeats Demo Short's, so post it third and make the first-frame text hook about the payoff, not the typing: 'Watch the hips on this deadlift.' Set the Reels cover to the orbit frame, not the typing. Sound: this one benefits most from a coach-style VO calling one cue on the orbit ('hips back, bar close, that's the hinge'); keep a low techno bed ('Muscle Drive' or 'Vibin' on TikTok, 'Work & Result' on Reels) and no foley clutter over the 3D. On Shorts consider running this one first if you want the visual-novelty click-through; keep post order 3 on TikTok and Reels. Recut opportunity later: open cold on the 3D orbit and show the typed ask as the reveal (result-first rewind), which is what this week's formats reward.

Sources: https://newengen.com/insights/instagram-trends/, https://socialbee.com/blog/instagram-trends/, https://www.ramd.am/blog/trends-tiktok, https://www.ramd.am/blog/trends-instagram, https://newengen.com/insights/september-tiktok-trends/, https://www.pepperagency.com/blog/tiktok-instagram-trends-for-september-2026-and-how-brands-can-actually-use-them, https://napoleoncat.com/blog/tiktok-trends/, https://blog.mean.ceo/social-media-trends-september-2026/, https://buffer.com/resources/trending-songs-tiktok/, https://www.socialpilot.co/blog/instagram-reels-trends

## Automation pipeline, upgraded (Sep 13, 2026)

Source: the YouTube walkthrough "How Claude + Higgsfield Automate 90% Of My Social Media Content" (Skai Generated, 2026-05-25). Transcript pulled and read in full. What it actually shows: Claude as a strategist inside a claude.ai Project (a weekly "master prompt" that web-searches 3–5 competitor channels for outlier posts and returns 7 blueprints — topic, format, hook, script, caption, hashtags, a paste-ready visual prompt), then prompts hand-pasted into Higgsfield Canvas node templates (GPT Image 2 carousels ~12 credits/slide; Seedance 2.0 talking heads ~360 credits/segment; Flux-still → Kling-motion B-roll ~6,000 credits per 8 shots), then CapCut, then manual posting. Nothing in it calls Higgsfield from Claude — our MCP connector, ffmpeg cutting, and staged posting are already a step ahead of the video on automation. Sources: https://www.youtube.com/watch?v=jkvh-bQJVAk (watch page HTML: metadata, description; auto-captions via yt-dlp), https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=jkvh-bQJVAk&format=json (title/author), https://docs.google.com/document/d/1rf2v7UNbLGm9RF0_5MOPMLjARYdt-nmEIeIDPz8tt-I/edit?usp=sharing (Skai Generated Prompt Pack, linked in description)

**Adopted into our pipeline:**

- **0. Ground truth before spending anything: read the live Higgsfield balance and transaction log, and the existing generation history** — Higgsfield MCP: balance, transactions, show_generations (all read-only) · *Claude* — Checked 2026-09-13: balance is 6 credits on the FREE plan, not ~10. One 4-credit Veo 3.1 Lite job ran at 13:51 UTC today and is COMPLETED: job ccc0e8f3-f671-4f3e-b212-843228548e2e, 4.0 s, 9:16, 720x1280 h264 24 fps, silent, 1.08 MB, prompt = loaded barbell on a black rubber garage-gym floor at golden hour, chalk dust, phone face-up glowing, no people/text/logos. Raw URL: https://d8j0ntlcm91z4.cloudfront.net/user_3JH8Pa8voBTlcNtMRgWNDJupjt2/hf_20260913_135150_ccc0e8f3-f671-4f3e-b212-843228548e2e.mp4 . That clip IS the Reel 1 hook; Reel 1 costs 0 more credits. Real prices preflighted with get_cost (9:16): Veo 3.1 Lite 4 s silent = 4, 6 s = 6; Kling 3.0 Turbo 5 s 720p = 7.5; Kling 3.0 std 5 s sound off = 7.5; Happy Horse 4 s = 10; Seedance 2.0 Mini 5 s silent = 12.5. Update MARKETING.md's budget math (it says ~5 credits basic, ~15 per finished clip): the affordable unit is Veo 3.1 Lite 4 s at 4 credits, so 6 credits = exactly one retry.
- **1. Trend check at production time (standing rule; already done for the week of Sep 12)** — Claude web search + MARKETING.md 'Trend check at production time' section · *Claude drafts, owner reads* — Adopt from the video: run it as a fixed 'master prompt' with an explicit outlier scan of 3-5 named accounts (posts far above that account's median views), extract hook/format only, never topics. Keep the Fatcamp rule that the snapshot is dated and re-done every batch. Add a 5-line competitor list to MARKETING.md so the scan is repeatable (local coaches/gym owners 1k-20k from OUTREACH.md, plus 2 app-demo accounts).
- **2. Weekly blueprint set (the video's 7-blueprint output, cut to Fatcamp's 4-5/week cadence)** — Claude Code writing a dated 'Week of' block into /Users/tannerfrancis/Desktop/Fatcamp/fatcamp/MARKETING.md · *Claude drafts, owner edits/picks* — Per post: Topic; Format = [App capture | AI hook + capture | Receipt carousel | Founder phone clip]; Hook (<=10 words, dry, a receipt not a claim); Script or capture ask-line (e.g. 'bad shoulder, 40 min, dumbbells only'); Caption in brand voice + soft CTA; 5-8 hashtags (search phrases over hashtag stacks); Higgsfield prompt ONLY for the AI-hook format, using the prompt_template below; credit estimate from step 0 prices. The Sep 12 'Posting order and captions' block already is this for posts 1-3; keep that shape.
- **3. Zero-cost app captures (the proof)** — Existing recording rig (real app, iPhone/simulator screen recording) -> /Users/tannerfrancis/Desktop/Fatcamp/Marketing/*.mp4 at 1080x1920 30 fps silent · *Owner records (or Claude drives the web app), Claude QA* — Unchanged. Measured this session: Before After 20.73 s, Demo Short v1 32.27 s, Coached in 3D 23.87 s, all 1080x1920 30 fps, no audio track. QA locally with AVFoundation (scratchpad frames.swift extracts frames at given times; no ffmpeg on this Mac, but `swift` works) to confirm UI sits in the middle ~1470 px and typing is readable.
- **4. AI hook generation (the reach), one clip per week at most while on 6 credits** — Higgsfield MCP: models_explore -> generate_video with get_cost:true -> owner go -> generate_video veo3_1_lite, aspect_ratio 9:16, duration 4, generate_audio false, count 1 · *Claude preflights and reports cost, OWNER says go per generation, Claude runs it* — Hard rule: never call generate_* without get_cost first and an explicit yes for that exact cost; report balance before/after. Skip this week: the hook already exists (step 0). Once on a paid plan, adopt the video's 'batch and pick best' as count 2, never 4. Free-plan outputs may carry a Higgsfield watermark: I checked the bottom quarter of the existing clip at 3.9 s at thumbnail size and saw none, but the owner must eyeball the full-res file before it ships.
- **5. Stitch and title (the CapCut step in the video, done with ffmpeg instead)** — Higgsfield MCP sandbox_exec (cloud Linux with ffmpeg/ffprobe, ImageMagick, sox, Montserrat/Metropolis fonts, faster-whisper); media_upload presigned PUT + media_confirm. Fallback: `conda create -p ~/ffenv -c conda-forge ffmpeg` (never under ~/Desktop) · *Claude* — Flow: (a) media_upload {filename:'ba.mp4'} -> run the returned curl PUT from local Bash against the local capture (4.9 MB) -> media_confirm type video; (b) in one sandbox_exec command: curl the Veo raw URL + the confirmed capture URL, run the ffmpeg in first_reel_recipe, then PUT the result to a second media_upload URL inside the same command (sandbox is discarded ~10 s after the call), then media_confirm. Result is Higgsfield-hosted, which is what tiktok_prepare_publish requires, and the owner downloads the same file for native IG Reels / Shorts uploads (no TikTok watermark on Reels).
- **6. Sound and captions** — Owner: iPhone Voice Memos (this Mac has no audio input device). Claude: sandbox ffmpeg mux + Higgsfield 'subtitles' workflow (get_workflow_instructions 'subtitles', faster-whisper) for burned word-level captions · *Owner records the one-line VO, Claude muxes and captions* — Original audio beats licensed music this week (business accounts are locked out of most licensed tracks on Reels; 75-85% of TikTok viewing is muted). VO line for Reel 1: 'Fifteen seconds of typing. That's the workout.' If no VO is recorded, ship silent with burned text and let the owner add a native sound at post time; on TikTok via the API, tiktok_music_trending (Commercial Music Library, DIRECT_POST only) at music_sound_volume ~25.
- **7. QA gate** — Claude: frames.swift / sandbox ffprobe; owner: preview the Higgsfield-hosted URL on a phone · *Claude checks, owner approves* — Checklist: 1080x1920, 30 fps (TikTok needs 23-60), first frame has the text hook, hook inside y 700-1300, no AI-generated UI anywhere, no watermark, total 15-30 s, the app screen appears by second 3, ?p= link matches the platform. Optional: virality_predictor on the confirmed upload; I did not verify whether it costs credits, so preflight or skip.
- **8. Publish, one platform at a time, nothing without the owner's go** — TikTok: tiktok_connect (owner clicks the OAuth authorize_url, expires ~10 min) -> tiktok_accounts -> tiktok_prepare_publish (video_url = Higgsfield-hosted, mode UPLOAD_TO_DRAFT recommended) -> owner reviews -> tiktok_publish with is_aigc true and every required confirmation. Instagram Reels + Shorts: owner uploads the downloaded MP4 natively in the Fatcamp Chrome profile · *Owner authorizes and gives the go; Claude stages and reports publish_id* — No TikTok account is connected today (tiktok_accounts returned empty). Draft mode keeps the owner's hand on the post and lets him add a native sound in the TikTok editor; DIRECT_POST only if he says so, privacy PUBLIC_TO_EVERYONE stated explicitly. Quotas: 5/min, 13/day. Captions and hashtags come from MARKETING.md's 'Posting order and captions' (post 1 = Before After). Disclose AI on TikTok (is_aigc) because the hook is generated; Reels has an equivalent 'AI info' label. Bio links: ?p=tt TikTok, ?p=ig Instagram, ?p=yt in the Shorts channel About.
- **9. Measure and write back** — Supabase events (app_open/forge by ?p= source) + platform insights -> a dated line in MARKETING.md · *Claude* — Friday: scans/opens per ?p= code, opens -> forged session, day-2/day-7 return; plus per-post 3-second hold and completion rate. Whichever of 'AI hook + capture' vs 'capture only' wins on forge conversion decides whether a paid Higgsfield plan is worth it. Do not buy a plan on the video's math.

**Reel 1 recipe (as produced):** REEL 1 = the existing Veo 3.1 Lite barbell hook (0 new credits) + 'Fatcamp Day1 - Before After.mp4' (post #1 in MARKETING.md). Budget: 6 credits on hand; hold them as the single allowed retry (Veo 3.1 Lite 4 s 9:16 silent = 4 credits, verified with get_cost). Do NOT generate anything unless the owner rejects the existing clip after viewing it at full resolution.

WHAT TO GENERATE (only if the retry is needed): model veo3_1_lite, aspect_ratio 9:16, duration 4, generate_audio false, count 1. Prompt: "Vertical 9:16, low angle from the floor, handheld micro-shake. A loaded barbell rests on a black rubber home-garage gym floor, one warm shaft of window light across the plates, chalk dust drifting, a phone lying face-up beside the bar with its screen glowing. Slow push-in toward the phone over four seconds. Shallow depth of field, muted warm palette, a single red accent on the bar collar. Photoreal, quiet, no people, no faces, no hands, no text, no logos, no app interface." Negative (append if the model accepts it): people, faces, text, watermark, UI, neon, lens flare, fast camera moves.

STITCH ORDER AND DURATIONS (total 23.3 s, 1080x1920, 30 fps):
- 0.0-2.6 s: Veo clip, first 2.6 s (the push-in is still at rest, no settle frames), scaled 720x1280 -> 1080x1920 lanczos, 24 -> 30 fps. Text hook burned from 0.15 s.
- 2.6 s: hard cut to Before After frame 0 (the dark 'ANOTHER ONE DOWN' celebration matches the dark garage tone, so no dissolve).
- 2.6-23.3 s: Before After untouched. Its own timeline, measured: 0-3.3 celebration; 3.3-5.5 the ask screen with 'push day at home, 30' typed; 6-9 the PUSH card (35 min, 13 work sets, 100%, 236 pts); 9.5-13.3 dumbbell bench press sets logged 1/13 -> 3/13 (CLAIM 15 -> 45 PTS); 13.5-18.5 bank celebration; 18.5-20.7 home screen with the BANKED +131 banner (streak 1). So the app is on screen 2.6 s into the reel, the typing appears at 5.9 s (the rewind), and the receipt lands at 21.5 s.
Alternative pairing for Reel 2 with the same hook: Demo Short v1 trimmed to start at 12.0 s (its splash/tour runs 0-12.0 s, which is the throat-clearing the trend notes flag), giving 2.6 + 20.3 = 22.9 s ending on the NO ACCOUNT. NO EMAIL. JUST A WORKOUT card.

ON-SCREEN TEXT: frame one, centered, y = 940 px (inside the 700-1300 safe band), Montserrat ExtraBold 64 px as the sandbox stand-in for Avenir Next 800, paper #EFEDE7 with a soft black shadow, visible 0.15-2.6 s: "This workout took 15 seconds to write." Second line at 18.6-20.7 s, y = 1260 px, 48 px: "No account. No email. Just a workout." Everything else comes from the app's own screens (ANOTHER ONE DOWN, WHAT ARE YOU TRAINING TODAY?, BANKED +131), which is the point.

FFMPEG (run inside sandbox_exec after curl'ing veo.mp4 and the confirmed capture as ba.mp4; F = path from `fc-list | grep -i Montserrat-ExtraBold | head -1 | cut -d: -f1`):
ffmpeg -y -i veo.mp4 -i ba.mp4 -filter_complex "[0:v]trim=0:2.6,setpts=PTS-STARTPTS,scale=1080:1920:flags=lanczos,fps=30,format=yuv420p,drawtext=fontfile=$F:text='This workout took 15 seconds to write.':fontcolor=0xEFEDE7:fontsize=64:x=(w-text_w)/2:y=940:shadowcolor=black@0.6:shadowy=3:enable='between(t,0.15,2.6)'[a];[1:v]fps=30,format=yuv420p,drawtext=fontfile=$F:text='No account. No email. Just a workout.':fontcolor=0xEFEDE7:fontsize=48:x=(w-text_w)/2:y=1260:shadowcolor=black@0.6:shadowy=3:enable='between(t,18.6,20.8)'[b];[a][b]concat=n=2:v=1:a=0[v]" -map "[v]" -c:v libx264 -preset medium -crf 18 -r 30 -pix_fmt yuv420p -movflags +faststart reel1_silent.mp4
Then, in the SAME command, `curl -f -X PUT --upload-file reel1_silent.mp4 '<upload_url from media_upload>'`, and media_confirm afterwards. If the owner records the VO (iPhone Voice Memos, AirDrop or upload as vo.m4a): add `-i vo.m4a` and `-filter_complex "...;[2:a]adelay=300|300,volume=1.0[aud]" -map "[aud]" -c:a aac -b:a 160k -shortest`, then run the Higgsfield 'subtitles' workflow to burn word-level captions from that audio. Local fallback if the sandbox is unavailable: the same command in a conda-forge ffmpeg env created outside ~/Desktop.

SOUND: original audio is the target this week (business-safe, favoured by both platforms). VO, dry coach, one breath, no music sting: "Fifteen seconds of typing. That's the workout." timed to start at 0.3 s so it finishes as the celebration lands. If no VO: ship silent with the burned text and add sound natively at post time; on TikTok pick a low-key bed from tiktok_music_trending (or 'Muscle Drive' in-app) at volume ~25 under the burned captions; on Reels use the 'Work & Result' original-sound bed only if the account can access it, otherwise silence plus captions. Reels cover = the ANOTHER ONE DOWN frame at 2.6 s. Disclose AI (is_aigc true) since the first 2.6 s are generated.

**Prompt template for AI clips (Fatcamp voice):**

```
FATCAMP AI-CLIP PROMPT TEMPLATE (for the 'AI hook + capture' format; the AI clip is garnish for a real app capture, never the product)

Settings block (fill before writing the prompt): model = veo3_1_lite (4 credits / 4 s, the only unit affordable at 6 credits; kling3_0_turbo 7.5 credits when on a plan) | aspect 9:16 | duration 4 (6 max) | audio OFF (sound is added at post time) | count 1 (2 when on a plan) | get_cost first, owner go, then generate.

Prompt (one paragraph, in this order):
1. Frame: "Vertical 9:16, [low angle from the floor | eye level | over-the-shoulder on a rack], [static | handheld micro-shake | slow push-in over four seconds]."
2. World (fixed for every clip, this is the consistency trick without paying for reference images): "a home garage gym: black rubber floor, one warm shaft of window light, chalk dust in the air, plain steel rack, a single red accent on the bar collar, muted warm palette, photoreal, quiet."
3. Subject and the one motion: "[a loaded barbell at rest | a pair of dumbbells on a bench | an empty rack with a towel over it | a phone face-up on the floor, screen glowing] and exactly one thing moving: [chalk drifting | the light shifting | a plate settling | nothing but the camera]."
4. Story beat (what the cut into the app will pay off): "the moment before the workout exists" / "the moment after the last set".
5. Always end with: "No people, no faces, no hands, no text, no logos, no app interface, no neon, no lens flare, no fast camera moves."
Negative list if the model takes one: people, faces, hands, text, watermark, UI, screen content, neon, flare, warping.
If animating a still (image-to-video), keep the scene in the still and give the model a motion-only line, e.g. "Slow push-in toward the phone; chalk drifts left to right; nothing else moves." (the video's two-prompt rule, adopted).

Hook line to burn over frame one (the dry coach, 6-10 words, a receipt not a promise, no exclamation marks, no 'AI'): pattern = "[concrete number or fact]. [what it cost]." Examples: "This workout took 15 seconds to write." / "Thirteen sets. Typed, not planned." / "No account. The session still got banked." / "Everyone's picking plans. Someone just typed 'push day'."
VO line (one breath, same voice): "[The fact]. That's the workout." Never say 'crush', 'unlock', 'game-changer', or 'AI-powered'.
Then cut to a real capture by second 3 at the latest.
```

**Weekly ritual:** MONDAY, 45 minutes, in this order.
1. Balance first (Claude, read-only): Higgsfield balance + transactions + show_generations, and Supabase ?p= numbers from last week. Decide the credit ceiling for the week out loud (today: 6 credits = one retry, zero planned spends).
2. Trend check at production time (standing rule, Claude with web search, 10 minutes per platform's fitness/app feeds + trending-audio charts, plus the outlier scan of the 3-5 listed accounts): date it, write it into MARKETING.md, pick ONE format to ride. Never reuse last week's snapshot.
3. Blueprints (Claude drafts, owner picks): 4-5 posts, each with topic / format / hook / script or ask-line / caption / hashtags / Higgsfield prompt (AI-hook format only) / credit cost. Mix = 2-3 zero-cost captures with new ask lines, 1 AI hook + capture at most, 1 founder phone clip when Tanner has one.
4. Capture (owner, 15 minutes): record the 2-3 app sessions; Claude QAs frames and safe zones.
5. AI hook (only if a blueprint needs one AND credits allow): get_cost, owner go, generate once, retry once at most.
6. Stitch + captions (Claude in the sandbox), VO from the owner's phone if he has one, upload to Higgsfield, owner previews on a phone.
TUESDAY-FRIDAY: post one per day on TikTok (drafts staged by Claude, owner adds sound and hits post, or gives the go for DIRECT_POST), 3 per week on Reels and 2 on Shorts uploaded natively from the same files, staggered by a few hours, same order on every platform. Nothing posts without the owner's explicit go.
FRIDAY, 10 minutes: Claude writes the scoreboard line into MARKETING.md: per-post 3-second hold, completion, sends/saves, and per-?p= opens and forge conversions. Rule for the AI budget: if 'AI hook + capture' does not beat 'capture only' on forge conversion within two weeks, stop spending credits and keep the free stream only; if it does, that is the evidence for a paid plan, not the video's $50/month math.

**Deliberately not adopted:** 1. Talking-head avatars (the video's Template B, Seedance 2.0 with generated audio, ~360 credits per segment, ~1,800 per post). Unaffordable on 6 credits and off-brand: Fatcamp's voice is a dry coach with receipts, and this week's snapshot says raw founder-voice proof beats gloss. A synthetic person reading a script is the opposite of 'honest > impressive'. When a face is wanted, it is Tanner on his phone, unscripted (the 'founder visibility' format already in MARKETING.md).
2. Soul ID / Soul 2.0 digital twin (uploading 20 photos of Tanner). Same brand reason plus privacy; a real 20-second phone clip costs nothing.
3. The 8-shot cinematic B-roll pipeline (Template C: Flux 2 Max stills + Kling 3.0, two reference images, ~6,000 credits per post). The AI is garnish here; the app capture is the product and the proof. Also, the video's reference-image trick exists to keep an AI character consistent across shots; Fatcamp has no AI character, so a fixed 'world' block in the prompt template gives enough consistency at zero cost.
4. GPT Image 2 carousels at ~12 credits per slide. The poster pipeline (HTML to PNG/PDF in /Users/tannerfrancis/Desktop/Fatcamp/Marketing/Posters, brand paper #EFEDE7, ink #1B1A19, accent #D8382B, Avenir Next 800) already renders text-on-image slides perfectly, with the real font, for free. A 'receipts' carousel (bank screen, streak, PRs) should be real screenshots plus that template, not a diffusion model rendering fake numbers.
5. A separate claude.ai 'Content Machine' Project with copy-paste into Higgsfield Canvas. Claude Code here already has the MCP connector, the marketing file, the analytics, the captures and a shell; splitting the brain into a Project and pasting prompts by hand adds a second source of truth and no capability. MARKETING.md stays the single working source (the .docx in Marketing/ is regenerated from it).
6. Seven blueprints a week and 'batch 4, pick the best'. Cadence is already set at 4-5 posts per week, the September roundups say 2-6 high-signal posts beat forced volume, and batch-4 multiplies every credit spend by four. Use count 1, retry once, and only when on a plan move to count 2.
7. CapCut as a required finishing step. ffmpeg in the Higgsfield sandbox does the trim, concat, titles and mux, the platforms' native editors add sound, and the faster-whisper subtitles workflow burns captions. Tanner can still use CapCut if he prefers; it is not part of the pipeline.
8. The video's cost and 'automation' claims: 'Higgsfield $50/mo' vs 'from $39/mo' is affiliate copy, the per-plan credit allotment is unverified, MARKETING.md's own '~15 credits per basic clip' estimate is also off (measured today: 4 credits per Veo 3.1 Lite 4 s), and the '90% automated' framing ends where Fatcamp's rule begins: posting is manual and needs the owner's explicit go, and the TikTok connector still needs his one OAuth click. Decide on any paid plan only from the Friday ?p= numbers.
9. Copying competitor topics. The outlier scan is adopted for hook structure and format only, which is what the video's own prompt says; the topics stay Fatcamp's (typed ask -> forged session, no account, injury limits, streaks and standings).

**Produced Sep 13:** `Marketing/Reels/Fatcamp Reel 1 v2 - No plan for the gym tonight.mp4` (44s, captioned walkthrough: Veo 3.1 Lite hook 4 credits → typed ask → forged session → 3D bench demo + orbit → muscle map → log sets → bank → reminder end card). Raw hook kept alongside. Instagram profile live at instagram.com/fatcamp.ai (photo, bio; link must be added from the phone app). TikTok sign-up blocked by OTP risk-check — use Continue with Google.
