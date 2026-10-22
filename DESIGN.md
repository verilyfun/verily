---
name: Verily
description: Real-world actions, captured live, checked, and stamped in a field notebook.
colors:
  paper: "#FFFAF0"
  night: "#292331"
  ink: "#34283F"
  muted-ink: "#736678"
  muted-paper: "#B9ACBF"
  dusk: "#4A3B5E"
  stamp: "#D13F22"
  stamp-on-night: "#F2856A"
  place: "#2F6B4F"
  place-wash: "#DDEAD9"
  place-on-night: "#86C7A0"
  reward: "#9A6A12"
  reward-wash: "#F6E8AF"
  reward-on-night: "#E6BC5C"
  review: "#6B4FA0"
  review-wash: "#E5DDF4"
  review-on-night: "#BBA6EC"
  fire-core: "#F2FCFF"
  fire-glow: "#9BEFFF"
  fire-flame: "#3DB4FF"
  fire-edge: "#1E6BE6"
typography:
  display:
    fontFamily: "SkribblePlayful (skribble_font_recursive)"
    fontSize: "40-64dp"
    fontWeight: 800
    lineHeight: 1.08
  headline:
    fontFamily: "SkribblePlayful (skribble_font_recursive)"
    fontSize: "24-32dp"
    fontWeight: 800
    lineHeight: 1.1
  title:
    fontFamily: "SkribblePlayful (skribble_font_recursive)"
    fontSize: "18-22dp"
    fontWeight: 700
    lineHeight: 1.2
  body:
    fontFamily: "SkribbleLinearPlayful (skribble_font_recursive)"
    fontSize: "16dp"
    fontWeight: 500
    lineHeight: 1.45
  label:
    fontFamily: "SkribbleLinearPlayful (skribble_font_recursive)"
    fontSize: "13-15dp"
    fontWeight: 700
    lineHeight: 1.2
  numeral:
    fontFamily: "SkribbleMonoPlayful (skribble_font_recursive)"
    fontSize: "matches context"
    fontWeight: 600
rounded:
  control: "6dp"
  chip: "14dp"
  card: "12dp"
  sheet: "24dp"
  phone-frame: "34dp"
  app-icon: "22.3% of the side"
spacing:
  page-gutter: "16dp"
  stack: "12dp"
  section: "24dp"
  touch-target: "44dp"
components:
  action-card:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    border: "WiredCard rough rounded rectangle, ink, 2.6dp"
    rounded: "{rounded.card}"
    padding: "12dp"
  place-sheet:
    backgroundColor: "{colors.paper}"
    accent: "{colors.place}"
    radiusFill: "hachure in {colors.place} at 35% over {colors.place-wash}"
    rounded: "{rounded.sheet}"
  reward-chip:
    backgroundColor: "{colors.reward-wash}"
    textColor: "{colors.ink}"
    border: "rough, {colors.reward}"
    rounded: "{rounded.chip}"
    height: "44dp"
  proof-checklist-row:
    textColor: "{colors.ink}"
    tick: "Skribble box in ink, check drawn in {colors.stamp}"
    height: "44dp"
  verified-stamp:
    color: "{colors.stamp}"
    rotation: "-8deg"
    size: "72-160dp"
  review-chip:
    backgroundColor: "{colors.review-wash}"
    textColor: "{colors.ink}"
    accent: "{colors.review}"
    rounded: "{rounded.chip}"
---

# Design System: Verily

## Overview

**Creative North Star: "The Stamped Field Notebook"**

Every action is a page in a field notebook. A creator writes the page: what
to do, where (a pin and a hatched radius), and what it pays (already in the
jar). A participant fills it in by doing the thing, live, with their phone.
When the proof passes, the page gets stamped.

Verily is built on **Skribble**: `SkribbleApp` and `WiredTheme`, rough
seeded borders, hachure washes, Skribble emoji, and the Skribble typefaces.
Nothing is a clean vector box. Lines are inked by a seeded pen, so the same
control always wobbles the same way, and the paper is dotted like a notebook.

The product celebrates doing things in the world. It is not a surveillance
tool, a gig dashboard, or a crypto app, and it must never look like one.

**Key Characteristics:**

- Warm paper (or night paper) with a faint dot grid, plum ink, and one
  vermilion that means "verified".
- Hand-drawn everything: rough rounded borders, hatched fills, sketched maps,
  doodled arrows, Skribble emoji for flavour.
- The place is always visible: a pin and a hatched sage radius.
- The money is visible before the work: the escrow chip or jar is full first.
- Proof reads as a checklist of plain outcomes, then a stamp. Never a score.

## Logo

The **pin-check** is one continuous stroke: a map pin whose point is the
vertex of a check, the check's long arm crossing the head exactly where the
loop began. It reads as "verified, here". The **✓erily** wordmark makes the v a
vermilion check and dots the i in vermilion, last.

Use the widgets (`VerilyMark`, `VerilyWordmark`, `VerilyLockup`) in the app
and the files in [`brand/`](brand/README.md) everywhere else. In the app the
mark is inked in the seeded Skribble hand; exported files are the clean
centreline. The mark keeps its own optical weight: a heavier pen at 32dp and
below so it reads at 24dp. Full rules, construction, clear space, and
minimum sizes are in [`docs/brand.md`](docs/brand.md).

## Colors

Paper and ink come from Skribble so every Wired widget sits on the same page.
Accents are roles, not decoration, and each has a wash for the surface
behind it. All values live in `VerilyBrandColors`; no other code constructs a
colour.

### Primary

- **Stamp vermilion** (`stamp`, `stamp-on-night`): the mark, the check-v,
  the i-dot, proof ticks, and the verified stamp. It means "verified" or
  "Verily" and nothing else; never errors, warnings, or promotions.
- **Plum ink** (`ink`): text and outlines on paper.

### Roles

- **Place green** (`place`, `place-wash`, `place-on-night`): pins, radius
  circles, "inside the place", and location status.
- **Reward gold** (`reward`, `reward-wash`, `reward-on-night`): escrowed
  rewards, coins, the jar, and payouts. Gold on butter is 3.84:1, so it is for
  coins, icons, and large amounts; text on butter is ink.
- **Review violet** (`review`, `review-wash`, `review-on-night`): proof
  waiting for a person, appeals, and anything a human decides.
- **Fire blue** (`fire-core`, `fire-glow`, `fire-flame`, `fire-edge`): the
  ball-skill flame, its embers, and the limb that touches the ball. It burns
  white through ice cyan to deep blue, a hotter fire than gold or vermilion,
  so a flame is never read as a coin or a stamp. It is light drawn over the
  camera, never text or a surface.

### Neutral

- **Paper** (`paper`) and **night** (`night`): the page in light and dark.
- **Muted ink** (`muted-ink`) and **muted paper** (`muted-paper`): secondary
  text, 5.17:1 and 7.05:1.
- **Dusk** (`dusk`): fills and selections on night paper.

**The One Vermilion Rule.** If something is vermilion, it is verified or it
is the brand. Anything else that wants attention uses ink, weight, or a wash.

**The Never Colour Alone Rule.** Status always pairs colour with a word and a
shape: a stamp and "Verified", a pin and the place's name, a violet chip and
"With a reviewer".

## Typography

**Display:** SkribblePlayful, 800, from `skribble_font_recursive`\
**Body and labels:** SkribbleLinearPlayful, 500–700\
**Numerals and codes:** SkribbleMonoPlayful

**Character:** the playful Skribble face is hand-lettered and chunky, so big
lines feel written on the page. The linear sibling keeps small text calm and
legible on a phone. All three follow the theme's playful roughness level.

### Hierarchy

- **Display** (800, 40–64dp): one plain promise per screen or moment. "Post
  an action." "Prove it."
- **Headline** (800, 24–32dp): screen titles and big amounts.
- **Title** (700, 18–22dp): action names on cards.
- **Body** (500, 16dp, 1.45 line-height): explanations, kept short.
- **Label** (700, 13–15dp): chips, place names, status words.

**The Plain Words Rule.** Large type says what happens in ordinary language.
Never put model, provider, chain, or storage words in display copy.

**The Honest Proof Rule.** Copy says what was checked ("Filmed live in
Verily", "Inside the place"), never that a scene is "real".

## Layout

Mobile portrait first, for Android. A 16dp page gutter, 12dp between related
items, 24dp between groups. Every touch target is at least 44dp. Screens are
pages in the notebook: a display line at the top, the page's content (an
action card, a map, a checklist) as the body, and one primary action at the
bottom.

Text scales; layouts wrap instead of clipping. Long action names wrap on
cards rather than ellipsizing.

## Elevation & Depth

There are no shadows. Depth comes from paper on paper: a card is a rough ink
outline on the same paper, a sheet is a larger rough outline, and the camera
is a night-paper viewfinder framed by sketched corner brackets. Overlap
(a stamp landing across a card's edge, a coin over a chip) is the only
"elevation".

## Shapes

Rough rounded rectangles for controls (6dp), chips (14dp), cards (12dp), and
sheets (24dp); rough circles for pins, coins, and radius rings. Hatching
(`HachureFiller`) marks an area: the place's radius in sage, the seal's sweep
in vermilion. Arrows and underlines are doodled by hand.

## Components

### Action card

A `WiredCard` with a Skribble emoji for flavour, the action's name as a
title, and its place and reward underneath. Tapping opens the action's page.

### Place sheet

A sketched map with the pin in place green and the radius as a hatched sage
circle drawn in place green. The place's name and radius are written under
it. Precise coordinates are never shown publicly.

### Escrow jar and reward chip

Butter chip with a gold coin, the amount, and "in escrow" with a lock. The
jar is the illustrated version for empty states and onboarding: coins go in,
the lid comes down, the padlock clicks. A rewarded action shows its full jar
before anyone starts.

### Camera viewfinder

Night paper, sketched corner brackets, a "Live" label, the rep or step
counter, the live challenge in a speech bubble ("Say “pelican”"), and a small
place chip with a pulsing dot inside the hatched radius. No face boxes, no
grids, no red rectangles, no scores.

The roles keep their meaning over the camera. The HUD inks with paper, fills
with dusk, and outlines in ink; the record, stop, and shutter button is the
night page's primary action, ink on a paper fill. A counter reaching its
target, a body at depth, or a quick check seeing its label says so in words
and with a paper fill, never in gold, green, or vermilion: nothing on the HUD
is a reward or a verdict yet. A ball skill's fire burns in fire blue.

### Proof checklist

One row per plain outcome: _Filmed live in Verily_, _Signed by this phone_,
_Inside the place_, _Challenge spoken_, _Checked by Verily_. Each tick is a
Skribble box with the brand check drawn in vermilion. Rows that need a person
show a violet review chip instead of a tick.

### Verified stamp

`VerifiedStamp`: a vermilion double ring, the brand check inside, turned −8°,
with a rubber-stamp texture. Pressed only onto proof that passed, once.

### Motion

One moment, one gesture: the mark draws itself in one stroke, a word writes
on, a tick is drawn, or the stamp slams (it lands half way through, squashes,
rings, and the ink settles). Never several at once on one screen. Everything
is drawn from a seeded pen, so motion never re-rolls a wobble. Under reduced
motion every drawing appears complete and the stamp appears settled.

## Do's and Don'ts

### Do:

- Draw with Skribble: Wired widgets, rough borders, hatching, emoji.
- Show where: a pin, a hatched radius, and the place's name.
- Show the reward before the work: a full jar, "in escrow".
- Explain outcomes and next steps in plain words.
- Keep evidence private and coordinates approximate in public views.
- Send hard cases to a person, and say so kindly.

### Don't:

- Use red boxes, face grids, threat meters, or confidence scores.
- Present a model's opinion as truth, or say a clip is "real".
- Show an upload button for proof that must be captured live.
- Treat people as task queues, or turn actions into farmable clicks.
- Make the token the product: no charts, prices, or trading.
- Use vermilion for anything that is not verified or the brand.
- Ask for danger, humiliation, trespass, or someone else's private life.
