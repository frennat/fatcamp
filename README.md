# Lifted.AI

An agent that builds your training session from three things: what equipment you
have, what you want to hit, and how much you've got in the tank. Then it shows
you how to do every movement, in 3D.

No dependencies, no build step, no accounts, no network. Install it to your home
screen and it works in a basement with no signal.

## What it does

**Presets, if you don't want to think.** Four plates — Easy Day (10 kg), Medium
Day (15 kg), Killer (25 kg), Cardio (20 kg). One tap fills in every criterion
below it. Change whatever you like afterwards, or just forge it.

**Home or public gym.** *Home* uses a kit you define once — the generator will
never prescribe a lift you can't load. *Public gym* opens up racks, cables,
machines and conditioning gear.

**Coverage-first generation.** You pick the compound lifts you want and the
muscle groups you care about; the generator fills the remaining slots by
greedily maximising *new* muscle coverage, keeping movement patterns balanced
and ordering the sheet the way you should actually train it — compounds first,
isolation later, core at the end. Every movement tells you why it earned its
slot, and the session shows you which muscle groups it missed.

**A 3D figure for every movement.** A real articulated skeleton, not a video:
drag to orbit it, snap to side / three-quarter / front, or set it spinning.
Equipment is drawn in 3D too, so a barbell is a bar with plates on both ends
rather than a line. Beside it, a muscle map shades what the movement works.

**Points and streaks.** Sets and effort earn points, coverage pays a bonus, and
a streak multiplier compounds it. Ranks go from Empty Bar to Cast Iron.
Training at least every other day keeps a streak alive, and every seventh day
banks a rest-day pass that will cover one longer gap.

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
| `M` / `GEO` | 19 muscle regions and the shapes that draw them on a front/back body |
| `ARCH` | 49 movement archetypes — two authored poses each, plus the equipment to draw |
| `solve()` | Re-solves every frame against one canonical skeleton, so joint *angles* come from the pose and limb *lengths* never do |
| `pose3()` | Extrudes a solved 2D pose into 3D — sagittal archetypes gain left/right depth, frontal ones mirror in place |
| `makeRig()` | Canvas renderer: orbit camera, perspective projection, painter's-algorithm depth sort, depth-shaded capsule bones |
| `X` | The exercise library — muscles worked, equipment needed, movement pattern, coaching cue |
| `generate()` | The session builder: seeded compounds, greedy coverage fill, pattern balance, prescription |
| `parseEquipment()` | Free-text and pasted-list equipment matching |
| `scoreSession()` / `bumpStreak()` | Points, ranks, streaks and rest-day passes |
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
accent badge, cards with one corner blown out to 48px, layered soft shadows,
and a hero built from perspective-transformed cards floating in 3D. A
handwritten face appears once or twice as an aside, as it does in the template.

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
