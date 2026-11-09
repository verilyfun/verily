# Verily brand files

Every file here is generated from the brand geometry in
[`packages/verily_brand/lib/src/geometry.dart`](../packages/verily_brand/lib/src/geometry.dart).
Do not edit them by hand: change the geometry and re-export (see below), so
the app, the launch video, and these files can never drift apart.

The vectors are clean: the mark's pin is a filled path, its check is cut out
of the pin with an SVG `<mask>` (so the background shows through), and every
other line is a single stroke with round caps and joins. Each file's mask has
its own id, so several files can be inlined into one page. The app and the
launch reel draw the same geometry in Skribble's seeded hand-drawn ink; the
files stay crisp at every size. Read [`docs/brand.md`](../docs/brand.md)
before using them.

| File                             | What it is                                                                                                            | Use it for                                                               |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `verily-mark.svg`                | The pin-check in stamp vermilion `#D13F22` (cut and flick 42) on a 512 square.                                        | The mark on light paper: avatars, stickers, social cards, docs.          |
| `verily-mark-mono.svg`           | The pin-check in `currentColor`, the check cut through.                                                               | Single-colour uses: favicons via CSS, monochrome print, themed icons.    |
| `verily-mark-dark.svg`           | The pin-check in night vermilion `#F2856A`.                                                                           | The mark on night paper `#292331` or other dark surfaces.                |
| `verily-mark-small.svg`          | The pin-check with the wider small-size cut and flick (54).                                                           | 16 to 32 px: favicons, tab icons, inline badges.                         |
| `verily-wordmark.svg`            | ✓erily: vermilion check-v and i-dot, plum ink `#34283F` letters.                                                      | The name on light paper when the mark is shown elsewhere.                |
| `verily-lockup-horizontal.svg`   | Mark and wordmark side by side.                                                                                       | Headers, footers, slides, the default lockup.                            |
| `verily-lockup-stacked.svg`      | Mark centred above the wordmark.                                                                                      | Square and portrait spaces: splash screens, posters, merch.              |
| `verily-app-icon.svg`            | Paper pin-check (cut and flick 46) on a vermilion rounded square, 1024 artboard; the vermilion shows through the cut. | Store listings, websites, and previews of the app icon.                  |
| `verily-app-icon-foreground.svg` | The paper pin-check alone on a 108 dp artboard, flick included inside the 66 dp safe zone; the cut is transparent.    | The Android adaptive icon's foreground layer (and its monochrome layer). |
| `verily-app-icon.png`            | 1024 × 1024 RGB (no alpha channel), full-bleed vermilion with the paper pin-check.                                    | The launcher-icon source for iOS and Android (`flutter_launcher_icons`). |

## App icons

- **Launcher source.** `verily-app-icon.png` is deliberately full-bleed and
  has no alpha channel at all: iOS and Android launchers apply their own
  corner mask, and the App Store rejects icons with an alpha channel. The
  rounded square in `verily-app-icon.svg` only previews how it looks once
  masked.
- **Android adaptive icon.** Use `verily-app-icon-foreground.svg` as the
  foreground layer and a solid **`#D13F22`** (stamp vermilion) background
  layer. Every bit of ink, the flick included, sits inside the 66 dp safe
  circle, so no launcher mask clips the mark, and the vermilion background
  shows through the cut check. The same foreground works as the Android 13+
  monochrome (themed) layer.

## Re-exporting

From `packages/verily_brand`:

```bash
flutter test tool/export_brand_test.dart --dart-define=BRAND_OUT=../../brand
```

This rewrites the SVG files and `verily-app-icon.png`. Add
`--dart-define=SPECIMEN_OUT=../../.screenshots/brand` to also render review
sheets (the mark at 1024, 96, 48, and 24 px, rough and clean, on paper and on
night) into the gitignored `.screenshots/` folder.
