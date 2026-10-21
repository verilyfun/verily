import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:verily_brand/verily_brand.dart';

import 'package:verily_flutter/app/theme/theme_mode_provider.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_appearance_settings.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

import '../../support/contrast.dart';
import '../../support/memory_theme_store.dart';

const _paper = VerilyPalette.paper();
const _night = VerilyPalette.night();

void main() {
  group('typeface', () {
    test('letters display roles by hand and text roles in the linear face', () {
      final textTheme = buildVerilyTheme().textTheme;

      for (final (style, weight) in [
        (textTheme.displayLarge, FontWeight.w800),
        (textTheme.headlineMedium, FontWeight.w800),
        (textTheme.titleLarge, FontWeight.w700),
      ]) {
        expect(style?.fontFamily, verilyDisplayFontFamily);
        expect(style?.fontWeight, weight);
      }
      for (final (style, weight) in [
        (textTheme.bodyMedium, FontWeight.w500),
        (textTheme.bodySmall, FontWeight.w500),
        (textTheme.labelLarge, FontWeight.w700),
        (textTheme.labelSmall, FontWeight.w700),
      ]) {
        expect(style?.fontFamily, verilyTextFontFamily);
        expect(style?.fontWeight, weight);
      }
      expect(
        verilyDisplayFontFamily,
        'packages/skribble_font_recursive/SkribblePlayful',
      );
      expect(
        verilyTextFontFamily,
        'packages/skribble_font_recursive/SkribbleLinearPlayful',
      );
      expect(
        verilyNumeralFontFamily,
        'packages/skribble_font_recursive/SkribbleMonoPlayful',
      );
    });

    test('keeps the DESIGN.md sizes and line heights', () {
      final textTheme = buildVerilyTheme(useAppTypeface: false).textTheme;

      expect(textTheme.displayLarge?.fontSize, 48);
      expect(textTheme.displayLarge?.height, 1.08);
      expect(textTheme.headlineLarge?.fontSize, 32);
      expect(textTheme.headlineSmall?.fontSize, 24);
      expect(textTheme.headlineSmall?.height, 1.1);
      expect(textTheme.titleLarge?.fontSize, 22);
      expect(textTheme.titleSmall?.fontSize, 18);
      expect(textTheme.titleLarge?.height, 1.2);
      expect(textTheme.bodyMedium?.fontSize, 16);
      expect(textTheme.bodyMedium?.height, 1.45);
      expect(textTheme.labelLarge?.fontSize, 15);
      expect(textTheme.labelSmall?.fontSize, 13);
      expect(textTheme.labelLarge?.height, 1.2);
      // Without the app typeface, the test font keeps its metrics.
      expect(textTheme.bodyMedium?.fontFamily, isNot(verilyTextFontFamily));
    });
  });

  group('palette', () {
    test('paper and night carry the documented brand values', () {
      expect(_paper.canvas.toARGB32(), 0xFFFFFAF0);
      expect(_paper.ink.toARGB32(), 0xFF34283F);
      expect(_paper.mutedInk.toARGB32(), 0xFF736678);
      expect(_paper.accent.toARGB32(), 0xFFD13F22);
      expect(_paper.place.toARGB32(), 0xFF2F6B4F);
      expect(_paper.placeWash.toARGB32(), 0xFFDDEAD9);
      expect(_paper.reward.toARGB32(), 0xFF9A6A12);
      expect(_paper.rewardWash.toARGB32(), 0xFFF6E8AF);
      expect(_paper.review.toARGB32(), 0xFF6B4FA0);
      expect(_paper.reviewWash.toARGB32(), 0xFFE5DDF4);
      expect(_paper.highlight.toARGB32(), 0xFFF6DFD5);
      expect(_paper.action, _paper.ink);

      expect(_night.canvas.toARGB32(), 0xFF292331);
      expect(_night.ink.toARGB32(), 0xFFFFFAF0);
      expect(_night.mutedInk.toARGB32(), 0xFFB9ACBF);
      expect(_night.accent.toARGB32(), 0xFFF2856A);
      expect(_night.place.toARGB32(), 0xFF86C7A0);
      expect(_night.reward.toARGB32(), 0xFFE6BC5C);
      expect(_night.review.toARGB32(), 0xFFBBA6EC);
      expect(_night.highlight.toARGB32(), 0xFF4A3B5E);
      expect(_night.action, _night.ink);
    });

    test('every role changes with the brightness', () {
      final light = buildVerilyTheme(useAppTypeface: false).verily;
      final dark = buildVerilyTheme(
        brightness: Brightness.dark,
        useAppTypeface: false,
      ).verily;

      expect(light, same(_paper));
      expect(dark, same(_night));
      expect(light.canvas, isNot(dark.canvas));
      expect(light.surface, isNot(dark.surface));
      expect(light.ink, isNot(dark.ink));
      expect(light.mutedInk, isNot(dark.mutedInk));
      expect(light.line, isNot(dark.line));
      expect(light.accent, isNot(dark.accent));
      for (final tone in VerilyTone.values) {
        expect(light.hue(tone), isNot(dark.hue(tone)));
        expect(light.wash(tone), isNot(dark.wash(tone)));
      }
    });

    test('every wash on night paper is dusk', () {
      for (final tone in VerilyTone.values) {
        expect(_night.wash(tone), _night.highlight, reason: '$tone');
      }
    });

    test('vermilion is only ever the stamp', () {
      for (final brightness in Brightness.values) {
        final theme = buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: false,
        );
        final stamp = theme.verily.accent;
        final scheme = theme.colorScheme;
        expect(
          [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
            scheme.error,
            scheme.primaryContainer,
            scheme.errorContainer,
            theme.progressIndicatorTheme.color,
            theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
            theme.textButtonTheme.style!.foregroundColor!.resolve({}),
          ],
          everyElement(isNot(stamp)),
          reason: '$brightness',
        );
        for (final tone in VerilyTone.values) {
          expect(theme.verily.hue(tone), isNot(stamp));
        }
      }
    });

    for (final (name, palette) in [('paper', _paper), ('night', _night)]) {
      group('$name meets WCAG 2.2 AA', () {
        test('text on the page and surfaces', () {
          expect(
            verilyContrastRatio(palette.ink, palette.canvas),
            greaterThanOrEqualTo(7),
          );
          expect(
            verilyContrastRatio(palette.ink, palette.surface),
            greaterThanOrEqualTo(7),
          );
          expect(
            verilyContrastRatio(palette.mutedInk, palette.surface),
            greaterThanOrEqualTo(4.5),
          );
        });

        test('the inked action and the stamp', () {
          expect(
            verilyContrastRatio(palette.onAction, palette.action),
            greaterThanOrEqualTo(7),
          );
          expect(
            verilyContrastRatio(palette.accent, palette.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            verilyContrastRatio(palette.onAccent, palette.accent),
            greaterThanOrEqualTo(4.5),
          );
        });

        test('every hue reads as a label on the surface', () {
          for (final tone in VerilyTone.values) {
            expect(
              verilyContrastRatio(palette.hue(tone), palette.surface),
              greaterThanOrEqualTo(4.5),
              reason: '$tone hue on $name',
            );
            expect(
              palette.readableAccent(palette.hue(tone)),
              palette.hue(tone),
            );
          }
        });

        test('every wash carries ink, and its hue as an icon', () {
          for (final tone in VerilyTone.values) {
            expect(
              verilyContrastRatio(palette.ink, palette.wash(tone)),
              greaterThanOrEqualTo(4.5),
              reason: 'ink on the $tone wash in $name',
            );
            expect(
              verilyContrastRatio(palette.hue(tone), palette.wash(tone)),
              greaterThanOrEqualTo(3),
              reason: '$tone hue on its own wash in $name',
            );
          }
        });

        test('the quiet pen marks a control edge at 3:1', () {
          expect(
            contrastOver(palette.quietPen, palette.surface),
            greaterThanOrEqualTo(3),
          );
          expect(
            contrastOver(palette.firmPen, palette.surface),
            greaterThan(contrastOver(palette.quietPen, palette.surface)),
          );
        });
      });
    }

    test('readableAccent falls back to ink for a pale colour', () {
      expect(_paper.readableAccent(_paper.placeWash), _paper.ink);
    });

    test('the movement HUD stays readable over its own scrim', () {
      expect(
        verilyContrastRatio(
          VerilyColors.movementHudInk,
          VerilyColors.movementScrim,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        verilyContrastRatio(
          VerilyColors.movementHudMuted,
          VerilyColors.movementScrim,
        ),
        greaterThanOrEqualTo(4.5),
      );
      // Emphasis is ink on a paper fill.
      expect(
        verilyContrastRatio(
          VerilyColors.movementOutline,
          VerilyColors.movementHudInk,
        ),
        greaterThanOrEqualTo(4.5),
      );
      // A resting fill must look different from an emphasised one.
      expect(VerilyColors.movementHudWash, isNot(VerilyColors.movementHudInk));
      expect(
        VerilyColors.movementBone,
        isNot(VerilyColors.movementOutline),
      );
    });

    test('the camera HUD never borrows a role colour', () {
      const roles = [
        VerilyBrandColors.stamp,
        VerilyBrandColors.stampOnNight,
        VerilyBrandColors.place,
        VerilyBrandColors.placeOnNight,
        VerilyBrandColors.placeWash,
        VerilyBrandColors.reward,
        VerilyBrandColors.rewardOnNight,
        VerilyBrandColors.rewardWash,
        VerilyBrandColors.review,
        VerilyBrandColors.reviewOnNight,
        VerilyBrandColors.reviewWash,
      ];
      for (final hud in [
        VerilyColors.movementBone,
        VerilyColors.movementOutline,
        VerilyColors.movementScrim,
        VerilyColors.movementHudInk,
        VerilyColors.movementHudMuted,
        VerilyColors.movementHudWash,
      ]) {
        expect(roles, isNot(contains(hud)));
      }
    });
  });

  group('Material mapping', () {
    for (final brightness in Brightness.values) {
      test('maps $brightness roles explicitly from the palette', () {
        final theme = buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: false,
        );
        final palette = theme.verily;
        final scheme = theme.colorScheme;

        expect(scheme.brightness, brightness);
        expect(scheme.primary, palette.action);
        expect(scheme.onPrimary, palette.onAction);
        expect(scheme.primaryContainer, palette.highlight);
        expect(scheme.error, palette.ink);
        expect(scheme.secondary, palette.place);
        expect(scheme.secondaryContainer, palette.placeWash);
        expect(scheme.tertiary, palette.review);
        expect(scheme.tertiaryContainer, palette.reviewWash);
        expect(scheme.surface, palette.surface);
        expect(scheme.onSurface, palette.ink);
        expect(scheme.onSurfaceVariant, palette.mutedInk);
        expect(scheme.surfaceContainerHighest, palette.highlight);
        expect(scheme.outlineVariant, palette.line);
        expect(theme.scaffoldBackgroundColor, palette.canvas);
        // Material's default dialog icon is the secondary (place) colour.
        expect(theme.dialogTheme.iconColor, palette.ink);

        for (final (fill, label) in [
          (scheme.primary, scheme.onPrimary),
          (scheme.secondary, scheme.onSecondary),
          (scheme.tertiary, scheme.onTertiary),
          (scheme.error, scheme.onError),
          (scheme.primaryContainer, scheme.onPrimaryContainer),
          (scheme.secondaryContainer, scheme.onSecondaryContainer),
          (scheme.tertiaryContainer, scheme.onTertiaryContainer),
          (scheme.inverseSurface, scheme.onInverseSurface),
        ]) {
          expect(
            verilyContrastRatio(label, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$label on $fill',
          );
        }
      });
    }

    test('the filled button keeps its label readable in both modes', () {
      for (final brightness in Brightness.values) {
        final style = buildVerilyTheme(
          brightness: brightness,
          useAppTypeface: false,
        ).filledButtonTheme.style!;
        expect(
          verilyContrastRatio(
            style.foregroundColor!.resolve({})!,
            style.backgroundColor!.resolve({})!,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  group('appearance preference', () {
    test(
      'restores the saved mode without overwriting a newer choice',
      () async {
        final store = MemoryThemeStore(saved: 'dark');
        final container = ProviderContainer(
          overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(verilyThemePreferenceProvider),
          VerilyThemePreference.system,
        );
        await pumpEventQueue();
        expect(
          container.read(verilyThemePreferenceProvider),
          VerilyThemePreference.dark,
        );

        await container
            .read(verilyThemePreferenceProvider.notifier)
            .setPreference(VerilyThemePreference.light);
        expect(store.saved, 'light');
        expect(
          container.read(verilyThemePreferenceProvider),
          VerilyThemePreference.light,
        );
      },
    );

    test('a choice made before the restore finishes wins', () async {
      final store = MemoryThemeStore(saved: 'dark');
      final container = ProviderContainer(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(verilyThemePreferenceProvider);
      await container
          .read(verilyThemePreferenceProvider.notifier)
          .setPreference(VerilyThemePreference.light);
      await pumpEventQueue();

      expect(
        container.read(verilyThemePreferenceProvider),
        VerilyThemePreference.light,
      );
    });

    test('a value this build does not know falls back to the device', () {
      expect(VerilyThemePreference.decode(null), VerilyThemePreference.system);
      expect(
        VerilyThemePreference.decode('twilight'),
        VerilyThemePreference.system,
      );
      expect(VerilyThemePreference.decode('dark'), VerilyThemePreference.dark);
    });

    test(
      'a store that cannot save is reported, and the choice applies',
      () async {
        final reported = <FlutterErrorDetails>[];
        final previousHandler = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = previousHandler);

        final container = ProviderContainer(
          overrides: [
            themePreferenceStoreProvider.overrideWithValue(
              _FailingThemeStore(),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(verilyThemePreferenceProvider);
        await container
            .read(verilyThemePreferenceProvider.notifier)
            .setPreference(VerilyThemePreference.dark);
        await pumpEventQueue();

        expect(
          container.read(verilyThemePreferenceProvider),
          VerilyThemePreference.dark,
        );
        expect(reported, hasLength(2));
        expect(
          reported.map((details) => details.library),
          everyElement('verily appearance'),
        );
      },
    );
  });

  testWidgets('appearance settings switch the theme and save the choice', (
    tester,
  ) async {
    final store = MemoryThemeStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themePreferenceStoreProvider.overrideWithValue(store)],
        child: const _ThemeHarness(),
      ),
    );
    await tester.pump();

    expect(
      tester.getSemantics(find.byKey(VerilyTestKeys.appearanceSystem)),
      isSemantics(isSelected: true, isButton: true),
    );

    await tester.tap(find.byKey(VerilyTestKeys.appearanceDark));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(VerilyAppearanceSettings));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).verily.canvas, _night.canvas);
    expect(store.saved, 'dark');
    expect(find.text('Always deep night with paper ink.'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(VerilyTestKeys.appearanceDark)),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.byKey(VerilyTestKeys.appearanceSystem)),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('the page header does not expose appearance controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildVerilyTheme(useAppTypeface: false),
        home: const Scaffold(body: VerilyAppHeader(title: 'Your actions')),
      ),
    );

    expect(find.byType(VerilyAppearanceSettings), findsNothing);
    expect(find.byKey(VerilyTestKeys.appearanceDark), findsNothing);
  });
}

class _ThemeHarness extends ConsumerWidget {
  const _ThemeHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(verilyThemePreferenceProvider);
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildVerilyTheme(useAppTypeface: false),
      darkTheme: buildVerilyTheme(
        brightness: Brightness.dark,
        useAppTypeface: false,
      ),
      themeMode: preference.themeMode,
      home: const Scaffold(
        body: SingleChildScrollView(child: VerilyAppearanceSettings()),
      ),
    );
  }
}

class _FailingThemeStore implements ThemePreferenceStore {
  @override
  Future<String?> read() async => throw StateError('no preferences plugin');

  @override
  Future<void> write(String value) async =>
      throw StateError('no preferences plugin');
}
