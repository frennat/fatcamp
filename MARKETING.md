# Getting the first hundred people to use Lifted.AI

Written for a standing start: no social, no ad budget, no press. Posters,
stickers, and people telling other people.

---

## The thing to fix before printing anything

**Right now a QR code has nowhere good to send someone.** The app is in
TestFlight, and TestFlight is a wall: a public link needs Beta App Review, and
without one you are adding testers by Apple ID one at a time. Nobody scanning a
poster in a coffee shop is going to do that.

But `frennat.github.io/lifted-ai/` already works. It opens instantly in Safari,
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

Give each location its own URL: `frennat.github.io/lifted-ai/?p=spot-coffee`,
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
