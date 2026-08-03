# Lifted.AI

An agent that builds your training session from three things: what equipment you
have, what you want to hit, and how much you've got in the tank. Then it shows
you how to do every movement, in 3D.

No dependencies, no build step, no bundler. Install it to your home screen and
it trains you in a basement with no signal. Signing in is optional and only ever
adds a leaderboard — the generator, the 3D body and your whole log work offline
exactly as before.

## What it does

**Just say it.** The box at the top takes the request the way you'd say it out
loud — *"push day at home, six movements, go hard"*, *"45 minutes of legs and a
steady state run"*, *"killer leg day with back squats and RDLs"*. It reads the
location, the muscle groups, the movement count, the effort, the conditioning
and any lifts you name by name, fills in the whole Workload panel, and forges
the session in one press. Each ask is a complete request rather than an edit of
the last one, so yesterday's bench press cannot turn up in today's leg day.
Anything it doesn't recognise it leaves alone. Behind the box a shape turns
slowly through the gym and back again — dumbbell, kettlebell, barbell, medicine
ball, a flexing arm, a bicycle, a treadmill, a bench, a rope, resistance bands
and a forge hammer.

**Presets, if you don't want to think.** Four plates — Easy Day (10 kg), Medium
Day (15 kg), Killer (25 kg), Cardio (20 kg). One tap fills in every criterion
below it. Change whatever you like afterwards, or just forge it. The card marks
the effort in bolts — one, two, three — in the plate colour that codes it
everywhere else; Cardio gets a runner on a treadmill instead.

**Home, public gym, or nothing at all.** *Home* uses a kit you define once — the
generator will never prescribe a lift you can't load. *Public gym* opens up
racks, cables, machines and conditioning gear. *Body Weight* strips it to you
and the floor: a hotel room, a park, ten minutes between things. Twenty-seven
movements need no equipment whatsoever, covering fourteen of the twenty-three
muscle regions. Lats and biceps are not among them — there is no honest way to
load a pull without something to hang from, so the mode says so on the panel
rather than inventing something.

**Coverage-first generation.** You pick the compound lifts you want and the
muscle groups you care about; the generator fills the remaining slots by
greedily maximising *new* muscle coverage, keeping movement patterns balanced
and ordering the sheet the way you should actually train it — compounds first,
isolation later, core at the end. Every movement tells you why it earned its
slot, and the session shows you which muscle groups it missed.

**A shaded 3D body for every movement.** Not a stick figure and not a video —
a procedural anatomical mesh whose every surface quad knows which muscle it
belongs to. Drag to orbit, snap to side / three-quarter / front, or set it
spinning. Equipment and surfaces are drawn in 3D too: floor, bench, rack, bars
with plates on both ends, bands anchored to the ground.

**The same body is the heat map.** Because each quad carries a muscle id,
colouring by activation turns the figure itself into the chart — rotate it to
see exactly what today's session lands on, front, back or side. No more
guessing from a flat silhouette.

**It notices what you skip.** The generator keeps a rolling read of the last
fortnight and builds up a debt for muscles that keep getting missed, then pays
it down in later sessions and tells you when it does.

**Personal bests.** Log a lift's load and reps from the session sheet or from
your profile, for the big lifts or any movement you name. Entries are ranked by
estimated 1RM (Epley) so a heavy triple and a set of ten can be compared, and
each lift gets its own chart over time — one lift at a time, because a deadlift
and a curl have no business sharing a y-axis.

**Failure mode.** Switch it on for the session and isolation and accessory work
drops its rep target — you go until the set stops. Compounds keep their numbers
on purpose. Per movement you can toggle it either way; when it's on the figure
runs the rep faster, trails behind itself, and the frame glows. Those sets are
worth more.

**Points, claimed as you go.** Finish a movement's sets and claim its points
right there — the balance moves while you're still in the gym. Whatever you
don't claim is settled when you bank the session, so the total is the same
either way and nothing pays twice.

**Streaks you can see.** The log keeps a calendar over a week, a month or the
last twelve months, each day coloured by how hard that session was. Ranks go
from Empty Bar to Cast Iron. Training at least every other day keeps a streak
alive, and every seventh day banks a rest-day pass that covers one longer gap.

**Build the week.** Pick a split — Push/Pull/Legs, Upper/Lower, Full Body ×3,
a body-part split, or set it day by day — and every session in it is generated
at once. The split is what gets saved; the movements are re-rolled each time
it's built, so the same routine keeps landing on different work. Planned days
show up on the streak calendar ahead of time, so opening the app tells you
what today is.

**Standings.** Points rank you rather than buy things. Your total, your week,
your best session and your streak multiplier, plus a breakdown of exactly where
points come from and which lever is worth the most right now. Sign in and you
join local, country and global leaderboards.

## Accounts and leaderboards

Optional, and additive. Signed out, the app is exactly what it was.

Sign-in lives in the profile, behind the avatar at the top of the page. There
is an emailed six-digit code, the link in that same email, or a password —
whichever suits. The same email carries both a
six-digit code and a link, and the app accepts either — type the code, or tap
the link and it returns you signed in (tokens are read from the URL fragment
and immediately scrubbed out of history).

**Supabase settings this depends on**, under Authentication:
- *URL Configuration* → add every origin you serve from to **Redirect URLs**
  (`http://localhost:8080/**`, and your Pages URL). The link in the email comes
  back to whichever origin asked for it, and an origin that is not on this list
  is refused.
- *Email Templates → Magic Link* → include `{{ .Token }}` if you want the code
  to appear. The stock template only has the link.
- The built-in mailer is rate limited to a couple of sends an hour, which is
  easy to trip while testing. *Authentication → Rate Limits* shows the current
  caps; wiring your own SMTP under *Project Settings → Auth → SMTP* removes the
  constraint.

**What leaves your device:** a handle, a coarse region, and per-session point
totals. **What never does:** your movements, loads, PRs, gym photo, or email.
That split is enforced by Postgres row-level security, not by the client:

| Table | Who can read it |
| --- | --- |
| `lifters` | only you |
| `sessions` | only you |
| `standings` | any signed-in user — handle, region and totals only |

`standings` has **no client write policy at all**. It is maintained by a trigger
that recomputes totals from `sessions`, so nobody can post a number they did not
earn. The publishable key in `index.html` is meant to be public; these policies
are the security boundary.

### Setting it up

1. Paste `supabase/schema.sql` into the Supabase SQL editor and run it once.
2. Run `supabase/verify.sh` — it uses only the public key and asserts that the
   tables exist and that an anonymous caller can read and write nothing.
3. Open the app, go to **Standings**, and sign in.

Sync is best-effort: it runs after you bank a session and on load, never blocks
the UI, and failures degrade to a quiet "Offline" note.

## Install it on your phone

Serve the folder over HTTPS — GitHub Pages is the easy way (Settings → Pages →
deploy from `main`, root) — then open the URL on your phone:

- **iOS**: Share → *Add to Home Screen*
- **Android**: the *Install app* prompt, or ⋮ → *Install app*

It installs as a standalone app with its own icon, no browser chrome, and a
service worker that precaches everything. After the first load it never needs
the network again.

To run it locally instead:

```bash
python3 -m http.server 8000
```

Opening `index.html` straight off disk works too, but service workers need
`http://` or `https://`, so you don't get offline install that way.

> **When you edit `index.html`, bump `CACHE` in `sw.js`.** Installed copies are
> served cache-first and will otherwise keep showing the old version for a load.

## Profiles

Progress belongs to a profile, and profiles live on the device. There is no
server behind this app — that is what lets it run with no signal — so it can't
offer a login that syncs by itself. Moving a profile to another device is an
explicit, one-time act:

- **Transfer code** — a `LIFTED-…` string you copy and paste into the app on
  the other device. Carries progress, streak, history and kit; not the gym photo.
- **Backup file** — a `.json` you can keep. Carries everything.

On import you choose to merge into the current profile (keeps the best of both,
de-duplicates sessions) or add it as a separate one. Multiple profiles on one
device work fine — useful if someone else lifts in the same room.

## The home gym editor

Three ways to tell it what you own, all in the same sheet:

1. **Tap the chips** for anything in the library.
2. **Type or paste a list.** It understands commas, bullets, numbered lists and
   prose, plus the names people actually use — "power cage", "dumbells",
   "concept 2", "peloton", "hex bar", "parallettes". Anything it doesn't
   recognise is kept on your list rather than dropped.
3. **Keep a photo of your gym** as a reference to tick things off against.

On the photo: the app runs entirely on your device with no network, so it
cannot analyse the image itself. What it does instead is give you a prepared
prompt — hand the photo and the prompt to Claude, then paste the reply into the
text box, which parses it. Fully automatic detection would need either a
backend or an API key living in the browser; see *Where this is going*.

## How it's built

`index.html` is the whole program. `manifest.json`, `sw.js` and `icons/` exist
only to make it installable.

| Part | What it does |
| --- | --- |
| `M` | 23 muscle regions |
| `LIMBS` / `MUSCLE_AT` | The body mesh: lofted tubes with radius profiles, and the rule that decides which muscle owns a surface point from its position along the bone and angle around it |
| `buildMesh()` / `skinMesh()` | Mesh topology is built once and shared by every rig; each frame only skins vertices and projects each one once, then paints faces back-to-front batching runs of like colour. ~6ms a frame, so it holds 60fps |
| `muscleDebt()` | Rolling read of what recent sessions neglected, fed back into generation |
| `ARCH` | 49 movement archetypes — two authored poses each, plus the equipment to draw |
| `solve()` | Re-solves every frame against one canonical skeleton, so joint *angles* come from the pose and limb *lengths* never do |
| `pose3()` | Extrudes a solved 2D pose into 3D — sagittal archetypes gain left/right depth, frontal ones mirror in place |
| `makeRig()` | Canvas renderer: orbit camera, perspective projection, painter's-algorithm depth sort, depth-shaded capsule bones |
| `X` | The exercise library — muscles worked, equipment needed, movement pattern, coaching cue |
| `generate()` | The session builder: seeded compounds, greedy coverage fill, pattern balance, prescription. On a focused day only movements that mostly train the focus are eligible, so a chest day stays a chest day |
| `parseEquipment()` | Free-text and pasted-list equipment matching |
| `movePoints()` / `scoreSession()` | Per-movement claims and the session settlement that nets them off |
| `epley()` / `prChart()` | Personal bests, estimated 1RM, and the per-lift chart |
| `bumpStreak()` / `trainingDays()` | Streak rules, rest-day passes, and the calendar behind them |
| profile vault | Multiple profiles, v1→v2 migration, transfer codes, backup files |

Exercises reference archetypes rather than owning poses, so adding a lift is a
few lines in `X` — and the implement drawn in the figure's hands comes from the
*exercise's* equipment, not the archetype, which is why a bodyweight calf raise
holds nothing and a loaded one holds dumbbells.

### Adding an exercise

```js
{id:"zercher", n:"Zercher Squat", arch:"frontsquat", eq:["barbell","rack"],
 cls:"comp", pat:"squat", big:1,
 pri:["quads","glutes"], sec:["abs","upperback"],
 cue:"Bar in the crooks of your elbows. Brutal, and it will teach you to stay upright."}
```

`cls` picks the set-and-rep scheme (`comp` / `acc` / `iso` / `core` / `cardio`),
`pat` keeps the session from stacking three horizontal presses in a row, and
`big:1` puts it in the compound picker.

## Design

The layout and typography follow the [SkiLens](https://skilens.framer.website/)
Framer template: wide geometric display type set uppercase with tight negative
tracking, corner-bracket eyebrow labels, 80px pill buttons with a circular
accent badge, cards with one corner blown out to 48px and layered soft shadows.
The top of the page is a single question over a frosted, translucent pane —
Apple's liquid glass, more or less — with a slowly morphing form glowing
behind it, in the manner of [dough.do](https://dough.do). That form is a rig of
eight slots, each a lathe with its own place and tilt and a cross-section that
can be squared off; a shape fills in the slots it needs and leaves the rest
empty. The slot count never changes, so turning a bicycle into a bench is still
a lerp, and a slot the next shape does not use borrows its partner's position
so parts grow where they belong instead of flying out of the middle. A handwritten face
appears once or twice as an aside, as it does in the template.

The forge button is the mark itself: a lightning bolt crossing a knurled
dumbbell on a hot disc, with no chrome around it. It sits in the ask box, in the Workload panel
next to the words *Forge the session*, and — once both have scrolled away —
floating in the corner, so the session is always one press away. Hovering the
Workload bar runs a row of chevrons across its empty middle, lighting in
sequence toward the mark; the floating one carries a single chevron that
breathes while it is up.

The palette stays the IWF competition plate colours, used as an actual coding
system rather than decoration — red 25 kg for Killer, blue 20 kg for Cardio,
yellow 15 kg for Medium, green 10 kg for Easy. Red carries the brand because
that is what the mark is built from; the template's acid lime would have fought
it. Every number is set in a monospace face so sets, reps, points and timers
stay in tabular columns. Both light and dark themes are first-class; the toggle
overrides your system preference.

### The mark

A hexagon frame with circuit traces and a flexed arm, drawn as vector so it
holds from a 16px favicon to a 512px store icon. `logoMark(size)` renders it
inline and drops the hairline detail below 40px; the same paths generate
`icons/` and the favicon, so there is one source for the identity.

## Plans

Thirty days of everything, free, counted from the first time the app is opened.
After that:

| | Pro — $10/mo | Max — $20/mo |
| --- | --- | --- |
| Sessions per week | unlimited | unlimited |
| Build-the-week training days | 4 | 7 |
| Saved splits | 1 | unlimited |
| Movements per session | 10 | 20 |
| 3D rig, heat map, PRs, streaks, rewards | yes | yes |
| Failure mode | — | yes |
| Surprise Me | — | yes |
| Adaptive catch-up targeting | — | yes |
| Profiles on one device | 1 | unlimited |

Sessions are deliberately **unlimited on both tiers**. Metering how often
somebody trains is the one limit that would make the app worse at its job; the
paid line is drawn at depth and automation instead.

Billing is not wired up — there is no payment code in this build. Choosing a
plan applies its limits so each tier can be lived with before a store release.
Enforcement is client-side and trivially bypassed, which is fine for a personal
build; a real release needs StoreKit or Play Billing to validate the purchase.

## Where this is going

1. **Store builds.** Capacitor or Tauri will wrap this for the App Store or
   Play Store with very little change, since there's no server to move.
2. **Photo analysis without a courier.** Two honest routes: a small backend
   that holds the API key and does the vision call, or an opt-in setting where
   you paste your own Anthropic key. The second keeps the zero-backend property
   but puts a real credential in browser storage, which is a genuine tradeoff
   rather than a free win.
3. **Split the source.** Once it's a store app, break `index.html` into modules
   and move the exercise library into JSON so it can be edited without touching
   code.

## Not medical advice

Warm up. Leave a rep in the tank when the prescription says so. If something
hurts in a way that isn't muscular, stop and talk to someone qualified.
