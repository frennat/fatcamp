# Lifted.AI

An agent that builds your training session from three things: what equipment you
have, what you want to hit, and how much you've got in the tank. It then shows
you how to do every movement.

One file. No dependencies, no build step, no network. Open `index.html` and it
works — on a laptop, on a phone, in a basement with no signal.

## What it does

**Presets, if you don't want to think.** Four plates — Easy Day (10 kg), Medium
Day (15 kg), Killer (25 kg), Cardio (20 kg). One tap fills in every criterion
below it. Change whatever you like afterwards, or just forge it.

**Two places to lift.** *Basement* uses a stored kit you can edit — the
generator will never prescribe a lift you can't load. *Public gym* opens up
racks, cables, machines and conditioning gear.

**Coverage-first generation.** You pick the compound lifts you want and the
muscle groups you care about; the generator fills the remaining slots by
greedily maximising *new* muscle coverage, while keeping movement patterns
balanced and ordering the sheet the way you should actually train it —
compounds first, isolation later, core at the end. Every movement tells you why
it earned its slot.

**An animated figure for every movement.** Not a photo, not a video — a jointed
rig that performs the actual rep, with the equipment drawn in. Play, pause, and
scrub the speed. Beside it, a muscle map shades what the movement works, primary
and secondary.

**Points and streaks.** Sets and effort earn points, coverage pays a bonus, and
a streak multiplier compounds it. Ranks go from Empty Bar to Cast Iron.
Training at least every other day keeps a streak alive, and every seventh day
banks a rest-day pass that will cover a longer gap once.

## Run it

Open the file. That's it.

```bash
open index.html
```

To use it on a phone, either serve the folder over your local network:

```bash
python3 -m http.server 8000
```

…or turn on GitHub Pages for this repo (Settings → Pages → deploy from `main`,
root) and load the URL. On iOS, *Share → Add to Home Screen* installs it as a
standalone app with its own icon — it already carries the meta tags for that.

All progress lives in `localStorage` on the device. Nothing is uploaded, and
there is no account.

## How it's built

`index.html` is the whole program. Inside it:

| Part | What it does |
| --- | --- |
| `M` / `GEO` | 19 muscle regions and the shapes that draw them on a front/back body |
| `ARCH` | 48 movement archetypes — two authored poses each, plus the equipment to draw |
| `solve()` | Re-solves every frame against one canonical skeleton, so joint *angles* come from the pose and limb *lengths* never do |
| `fitFor()` | Measures a whole rep and shrinks only the poses that don't fit the frame |
| `X` | The exercise library — muscles worked, equipment needed, movement pattern, coaching cue |
| `generate()` | The session builder: seeded compounds, greedy coverage fill, pattern balance, prescription |
| `scoreSession()` / `bumpStreak()` | Points, ranks, streaks and rest-day passes |

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

The palette is the IWF competition plate colours used as an actual coding
system rather than decoration — red 25 kg for Killer, blue 20 kg for Cardio,
yellow 15 kg for Medium, green 10 kg for Easy. Type is Avenir Next Condensed
for display, Avenir Next for text, and a monospace face for every number, so
sets, reps, points and timers stay in tabular columns. Both light and dark
themes are first-class; the toggle overrides your system preference.

## Where this is going

The single-file build is deliberate — it makes the thing portable and hard to
break. Turning it into a real app means:

1. **Home-screen install** — works today via Add to Home Screen. A service
   worker and a `manifest.json` would make it fully offline-installable.
2. **Wrap it** — Capacitor or Tauri will take this file to the App Store or
   Play Store with very little change, since there's no server to move.
3. **Split the source** — once it's an app, break `index.html` into modules and
   move the exercise library into JSON so it can be edited without touching code.

## Not medical advice

Warm up. Leave a rep in the tank when the prescription says so. If something
hurts in a way that isn't muscular, stop and talk to someone qualified.
