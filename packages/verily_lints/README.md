# verily_lints

Analyzer plugin rules and the shared analysis options for Verily.

## Rules

- `enforce_theme_palette_colors` (warning): disallows hardcoded `Color(...)`,
  `Colors.*`, and `CupertinoColors.*` everywhere in the app, including tests
  and developer UI. Raw values live only in
  `lib/app/theme/verily_theme.dart`; app code reads
  `Theme.of(context).colorScheme`, `Theme.of(context).verily`, or a named
  `VerilyColors` token.
- `enforce_pinned_app_dependencies` (warning): requires exact versions in the
  `dependencies:` section of `verily_flutter/pubspec.yaml`. It reports on
  `lib/main.dart`, so the warning shows up once per analysis run.
- `avoid_stateful_widgets` (lint, opt-in): disallows `StatefulWidget`,
  `ConsumerStatefulWidget`, and `StatefulHookConsumerWidget`. Enable it under
  `plugins: verily_lints: diagnostics:` and override the class list with
  `disallowed_classes:`.

## Use

```yaml
include: package:verily_lints/analysis_options.yaml

plugins:
  verily_lints:
    path: ../packages/verily_lints
```

Run the rule tests with `dart test` in this package.
