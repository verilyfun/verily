# verily_flutter

The Verily phone app: do it, prove it, get paid. See `../PRODUCT.md`.

This is the phase A shell: the paper and night themes, the hand-drawn
components, localization, the debug development menu, and the native Android
device-integrity and capture-signing channels. The home screen is a
placeholder until the Serverpod client and the real screens land.

## Commands

Run these from this directory with the pinned Flutter (`devenv shell flutter`
or `~/fvm/versions/3.47.9/bin/flutter`).

```sh
flutter test                                   # unit and widget tests
dart analyze                                   # includes the verily_lints plugin
dart run tool/generate_verily_icons.dart       # regenerate the icon catalog
dart run tool/generate_verily_icons.dart --check
flutter gen-l10n                               # after editing lib/l10n/app_en.arb
flutter test --dart-define=VERILY_SCREENSHOTS=true test/screenshots
```

`flutter analyze` does not report analyzer-plugin diagnostics; use
`dart analyze` so the colour-token and pinned-dependency rules run. The
screenshot run writes Seeker-sized PNGs with the real Skribble face to
`.screenshots/phase-a/`, which git ignores.

## Conventions

- Colours come from `Theme.of(context).verily` or `colorScheme`. Only
  `lib/app/theme/verily_theme.dart` may construct a `Color`.
- Every user-facing string lives in `lib/l10n/app_en.arb`.
- Dependencies in `pubspec.yaml` are pinned to exact versions.
