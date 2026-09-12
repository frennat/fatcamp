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
