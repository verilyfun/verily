# Verily brand guide

Verily is a field notebook that gets stamped when you do the thing. The brand
should feel hand-drawn, warm, and a little funny, and it should always be
honest about what proof can and cannot show.

Everything visual in this guide is drawn from one source of geometry,
[`packages/verily_brand/lib/src/geometry.dart`](../packages/verily_brand/lib/src/geometry.dart).
The app's widgets, the launch reel, and the files in [`brand/`](../brand/README.md)
all read it.

## The name

**Verily** is an old English word for _truly_, _certainly_. It is what you
say when you mean it. That is the promise of the product: an action that
says it happened, and can show that it was done.

Write it **Verily** in running text (capital V, never VERILY or verily.io).
The wordmark is the only place it is written ✓erily.

## Tagline and voice

**Do it. Prove it. Get paid.**

Three short verbs, in the order they happen. Keep the full stops; they are
the beats.

The voice is **playful, honest, and plain**:

- **Plain words.** "Pin a real place." "Lock the reward first." Not
  "geofenced proof-of-presence".
- **Outcomes, not machinery.** Say what happened and what to do next. Never
  name models, scores, providers, storage, or chains in normal copy.
- **Honest about proof.** Verily can say a clip was _filmed live in Verily_,
  _signed by this phone_, _inside the place_, and _checked_. It never says a
  scene is "real", "authentic", or "fake-proof", and it never calls an account
  a unique person.
- **Warm, a little funny.** Dares, squats, pigeons, pelicans. Never
  surveillance, never pressure, never a task queue.

| Say                         | Don't say                         |
| --------------------------- | --------------------------------- |
| Filmed live in Verily.      | 100% real footage.                |
| Checked by Verily.          | Verified by AI.                   |
| The reward is in escrow.    | Guaranteed earnings.              |
| Someone will look at this.  | Your submission was flagged.      |
| Nobody works for a promise. | Earn crypto for completing tasks. |

## The mark: the pin-check

![The pin-check](../brand/verily-mark.svg)

A solid **map pin** with a **check** knocked out of its head: _verified,
here_.

The check's short arm sits inside the head and its long arm rises up and to
the right, straight through the pin's rim, cutting it open. After a small
gap, the same line carries on outside the pin as a short vermilion flick: a
confident tick that overshoots the pin. The check is cut, not drawn: it is
transparent, so whatever the mark sits on (paper, night, a photo, the app
icon's vermilion) shows through it.

Construction, on a 512 × 512 artboard (y runs down):

```text
Pin (filled, vermilion)
M 240 486
C 240 486 90 330.56 90 218        up the left flank to the head's widest
C 90 135.15 157.15 68 240 68      round the head's left side to the top
C 322.85 68 390 135.15 390 218    round the head's right side
C 390 330.56 240 486 240 486 Z    down the right flank to the point

Check (knocked out of the pin, 42 wide, round caps and joins)
M 162 230 L 220 292 L 457.3 2.5   short arm to the vertex, then the long arm
                                  out through the rim and past it

Flick (vermilion, 42 wide, round caps)
M 380.7 95.9 L 420 48             the long arm again, outside the pin
```

- The flick lies exactly on the long arm's centreline. Its cap starts about
  **16 units** past the point where the arm leaves the pin, so the rim is
  visibly cut open before the flick begins.
- The cut runs far past the rim on purpose, so the rim is always cut clean
  through; past the rim there is nothing left to cut.
- The cut removes only the pin. It never cuts the flick, the wordmark, or
  anything behind the mark.
- The pin is centred on x = 240 and the flick reaches out to the upper
  right, so the ink box (90 to 441 across, 27 to 486 down) sits a little
  right of the artboard's centre. Lockups and icons place the mark by its ink
  box.
- Round caps and joins, always.

### Cut and flick weights

The cut and the flick get wider as the mark gets smaller, so the check stays
open and the flick stays visible. The pin itself never changes.

| Size on screen  | Cut and flick (artboard units) | Where                             |
| --------------- | ------------------------------ | --------------------------------- |
| 64 px and up    | 42                             | `verily-mark.svg`, hero uses      |
| 33 to 63 px     | blends 54 → 42                 | `VerilyMark` does this for you    |
| 32 px and below | 54                             | `verily-mark-small.svg`, favicons |
| App icon        | 46 on colour                   | `verily-app-icon*.svg/png`        |

### Rough and clean

In the app and in motion, the mark is inked in Skribble's seeded hand: the
pin's outline wanders very slightly and is edged by two light passes of an
even pen, and the cut and the flick follow two slightly different seeded
lines with round caps. The same seed always draws the same mark, so it never
shimmers between frames. Exported files are the clean vectors: the pin as a
filled path, the cut as an SVG mask, the flick as a stroke. Use the clean
mark for print, favicons, embroidery, and anywhere a renderer cannot draw
ours.

When the mark draws itself on, the pin presses in first (it fades up and
grows from its point), then the check is cut through it from the short arm
up, and the flick draws as the cut runs out past the rim, in one pass.

### Clear space and minimum size

- **Clear space:** keep a margin of at least **a quarter of the mark's
  height** (its ink, flick included) on every side, free of text and other
  marks. Around a lockup, use the height of the wordmark's lowercase letters.
- **Minimum size:** the mark is legible at **24 px** with the small weights:
  the pin, the cut check, and the flick all read, though the gap between the
  rim and the flick closes to under a pixel (see the review sheet below). It
  is usable down to **16 px** as a favicon. The wordmark and the lockups need
  at least **24 px** of height.

To check legibility yourself, render the review sheets (commands at the end)
and look at `mark-24.png`, `mark-48.png`, and `mark-96.png`: the rough mark,
the clean mark, the app icon, and the night mark (rough and clean) side by
side at each size. `mark-knockout.png` shows the cut over stripes, and
`mark-motion.png` shows the mark drawing itself on.

## The wordmark: ✓erily

![The wordmark](../brand/verily-wordmark.svg)

- The **v is a check**, in stamp vermilion: a short arm down to the baseline,
  a long arm up past the x-height.
- **erily** is handwritten in plum ink with monoline, round-capped strokes.
- The **i is dotted last**, in vermilion. When the wordmark writes itself on,
  it dots the i after the y, like a person signing.
- The check-v is the brand's only check. The verified stamp uses the same
  shape, scaled up.

Never set the name in a font and call it the wordmark, and never recolour the
check or the dot to ink.

### Lockups

- **Horizontal** (default): the mark (flick included) as tall as the
  wordmark from ascender to descender, with a gap of about a sixth of that
  height. The mark keeps its own proportions: its cut and flick are the
  regular 42 units of its artboard.
- **Stacked**: the mark centred above the wordmark by its ink box, a little
  larger.

The mark's cut goes through its pin only, never through the wordmark.

The proportions live in the geometry; use `VerilyLockup` or the exported files
instead of placing the parts by eye.

## Colour

Verily sits on Skribble's paper and ink. Vermilion is ours.

| Token          | Hex       | Role                                               | Contrast                                  |
| -------------- | --------- | -------------------------------------------------- | ----------------------------------------- |
| `paper`        | `#FFFAF0` | The page; every light surface                      | —                                         |
| `night`        | `#292331` | The dark page                                      | paper on night 14.64:1                    |
| `ink`          | `#34283F` | Text, outlines, "erily"                            | 13.27:1 on paper                          |
| `mutedInk`     | `#736678` | Secondary text on paper                            | 5.17:1 on paper                           |
| `mutedPaper`   | `#B9ACBF` | Secondary text on night                            | 7.05:1 on night                           |
| `stamp`        | `#D13F22` | The mark, the check, the i-dot, the verified stamp | 4.54:1 on paper; paper on it 4.54:1       |
| `stampOnNight` | `#F2856A` | Vermilion on night paper                           | 6.05:1 on night (plain vermilion: 3.22:1) |
| `place`        | `#2F6B4F` | Pins, radius circles, "inside the place"           | 6.05:1 on paper, 5.05:1 on sage           |
| `placeWash`    | `#DDEAD9` | Sage: the hatched radius, place chips              | ink on it 11.07:1                         |
| `reward`       | `#9A6A12` | Escrowed rewards, coins, the jar                   | 4.54:1 on paper, 3.84:1 on butter         |
| `rewardWash`   | `#F6E8AF` | Butter: reward chips, the jar                      | ink on it 11.23:1                         |
| `review`       | `#6B4FA0` | Proof waiting for a person, appeals                | 6.21:1 on paper, 4.92:1 on lilac          |
| `reviewWash`   | `#E5DDF4` | Lilac: review chips, selection                     | ink on it 10.50:1                         |
| `dusk`         | `#4A3B5E` | Fills and selections on night                      | —                                         |
| `fireCore`     | `#F2FCFF` | The white-hot centre of the ball-skill flame       | — (light over footage, never text)        |
| `fireGlow`     | `#9BEFFF` | Ice cyan: the flame's halo                         | — (light over footage, never text)        |
| `fireFlame`    | `#3DB4FF` | Flame blue: the body of the flame                  | — (light over footage, never text)        |
| `fireEdge`     | `#1E6BE6` | Deep blue: where the flame and embers fade         | — (light over footage, never text)        |

Night variants of the role accents (`placeOnNight` `#86C7A0` 7.75:1,
`rewardOnNight` `#E6BC5C` 8.49:1, `reviewOnNight` `#BBA6EC` 7.09:1) keep the
same roles on night paper. All values live in `VerilyBrandColors`, the only
place brand colours are written down.

Rules:

- **Vermilion means verified, or Verily.** Use it for the mark, the stamp,
  and checks that passed. Never for errors, warnings, or sales.
- **Reward gold on butter is for large text and icons only** (3.84:1). Put
  ink text on the butter wash.
- **Fire burns blue.** The ball-skill flame has its own family, so it is
  never drawn in gold or vermilion, and fire blue is never used for anything
  but fire.
- **Never use colour alone for status.** A verified proof carries the stamp
  _and_ a word; a place carries a pin _and_ its name.

## The verified stamp

A hand-pressed double ring in vermilion with the brand's check inside,
turned 8° anticlockwise, with a rubber-stamp texture (`VerifiedStamp`).

- **Only on verified proof.** The stamp means a capture passed Verily's
  checks (or a person's review). Never stamp something unverified, never use
  it as decoration, and never use it in place of the logo.
- **One slam per moment.** It drops, lands at the halfway point of its
  animation with a squash and a soft ring, then the ink settles. Under
  reduced motion it simply appears, settled.
- On night paper, use `stampOnNight`.

## Do and don't

**Do**

- Draw in Skribble's hand: seeded rough lines, hatched washes, dotted paper.
- Let the mark press in and tick itself, once, where a moment deserves it.
- Show the place: a pin and a hatched sage radius.
- Show the money before the work: the escrow jar or chip is already full.
- Keep copy short and literal.

**Don't**

- Redraw, stretch, rotate, outline, or shadow the mark, or add a gradient.
- Fill in the check, draw it on top of the pin instead of cutting it out,
  close the rim where the check breaks through, or drop the flick.
- Use surveillance imagery: red boxes, face grids, threat meters, scores.
- Make the token the product, or show charts, prices, or trading.
- Claim a clip is "real". Say what was checked.
- Stamp anything that has not passed verification.

## Launch media and re-rendering

From `packages/verily_brand` (Flutter 3.47.9; ffmpeg on `PATH`):

```bash
# Promo video (with and without the sound bed) and the Slopper cover:
dart run tool/render_promo.dart
#   -> .screenshots/promo/verily-promo.mp4         1920x1080, 30 fps, H.264, AAC
#   -> .screenshots/promo/verily-promo-silent.mp4
#   -> .screenshots/promo/verily-cover.png         1280x800, paper
#   -> .screenshots/promo/verily-cover-night.png   1280x800, night

# Re-score only the sound bed onto the existing silent cut:
dart run tool/render_promo.dart --remux

# Individual stills of the reel, for review:
flutter test tool/render_promo_test.dart \
  --dart-define=PROMO_OUT=../../.screenshots/stills \
  --dart-define=PROMO_STILLS=1,5,12,20,25,29

# The brand files, plus review sheets of the mark at 1024/96/48/24 px:
flutter test tool/export_brand_test.dart \
  --dart-define=BRAND_OUT=../../brand \
  --dart-define=SPECIMEN_OUT=../../.screenshots/brand
```

The reel is a pure function of time (`PromoReel(time:)`), drawn with Skribble
widgets and the brand widgets, and rendered frame by frame on the Flutter test
clock with the real Skribble typefaces. Its script lives in `PromoTimeline`,
which the render tool also reads to score the sound bed: soft plucked notes in
C major pentatonic at 100 BPM (each squat is one beat and plays the next note
up) over a quiet root on each bar, a soft pencil texture while text writes,
coin clinks, and a short, warm thunk (200 Hz falling to 120 Hz) on the exact
frame the stamp lands. The bed is high-passed at 70 Hz and normalised to −16
LUFS with a −1.5 dBTP ceiling.

`.screenshots/` is gitignored. Share the media on the launch, a release, or a
pull request; never commit it.
